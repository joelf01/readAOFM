# The /media/test URLs below are synthetic transport/redirect inputs only; the
# public catalogue route contract is tested separately against current direct
# Data Hub URLs.

test_that("runtime catalogue fails closed on any 23 plus seven drift", {
  complete <- aofm_catalog(include_unsupported = TRUE)
  expect_equal(nrow(complete), 30L)
  expect_equal(sum(complete$supported), 23L)
  expect_equal(sum(!complete$supported), 7L)
  expect_equal(anyDuplicated(complete$table_id), 0L)

  drifted <- readAOFM:::aofm_index
  drifted$fn[drifted$id == "tb_issuance"] <- "read_eom"
  testthat::local_mocked_bindings(
    aofm_index = drifted,
    .package = "readAOFM"
  )
  expect_error(aofm_catalog(), "23-supported/7-unsupported")
})

test_that("search reads use one short attempt while explicit loads stay bounded", {
  seen <- list()
  testthat::local_mocked_bindings(
    read_aofm = function(
        security, type, csv, timeout, retries, max_bytes) {
      seen[[length(seen) + 1L]] <<- list(
        timeout = timeout,
        retries = retries,
        max_bytes = max_bytes
      )
      data.frame(value = 1)
    },
    .package = "readAOFM"
  )
  search_aofm("tb issuance", read = TRUE)
  expect_equal(seen[[1L]]$timeout, 3)
  expect_equal(seen[[1L]]$retries, 0L)

  root <- tempfile("aofm-explicit-defaults-")
  source <- fixture_path("tb_issuance.xlsx")
  testthat::local_mocked_bindings(
    download_aofm_workbook = function(
        url, destfile, timeout, retries, max_bytes, lock_timeout,
        official_only) {
      seen[[length(seen) + 1L]] <<- list(
        timeout = timeout,
        retries = retries,
        max_bytes = max_bytes,
        official_only = official_only
      )
      file.copy(source, destfile, overwrite = TRUE)
      invisible(destfile)
    },
    .package = "readAOFM"
  )
  download_aofm_file("tb_issuance", root)
  expect_equal(seen[[2L]]$timeout, 30)
  expect_equal(seen[[2L]]$retries, 1L)
  expect_true(seen[[2L]]$official_only)
})

test_that("transport honors Retry-After and validates final host and byte cap", {
  source <- fixture_path("tb_issuance.xlsx")
  destination <- tempfile(fileext = ".xlsx")
  attempts <- 0L
  delays <- numeric()
  testthat::local_mocked_bindings(
    curl_fetch_disk = function(url, destfile, handle) {
      attempts <<- attempts + 1L
      if (attempts == 1L) {
        return(list(
          status_code = 429L,
          headers = charToRaw("HTTP/2 429\r\nRetry-After: 2\r\n\r\n"),
          type = "text/plain",
          url = url
        ))
      }
      file.copy(source, destfile, overwrite = TRUE)
      list(
        status_code = 200L,
        type = paste0(
          "application/vnd.openxmlformats-officedocument.",
          "spreadsheetml.sheet"
        ),
        url = url
      )
    },
    .package = "curl"
  )
  testthat::local_mocked_bindings(
    aofm_sleep = function(seconds) delays <<- c(delays, seconds),
    .package = "readAOFM"
  )
  readAOFM:::download_aofm_workbook(
    "https://www.aofm.gov.au/media/test",
    destination,
    retries = 1L,
    official_only = TRUE
  )
  expect_equal(attempts, 2L)
  expect_equal(delays, 2)
  expect_error(
    readAOFM:::download_aofm_workbook(
      "https://www.aofm.gov.au/media/test",
      tempfile(fileext = ".xlsx"),
      max_bytes = 3,
      official_only = TRUE
    ),
    "empty file|byte|maximum"
  )

  testthat::local_mocked_bindings(
    curl_fetch_disk = function(url, destfile, handle) {
      file.copy(source, destfile, overwrite = TRUE)
      list(
        status_code = 200L,
        type = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        url = "https://example.com/redirected.xlsx"
      )
    },
    .package = "curl"
  )
  expect_error(
    readAOFM:::download_aofm_workbook(
      "https://www.aofm.gov.au/media/test",
      tempfile(fileext = ".xlsx"),
      official_only = TRUE
    ),
    "official AOFM HTTPS"
  )
})

test_that("transport bounds reject coercion and overflow before network", {
  destination <- tempfile(fileext = ".xlsx")
  invalid <- list(
    list(timeout = "30"),
    list(retries = TRUE),
    list(retries = 1.5),
    list(retries = .Machine$integer.max),
    list(timeout = Inf),
    list(max_bytes = NA_real_)
  )
  for (arguments in invalid) {
    expect_error(do.call(
      readAOFM:::download_aofm_workbook,
      c(
        list(
          url = "https://www.aofm.gov.au/media/test",
          destfile = destination
        ),
        arguments
      )
    ), "bound|Timeout|retries|numeric|finite")
  }
  expect_false(file.exists(destination))
})

test_that("redirects are followed manually only after official target validation", {
  calls <- character()
  testthat::local_mocked_bindings(
    curl_fetch_disk = function(url, destfile, handle) {
      calls <<- c(calls, url)
      list(
        status_code = 302L,
        headers = charToRaw(
          "HTTP/1.1 302 Found\r\nLocation: https://evil.example/file.xlsx\r\n\r\n"
        ),
        type = "text/html",
        url = url
      )
    },
    .package = "curl"
  )
  expect_error(
    readAOFM:::download_aofm_workbook(
      "https://www.aofm.gov.au/media/test",
      tempfile(fileext = ".xlsx"),
      official_only = TRUE
    ),
    "official AOFM HTTPS"
  )
  expect_identical(calls, "https://www.aofm.gov.au/media/test")
})

test_that("content cache repairs corruption and serializes exact metadata", {
  root <- tempfile("aofm-content-cache-")
  source <- fixture_path("tb_issuance.xlsx")
  calls <- 0L
  testthat::local_mocked_bindings(
    download_aofm_workbook = function(url, destfile, ...) {
      calls <<- calls + 1L
      file.copy(source, destfile, overwrite = TRUE)
      invisible(destfile)
    },
    .package = "readAOFM"
  )

  first <- download_aofm_file("tb_issuance", root)
  second <- download_aofm_file("tb_issuance", root, overwrite = FALSE)
  expect_equal(calls, 1L)
  expect_false(attr(first, "cache_hit"))
  expect_true(attr(second, "cache_hit"))
  expect_match(basename(first), "^[a-f0-9]{64}\\.xlsx$")
  expect_match(attr(first, "raw_sha256"), "^[a-f0-9]{64}$")

  saved <- tempfile(fileext = ".rds")
  saveRDS(first, saved)
  restored <- readRDS(saved)
  expect_identical(
    attr(restored, "aofm_metadata")$raw_sha256,
    attr(first, "raw_sha256")
  )

  writeBin(charToRaw("corrupt"), first)
  expect_warning(
    repaired <- download_aofm_file(
      "tb_issuance",
      root,
      overwrite = FALSE
    ),
    "raw SHA-256 verification failed|raw byte verification failed"
  )
  expect_equal(calls, 2L)
  expect_identical(
    digest::digest(repaired, algo = "sha256", file = TRUE, serialize = FALSE),
    attr(repaired, "raw_sha256")
  )

  parsed <- read_aofm_file(repaired, "tb_issuance")
  metadata <- attr(parsed, "aofm_metadata")
  expect_identical(metadata$raw_sha256, attr(repaired, "raw_sha256"))
  expect_identical(metadata$table_id, "tb_issuance")
})

test_that("cache confinement locks final hashes and pruning preserve ownership", {
  source <- fixture_path("tb_issuance.xlsx")
  if (.Platform$OS.type != "windows") {
    outside <- tempfile("aofm-outside-")
    root <- tempfile("aofm-confined-")
    dir.create(outside)
    dir.create(file.path(root, ".readAOFM", "data"), recursive = TRUE)
    expect_true(file.symlink(
      outside,
      file.path(root, ".readAOFM", "data", "tb_issuance")
    ))
    expect_error(
      download_aofm_file("tb_issuance", root),
      "escaped the requested root|symlink"
    )
  }

  lock_root <- tempfile("aofm-lock-")
  paths <- readAOFM:::aofm_cache_paths(lock_root, "tb_issuance")
  dir.create(paths$lock)
  expect_error(
    download_aofm_file(
      "tb_issuance",
      lock_root,
      lock_timeout = 0.1
    ),
    "Timed out"
  )

  prune_root <- tempfile("aofm-prune-")
  dir.create(prune_root)
  unrelated <- file.path(prune_root, "keep-me.xlsx")
  file.copy(source, unrelated)
  testthat::local_mocked_bindings(
    download_aofm_workbook = function(url, destfile, ...) {
      file.copy(source, destfile, overwrite = TRUE)
      invisible(destfile)
    },
    .package = "readAOFM"
  )
  download_aofm_file(
    "tb_issuance",
    prune_root,
    max_files = 1L
  )
  download_aofm_file(
    "tib_issuance",
    prune_root,
    max_files = 1L
  )
  expect_true(file.exists(unrelated))
  expect_lte(
    length(readAOFM:::aofm_owned_cache_files(
      file.path(prune_root, ".readAOFM", "data")
    )),
    1L
  )

  final_root <- tempfile("aofm-final-hash-")
  original_save <- readAOFM:::aofm_atomic_save_rds
  testthat::local_mocked_bindings(
    download_aofm_workbook = function(url, destfile, ...) {
      file.copy(source, destfile, overwrite = TRUE)
      invisible(destfile)
    },
    aofm_atomic_save_rds = function(object, path) {
      original_save(object, path)
      writeBin(
        charToRaw("changed-after-metadata"),
        file.path(dirname(path), object$cache_file)
      )
      invisible(path)
    },
    .package = "readAOFM"
  )
  expect_error(
    download_aofm_file("tb_issuance", final_root),
    "final verification"
  )
  expect_false(file.exists(file.path(
    final_root,
    ".readAOFM",
    "data",
    "tb_issuance",
    "current.rds"
  )))
  expect_length(
    readAOFM:::aofm_owned_cache_files(
      file.path(final_root, ".readAOFM", "data")
    ),
    0L
  )
})

test_that("cache confinement has no symlink write or prune escape", {
  # Directory symlinks become reparse points on Windows. Hosted Windows R
  # cannot reliably remove those test-only links and can terminate during
  # tempdir cleanup, so the same guard is exercised on Unix-alike CI hosts.
  if (.Platform$OS.type == "windows") {
    root <- tempfile("aofm-root-escape-")
    dir.create(root)
    expect_error(
      readAOFM:::aofm_ensure_cache_directory(root, ".."),
      "escaped"
    )
  } else {
    root <- tempfile("aofm-root-link-")
    outside <- tempfile("aofm-root-outside-")
    dir.create(root)
    dir.create(outside)
    expect_true(file.symlink(outside, file.path(root, ".readAOFM")))
    expect_error(
      readAOFM:::aofm_cache_paths(root, "tb_issuance"),
      "escaped|symlink"
    )
    expect_false(dir.exists(file.path(outside, "data")))

    prune_root <- tempfile("aofm-prune-link-")
    prune_outside <- tempfile("aofm-prune-outside-")
    paths <- readAOFM:::aofm_cache_paths(prune_root, "tb_issuance")
    dir.create(prune_outside)
    victim <- file.path(
      prune_outside,
      paste0(paste(rep("a", 64L), collapse = ""), ".xlsx")
    )
    file.copy(fixture_path("tb_issuance.xlsx"), victim)
    Sys.setFileTime(victim, Sys.time() - 3600)
    expect_true(file.symlink(
      prune_outside,
      file.path(paths$data_root, "evil")
    ))
    expect_error(
      readAOFM:::aofm_prune_cache(
        paths,
        keep_file = file.path(paths$table_directory, "none.xlsx"),
        max_age = 1,
        max_files = 100L,
        max_cache_bytes = 500 * 1024^2
      ),
      "escaped|symlink"
    )
    expect_true(file.exists(victim))
  }
})

test_that("official transport requires attested final URL and restores old bytes", {
  source <- fixture_path("tb_issuance.xlsx")
  testthat::local_mocked_bindings(
    curl_fetch_disk = function(url, destfile, handle) {
      file.copy(source, destfile, overwrite = TRUE)
      list(
        status_code = 200L,
        type = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
      )
    },
    .package = "curl"
  )
  expect_error(
    readAOFM:::download_aofm_workbook(
      "https://www.aofm.gov.au/media/test",
      tempfile(fileext = ".xlsx"),
      official_only = TRUE
    ),
    "final.*URL|redirect target"
  )

  destination <- tempfile(fileext = ".xlsx")
  old_source <- fixture_path("tib_issuance.xlsx")
  file.copy(old_source, destination)
  digest_calls <- 0L
  testthat::local_mocked_bindings(
    curl_fetch_disk = function(url, destfile, handle) {
      file.copy(source, destfile, overwrite = TRUE)
      list(
        status_code = 200L,
        type = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        url = url
      )
    },
    .package = "curl"
  )
  testthat::local_mocked_bindings(
    digest = function(...) {
      digest_calls <<- digest_calls + 1L
      if (digest_calls == 1L) {
        paste(rep("a", 64L), collapse = "")
      } else {
        paste(rep("b", 64L), collapse = "")
      }
    },
    .package = "digest"
  )
  expect_error(
    readAOFM:::download_aofm_workbook(
      "https://www.aofm.gov.au/media/test",
      destination,
      official_only = TRUE
    ),
    "final SHA-256"
  )
  expect_identical(
    readBin(destination, what = "raw", n = file.info(destination)$size),
    readBin(old_source, what = "raw", n = file.info(old_source)$size)
  )
})

test_that("final digest errors restore the prior workbook", {
  source <- fixture_path("tb_issuance.xlsx")
  old_source <- fixture_path("tib_issuance.xlsx")
  destination <- tempfile(fileext = ".xlsx")
  file.copy(old_source, destination)
  original_digest <- digest::digest
  digest_calls <- 0L

  testthat::local_mocked_bindings(
    curl_fetch_disk = function(url, destfile, handle) {
      file.copy(source, destfile, overwrite = TRUE)
      list(
        status_code = 200L,
        type = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        url = url
      )
    },
    .package = "curl"
  )
  testthat::local_mocked_bindings(
    digest = function(...) {
      digest_calls <<- digest_calls + 1L
      if (digest_calls == 2L) {
        stop("simulated final digest error")
      }
      original_digest(...)
    },
    .package = "digest"
  )

  expect_error(
    readAOFM:::download_aofm_workbook(
      "https://www.aofm.gov.au/media/test",
      destination,
      official_only = TRUE
    ),
    "final SHA-256 verification.*simulated final digest error"
  )
  expect_identical(
    readBin(destination, what = "raw", n = file.info(destination)$size),
    readBin(old_source, what = "raw", n = file.info(old_source)$size)
  )
})

test_that("forged local metadata is ignored and active old locks are not stolen", {
  fixture <- fixture_path("tb_issuance.xlsx")
  tagged <- fixture
  row <- readAOFM:::aofm_table_row("tb_issuance")
  attr(tagged, "aofm_metadata") <- list(
    schema_version = 1L,
    table_id = "tb_issuance",
    source_url = as.character(row$file.path[[1L]]),
    source_filename = as.character(row$file.save[[1L]]),
    cache_file = basename(fixture),
    raw_sha256 = digest::digest(
      fixture,
      algo = "sha256",
      file = TRUE,
      serialize = FALSE
    ),
    raw_bytes = unname(file.info(fixture)$size),
    retrieved_at = as.POSIXct(Sys.time(), tz = "UTC"),
    cache_hit = TRUE
  )
  metadata <- aofm_file_metadata(tagged, "tb_issuance")
  expect_true(is.na(metadata$source_url))
  expect_false(metadata$cache_hit)
  expect_identical(metadata$source_filename, basename(fixture))

  lock <- file.path(tempfile("aofm-live-lock-"), "writer.lock")
  dir.create(dirname(lock))
  readAOFM:::aofm_acquire_lock(lock, timeout = 0.1)
  Sys.setFileTime(lock, Sys.time() - 3600)
  expect_error(
    readAOFM:::aofm_acquire_lock(lock, timeout = 0.1),
    "Timed out"
  )
  expect_true(dir.exists(lock))
})

test_that("lock release preserves a replacement owner", {
  lock <- file.path(tempfile("aofm-owner-lock-"), "writer.lock")
  dir.create(dirname(lock))
  first_owner <- readAOFM:::aofm_acquire_lock(lock, timeout = 0.1)

  unlink(lock, recursive = TRUE, force = TRUE)
  replacement_owner <- readAOFM:::aofm_acquire_lock(lock, timeout = 0.1)

  expect_false(readAOFM:::aofm_release_lock(lock, first_owner))
  expect_true(dir.exists(lock))
  expect_true(readAOFM:::aofm_release_lock(lock, replacement_owner))
  expect_false(dir.exists(lock))
})

test_that("official-shaped buybacks preserve their method identifier", {
  expected_headers <- c(
    "date_held",
    "tender_number_buyback_method",
    "maturity",
    "coupon",
    "isin",
    "amount_repurchased",
    "amount_of_offers",
    "weighted_average_repurchase_yield",
    "lowest_accepted_yield",
    "highest_accepted_yield",
    "lowest_offer",
    "weighted_average_offer",
    "secondary_market_mid_rate",
    "number_of_offers",
    "number_of_successful_offers",
    "number_of_offers_accepted_in_full",
    "settlement_proceeds",
    "date_settled"
  )
  cases <- list(
    tb_buyback = list(
      file = "tb_buyback.xlsx",
      methods = c("RBA", "TBB1"),
      omitted_measures = character()
    ),
    tib_buyback = list(
      file = "tib_buyback.xlsx",
      methods = c("Syndication", "TIBB1"),
      omitted_measures = expected_headers[9:16]
    )
  )

  for (table_id in names(cases)) {
    case <- cases[[table_id]]
    path <- fixture_path(case$file)
    header <- readxl::read_excel(path)[1, , drop = FALSE]
    expect_identical(
      janitor::make_clean_names(as.character(header)),
      expected_headers
    )

    parsed <- read_aofm_file(path, table_id)
    expect_setequal(
      unique(parsed$tender_number_buyback_method),
      case$methods
    )
    expect_false("tender_number_buyback_method" %in% parsed$name)
    expect_type(parsed$value, "double")
    expect_false(any(case$omitted_measures %in% parsed$name))
  }
})

test_that("official buyback offer measures reject malformed nonblank values", {
  required <- c("date_held", "maturity", "date_settled")
  for (column in c("lowest_offer", "weighted_average_offer")) {
    data <- data.frame(
      date_held = as.Date(c("2026-05-01", "2026-06-01")),
      tender_number_buyback_method = c("RBA", "TBB1"),
      maturity = as.Date(c("2028-04-21", "2029-04-21")),
      amount_repurchased = c(100, 120),
      date_settled = as.Date(c("2026-05-05", "2026-06-05")),
      stringsAsFactors = FALSE
    )
    data[[column]] <- c(NA_character_, "schema-drift")

    expect_error(
      readAOFM:::aofm_transactional_measure_columns(
        data,
        required,
        "read_transactional(tb_buyback)"
      ),
      paste0(column, ".*row\\(s\\) 2")
    )
  }
})

test_that("offline fixtures cover every parser and special schema branch", {
  cases <- list(
    summary = "summary.xlsx",
    aggregate_position_dealt = "tn_position_dealt.xlsx",
    aggregate_position_settlement = "tn_position_dealt.xlsx",
    tb_position_dealt = "tb_position_dealt.xlsx",
    tb_position_settlement = "tb_position_dealt.xlsx",
    tib_position_dealt = "tb_position_dealt.xlsx",
    tib_position_settlement = "tb_position_dealt.xlsx",
    tn_position_dealt = "tn_position_dealt.xlsx",
    tn_position_settlement = "tn_position_dealt.xlsx",
    tb_issuance = "tb_issuance.xlsx",
    tb_buyback = "tb_buyback.xlsx",
    tib_issuance = "tib_issuance.xlsx",
    tib_buyback = "tib_buyback.xlsx",
    tn_issuance = "tib_issuance.xlsx",
    retail = "retail.xlsx",
    slf = "slf.xlsx",
    tb_syndication = "tb_syndication.xlsx",
    tib_syndication = "tib_syndication.xlsx",
    ownership_public = "ownership_public.xlsx",
    ownership_nonresident = "ownership_nonresident.xlsx",
    tb_turnover = "tb_turnover.xlsx",
    tib_turnover = "tib_turnover.xlsx",
    termpremium = "termpremium.xlsx"
  )
  parsed <- Map(function(table_id, file) {
    read_aofm_file(fixture_path(file), table_id)
  }, names(cases), unname(cases))
  expect_equal(length(parsed), length(cases))
  expect_true(all(vapply(parsed, function(result) {
    components <- if (is.data.frame(result)) list(result) else result
    length(components) > 0L &&
      all(vapply(components, is.data.frame, logical(1))) &&
      all(vapply(components, nrow, integer(1)) > 0L) &&
      !is.null(attr(result, "aofm_metadata"))
  }, logical(1))))
  expect_true(inherits(parsed$retail$settle_date, "Date"))
  expect_true(inherits(parsed$slf$start_date, "Date"))
  expect_setequal(
    unique(parsed$termpremium$type),
    c("TermPremiumOLS", "TermPremiumBC")
  )
})

test_that("non-TB transaction dates use the canonical Excel date origin", {
  cases <- c(
    tib_issuance = "tib_issuance.xlsx",
    tb_buyback = "tb_buyback.xlsx",
    tib_buyback = "tib_buyback.xlsx",
    tn_issuance = "tib_issuance.xlsx"
  )

  for (table_id in names(cases)) {
    file <- unname(cases[[table_id]])
    raw <- readxl::read_excel(
      fixture_path(file),
      sheet = 1,
      col_names = FALSE
    )[[1L]][[4L]]
    expected <- as.Date(as.numeric(raw), origin = "1899-12-31")
    parsed <- read_aofm_file(
      fixture_path(file),
      table_id
    )
    expect_identical(min(parsed$date_held), expected)
  }
})

test_that("typeless search reads pass NULL rather than missing catalogue values", {
  seen <- list()
  testthat::local_mocked_bindings(
    read_aofm = function(
        security, type = NULL, csv, timeout, retries, max_bytes) {
      seen[[length(seen) + 1L]] <<- list(
        security = security,
        type = type
      )
      data.frame(value = 1)
    },
    .package = "readAOFM"
  )

  for (query in c("summary", "retail", "slf", "termpremium")) {
    search_aofm(query, read = TRUE)
  }
  expect_length(seen, 4L)
  expect_true(all(vapply(seen, function(call) {
    is.null(call$type)
  }, logical(1))))
})

test_that("public selectors reject non-scalar and missing controls", {
  expect_error(read_aofm(c("tb", "tib")), "`security`")
  expect_error(read_aofm(NA_character_), "`security`")
  expect_error(read_aofm("tb", c("issuance", "buyback")), "`type`")
  expect_error(read_aofm("tb", NA_character_), "`type`")
  expect_error(read_aofm("tb", "issuance", csv = NA), "`csv`")
  expect_error(search_aofm("summary", read = NA), "`read`")
  expect_error(search_aofm("summary", csv = NA), "`csv`")
  expect_error(aofm_catalog(include_unsupported = NA), "`include_unsupported`")
})

test_that("date and measure conversion reject malformed upstream rows", {
  expect_identical(
    readAOFM:::aofm_excel_date(c(950745600, 1774915200)),
    as.Date(c("2000-02-17", "2026-03-31"))
  )
  expect_error(
    readAOFM:::aofm_excel_date(c("2026-06-01", "schema-drift")),
    "date value.*row.*2"
  )
  expect_error(
    readAOFM:::aofm_numeric_measure(
      c("1.25", "schema-drift"),
      "amount",
      "test parser"
    ),
    "amount.*row.*2"
  )
})

test_that("Notes-first current layouts select data sheets by name", {
  summary <- read_aofm_file(fixture_path("summary.xlsx"), "summary")
  slf <- read_aofm_file(fixture_path("slf.xlsx"), "slf")

  expect_identical(max(summary$date), as.Date("2026-06-30"))
  expect_identical(max(slf$start_date), as.Date("2026-07-01"))
})

test_that("turnover readers join historical and current AOFM workbooks", {
  current <- fixture_path("tb_turnover_current.xlsx")
  history <- fixture_path("tb_turnover.xlsx")

  testthat::local_mocked_bindings(
    download_aofm_table_workbook = function(...) current,
    download_aofm_workbook = function(url, destfile, ...) {
      file.copy(history, destfile, overwrite = TRUE)
      invisible(destfile)
    },
    .package = "readAOFM"
  )

  parsed <- read_secondary("tb_turnover")

  expect_identical(
    sort(unique(parsed$group)),
    c("counterparty", "investor_type", "region", "security", "tenor")
  )
  expect_identical(min(parsed$period), as.Date("2025-12-31"))
  expect_identical(max(parsed$period), as.Date("2026-03-31"))
  expect_identical(
    anyDuplicated(parsed[c("period", "group", "name")]),
    0L
  )

  sources <- attr(parsed, "aofm_sources")
  expect_named(sources, c("historical", "current"))
  expect_identical(sources$historical$role, "historical")
  expect_identical(sources$current$role, "current")
  expect_match(sources$historical$source_url, "turnover_-_treasury_bonds")
  expect_match(sources$current$source_url, "new_turnover_-_treasury_bonds")
  expect_match(sources$historical$raw_sha256, "^[a-f0-9]{64}$")
  expect_match(sources$current$raw_sha256, "^[a-f0-9]{64}$")
})

test_that("source stitching prefers current revisions by natural identity", {
  historical <- data.frame(
    period = as.Date(c("2025-12-31", "2026-01-31")),
    group = c("region", "region"),
    name = c("Australia", "Australia"),
    value = c(100, 110)
  )
  current <- data.frame(
    period = as.Date(c("2026-01-31", "2026-02-28")),
    group = c("region", "region"),
    name = c("Australia", "Australia"),
    value = c(111, 120)
  )

  stitched <- readAOFM:::aofm_stitch_observations(
    historical,
    current,
    identity = c("period", "group", "name"),
    order_by = c("period", "group", "name")
  )

  expect_identical(
    stitched$value,
    c(100, 111, 120)
  )
  expect_identical(
    anyDuplicated(stitched[c("period", "group", "name")]),
    0L
  )
  expect_error(
    readAOFM:::aofm_stitch_observations(
      rbind(historical, historical[1, ]),
      current,
      identity = c("period", "group", "name")
    ),
    "duplicate natural observation identities"
  )
})

test_that("remaining parsers route measures through strict conversion", {
  cases <- c(
    summary = "summary.xlsx",
    tb_position_dealt = "tb_position_dealt.xlsx",
    tb_syndication = "tb_syndication.xlsx",
    ownership_public = "ownership_public.xlsx",
    tb_buyback = "tb_buyback.xlsx",
    tib_buyback = "tib_buyback.xlsx"
  )
  original <- readAOFM:::aofm_numeric_measure

  expect_rejection <- function(table_id, file) {
    injected <- FALSE
    testthat::local_mocked_bindings(
      aofm_numeric_measure = function(x, column, context) {
        if (!injected) {
          raw <- as.character(x)
          row <- which(!is.na(raw) & nzchar(trimws(raw)))[[1L]]
          raw[[row]] <- "schema-drift"
          x <- raw
          injected <<- TRUE
        }
        original(x, column, context)
      },
      .package = "readAOFM"
    )
    expect_error(
      read_aofm_file(fixture_path(file), table_id),
      "non-numeric value"
    )
    expect_true(injected)
  }

  Map(expect_rejection, names(cases), unname(cases))
})

test_that("cache bounds and URL overrides fail closed before I/O", {
  root <- tempfile("aofm-invalid-bounds-")
  invalid_bounds <- list(
    list(max_age = "3600"),
    list(max_files = TRUE),
    list(max_files = .Machine$integer.max),
    list(max_cache_bytes = "1000000"),
    list(max_cache_bytes = Inf)
  )
  for (arguments in invalid_bounds) {
    expect_error(
      do.call(
        download_aofm_file,
        c(list(table_id = "tb_issuance", path = root), arguments)
      ),
      "cache bounds"
    )
  }
  expect_false(dir.exists(root))

  withr::local_options(
    readAOFM.url_overrides = c(unknown_table = "https://www.aofm.gov.au/file.xlsx")
  )
  expect_error(aofm_catalog(), "supported override names")

  withr::local_options(
    readAOFM.url_overrides = c(
      termpremium = "https://evil.example/term-premium.xlsx"
    )
  )
  expect_error(aofm_catalog(), "official AOFM HTTPS")
})

test_that("failed cache publication restores the previous valid pair", {
  root <- tempfile("aofm-pair-rollback-")
  first_source <- fixture_path("tb_issuance.xlsx")
  second_source <- fixture_path("tib_issuance.xlsx")
  source <- first_source
  original_save <- readAOFM:::aofm_atomic_save_rds

  testthat::local_mocked_bindings(
    download_aofm_workbook = function(url, destfile, ...) {
      file.copy(source, destfile, overwrite = TRUE)
      invisible(destfile)
    },
    .package = "readAOFM"
  )
  first <- download_aofm_file("tb_issuance", root)
  first_metadata <- readRDS(file.path(dirname(first), "current.rds"))
  first_bytes <- readBin(first, what = "raw", n = file.info(first)$size)

  source <- second_source
  saves <- 0L
  testthat::local_mocked_bindings(
    aofm_atomic_save_rds = function(object, path) {
      saves <<- saves + 1L
      original_save(object, path)
      if (saves == 1L) {
        writeBin(
          charToRaw("corrupt-new-cache"),
          file.path(dirname(path), object$cache_file)
        )
      }
      invisible(path)
    },
    .package = "readAOFM"
  )
  expect_error(
    download_aofm_file("tb_issuance", root, overwrite = TRUE),
    "final verification"
  )
  restored_metadata <- readRDS(file.path(dirname(first), "current.rds"))
  expect_identical(restored_metadata, first_metadata)
  expect_identical(
    readBin(first, what = "raw", n = file.info(first)$size),
    first_bytes
  )
  expect_length(
    readAOFM:::aofm_owned_cache_files(
      file.path(root, ".readAOFM", "data")
    ),
    1L
  )
})
