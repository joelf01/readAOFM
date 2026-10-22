test_that("the 0.1.1 API delta has exactly 14 exports and bounded formals", {
  expected_exports <- c(
    "aofm_catalog",
    "aofm_file_metadata",
    "download_aofm_file",
    "download_aofm_xlsx",
    "read_aofm",
    "read_aofm_file",
    "read_eofy",
    "read_eom",
    "read_ownership",
    "read_premium",
    "read_secondary",
    "read_syndication",
    "read_transactional",
    "search_aofm"
  )
  expect_identical(
    sort(getNamespaceExports("readAOFM")),
    sort(expected_exports)
  )

  formals_text <- function(name) {
    fm <- formals(get(name, envir = asNamespace("readAOFM")))
    setNames(
      vapply(fm, function(x) paste(deparse(x), collapse = " "), character(1)),
      names(fm)
    )
  }

  transport_defaults <- c(
    timeout = "getOption(\"readAOFM.timeout\", 30)",
    retries = "getOption(\"readAOFM.retries\", 1L)",
    max_bytes = "getOption(\"readAOFM.max_bytes\", 100 * 1024^2)"
  )
  expect_identical(
    tail(formals_text("download_aofm_xlsx"), 3L),
    transport_defaults
  )
  expect_identical(tail(formals_text("read_aofm"), 3L), transport_defaults)
  for (name in c(
    "read_eofy",
    "read_eom",
    "read_ownership",
    "read_premium",
    "read_secondary",
    "read_syndication",
    "read_transactional"
  )) {
    expect_identical(tail(formals_text(name), 3L), transport_defaults)
  }
  expect_identical(
    tail(formals_text("search_aofm"), 3L),
    c(
      timeout = "getOption(\"readAOFM.search_timeout\", 3)",
      retries = "getOption(\"readAOFM.search_retries\", 0L)",
      max_bytes = "getOption(\"readAOFM.max_bytes\", 100 * 1024^2)"
    )
  )
})

test_that("the public catalogue exposes the exact 30-row direct route map", {
  expected_routes <- c(
    summary = "https://www.aofm.gov.au/sites/default/files/2025-06-06/portfolio_aggregate_-_executive_summary_-_dealt.xlsx",
    aggregate_position_dealt = "https://www.aofm.gov.au/sites/default/files/2025-05-02/portfolio_aggregate_-_dealt_4.xlsx",
    aggregate_position_settlement = "https://www.aofm.gov.au/sites/default/files/2025-05-02/portfolio_aggregate_-_settlement.xlsx",
    tb_position_dealt = "https://www.aofm.gov.au/sites/default/files/2025-05-02/portfolio_aggregate_-_treasury_bonds_-_dealt.xlsx",
    tb_position_settlement = "https://www.aofm.gov.au/sites/default/files/2025-05-02/portfolio_aggregate_-_treasury_bonds_-_settlement.xlsx",
    tib_position_dealt = "https://www.aofm.gov.au/sites/default/files/2025-05-02/portfolio_aggregate_-_treasury_indexed_bonds_-_dealt.xlsx",
    tib_position_settlement = "https://www.aofm.gov.au/sites/default/files/2025-05-02/portfolio_aggregate_-_treasury_indexed_bonds_-_settlement.xlsx",
    tn_position_dealt = "https://www.aofm.gov.au/sites/default/files/2025-05-02/portfolio_aggregate_-_treasury_notes_-_dealt_1.xlsx",
    tn_position_settlement = "https://www.aofm.gov.au/sites/default/files/2025-05-02/portfolio_aggregate_-_treasury_notes_-_settlement.xlsx",
    tb_issuance = "https://www.aofm.gov.au/sites/default/files/2025-06-20/treasury%20bonds%20-%20issuance.xlsx",
    tb_issuance_conversion = "https://www.aofm.gov.au/sites/default/files/2025-06-06/treasury%20bonds%20-%20conversion%20and%20switch.xlsx",
    tb_syndication = "https://www.aofm.gov.au/sites/default/files/2025-06-06/TB%20Syndications.xlsx",
    tb_buyback = "https://www.aofm.gov.au/sites/default/files/2025-06-06/treasury%20bonds%20-%20buybacks.xlsx",
    tib_issuance = "https://www.aofm.gov.au/sites/default/files/2025-07-10/Treasury%20Indexed%20Bonds%20-%20Issuance_0.xlsx",
    tib_syndication = "https://www.aofm.gov.au/sites/default/files/2025-06-06/TIB%20syndications.xlsx",
    tib_buyback = "https://www.aofm.gov.au/sites/default/files/2025-06-06/treasury%20indexed%20bonds%20-%20buybacks.xlsx",
    tn_issuance = "https://www.aofm.gov.au/sites/default/files/2025-06-05/Treasury%20Notes%20-%20Issuance.xlsx",
    retail = "https://www.aofm.gov.au/sites/default/files/2025-06-06/retail%20register%20buybacks.xlsx",
    slf = "https://www.aofm.gov.au/sites/default/files/2025-06-06/securities%20lending%20facility.xlsx",
    ownership_public = "https://www.aofm.gov.au/sites/default/files/2025-05-02/register_of_government_borrowing.xlsx",
    ownership_nonresident = "https://www.aofm.gov.au/sites/default/files/2025-05-02/foreign_holdings.xlsx",
    tb_turnover = "https://www.aofm.gov.au/sites/default/files/2026-05-29/new_turnover_-_treasury_bonds.xlsx",
    tib_turnover = "https://www.aofm.gov.au/sites/default/files/2026-05-29/new_turnover_-_treasury_indexed_bonds.xlsx",
    termpremium = "https://www.aofm.gov.au/sites/default/files/2025-06-06/term%20premium.xlsx",
    indexation_factors = "https://www.aofm.gov.au/sites/default/files/2025-05-02/treasury_indexed_bonds_-_indexation_factors_1.xlsx",
    rmbs_transactions = "https://www.aofm.gov.au/sites/default/files/2025-05-02/rmbs_-_transactions_0.xlsx",
    rmbs_auctions = "https://www.aofm.gov.au/sites/default/files/2025-05-02/rmbs_-_auction_results.xlsx",
    interest_rate_swaps = "https://www.aofm.gov.au/sites/default/files/2025-05-02/interest_rate_swaps_-_australian_dollar.xlsx",
    cross_currency_swaps = "https://www.aofm.gov.au/sites/default/files/2025-05-02/interest_rate_swaps_-_cross_currency.xlsx",
    portfolio_overview = "https://www.aofm.gov.au/sites/default/files/2019-06/australian_government_securities_on_issue_-_1983_to_2002.xlsx"
  )
  expected_supported <- c(
    "summary", "aggregate_position_dealt", "aggregate_position_settlement",
    "tb_position_dealt", "tb_position_settlement", "tib_position_dealt",
    "tib_position_settlement", "tn_position_dealt", "tn_position_settlement",
    "tb_issuance", "tb_syndication", "tb_buyback", "tib_issuance",
    "tib_syndication", "tib_buyback", "tn_issuance", "retail", "slf",
    "ownership_public", "ownership_nonresident", "tb_turnover",
    "tib_turnover", "termpremium"
  )
  expected_raw_only <- c(
    "tb_issuance_conversion", "indexation_factors", "rmbs_transactions",
    "rmbs_auctions", "interest_rate_swaps", "cross_currency_swaps",
    "portfolio_overview"
  )
  catalog <- aofm_catalog(include_unsupported = TRUE)

  expect_identical(catalog$table_id, names(expected_routes))
  expect_identical(catalog$source_url, unname(expected_routes))
  expect_identical(catalog$table_id[catalog$supported], expected_supported)
  expect_identical(catalog$table_id[!catalog$supported], expected_raw_only)
  expect_false(any(grepl("/media/", catalog$source_url, fixed = TRUE)))
  expect_true(all(grepl(
    "^https://www\\.aofm\\.gov\\.au/sites/default/files/",
    catalog$source_url
  )))
  expect_identical(
    tolower(tools::file_ext(utils::URLdecode(catalog$source_url))),
    tolower(tools::file_ext(catalog$file_name))
  )

  rows <- lapply(catalog$table_id, readAOFM:::aofm_table_row)
  expect_identical(
    vapply(rows, function(row) row$file.path[[1L]], character(1)),
    unname(expected_routes)
  )
})

test_that("the public download path applies every direct route offline", {
  catalog <- aofm_catalog(include_unsupported = TRUE)
  calls <- list()
  download_root <- tempfile("readAOFM-route-download-")
  dir.create(download_root)
  withr::local_dir(download_root)

  testthat::local_mocked_bindings(
    download_aofm_workbook = function(url, destfile, ...) {
      calls[[length(calls) + 1L]] <<- list(url = url, destfile = destfile)
      dir.create(dirname(destfile), recursive = TRUE, showWarnings = FALSE)
      file.create(destfile)
      invisible(destfile)
    },
    .package = "readAOFM"
  )

  capture.output(download_aofm_xlsx())
  expect_identical(length(calls), nrow(catalog))
  expect_identical(
    vapply(calls, `[[`, character(1), "url"),
    catalog$source_url
  )
  expect_identical(
    tolower(tools::file_ext(vapply(calls, `[[`, character(1), "destfile"))),
    tolower(tools::file_ext(catalog$file_name))
  )
})

test_that("generated sysdata and public routes match the authoritative map", {
  sysdata <- file.path(testthat::test_path("..", "..", "R", "sysdata.rda"))
  if (file.exists(sysdata)) {
    expect_identical(
      digest::digest(
        sysdata,
        algo = "sha256",
        file = TRUE,
        serialize = FALSE
      ),
      "985ca7d08373871c1f2f2a92514fec8326742602a47d24c7e0ecf844e7218a29"
    )
  }
  expect_identical(dim(readAOFM:::aofm_index), c(30L, 9L))
  expect_identical(dim(readAOFM:::aofm_index_nav), c(30L, 5L))
  expect_false(any(grepl(
    "/media/",
    readAOFM:::aofm_index$file.path,
    fixed = TRUE
  )))
  public <- aofm_catalog(include_unsupported = TRUE)
  expect_identical(public$table_id, readAOFM:::aofm_index$id)
  expect_identical(public$source_url, readAOFM:::aofm_index$file.path)
  expect_identical(public$file_name, readAOFM:::aofm_index$file.save)
  expect_identical(public$description, readAOFM:::aofm_index$despription)

  source_path <- file.path(
    testthat::test_path("..", "..", "data-raw"),
    "aofm_catalog_source.csv"
  )
  if (file.exists(source_path)) {
    source <- utils::read.csv(
      source_path,
      stringsAsFactors = FALSE,
      check.names = FALSE,
      na.strings = c("", "NA")
    )
    expect_identical(
      digest::digest(
        source_path,
        algo = "sha256",
        file = TRUE,
        serialize = FALSE
      ),
      "3a0ba9bfbac04ca623ed2da5a1783078352badf624e85375ffdd134a3be526b1"
    )
    expect_identical(readAOFM:::aofm_index, source[names(readAOFM:::aofm_index)])
  }
})

test_that("turnover catalogue descriptions carry the cadence and join contract", {
  descriptions <- aofm_catalog(include_unsupported = TRUE)
  descriptions <- descriptions$description[
    descriptions$table_id %in% c("tb_turnover", "tib_turnover")
  ]
  terms <- c(
    "By Tenor", "monthly", "By Category", "quarterly", "December 2025",
    "Security", "Region", "Counterparty", "January 2026", "two-month lag",
    "period, group and name", "current precedence",
    "duplicate keys", "SHA-256"
  )
  expect_true(all(vapply(descriptions, function(description) {
    all(vapply(terms, grepl, logical(1), x = description, fixed = TRUE))
  }, logical(1))))
})

test_that("the turnover documentation records source-specific cadence and joining", {
  root <- testthat::test_path("..", "..")
  source_paths <- file.path(root, c(
    "R/individual_table_functions.R",
    "README.Rmd",
    "vignettes/table-catalog.Rmd",
    "man/read_secondary.Rd"
  ))
  source_mode <- all(file.exists(source_paths))
  if (source_mode) {
    paths <- source_paths
    path_names <- basename(source_paths)
  } else {
    paths <- c(
      table_catalog = system.file(
        "doc", "table-catalog.Rmd", package = "readAOFM"
      ),
      route_continuity = system.file(
        "extdata", "README-aofm-route-continuity.md", package = "readAOFM"
      ),
      contract_v011 = system.file(
        "contract", "api-behavior-0.1.1.md", package = "readAOFM"
      )
    )
    # Direct source installs used by covr do not build inst/doc. The durable
    # installed continuity record, contract, and Rd topic still carry the full
    # cadence contract, while the pkgdown workflow validates the article.
    paths <- paths[nzchar(paths)]
    expect_true(all(c("route_continuity", "contract_v011") %in% names(paths)))
    path_names <- names(paths)
  }
  texts <- lapply(paths, function(path) paste(
      readLines(path, warn = FALSE, encoding = "UTF-8"),
      collapse = "\n"
    ))
  names(texts) <- path_names

  if (!source_mode) {
    rd <- tools::Rd_db("readAOFM")
    expect_true("read_secondary.Rd" %in% names(rd))
    texts$installed_read_secondary <- paste(
      capture.output(tools::Rd2txt(rd[["read_secondary.Rd"]])),
      collapse = "\n"
    )
  }

  for (label in names(texts)) {
    text <- texts[[label]]
    expect_match(text, "monthly", info = label)
    expect_match(text, "quarterly", info = label)
    expect_match(text, "two-month lag", info = label)
    expect_match(text, "(historical|history).*(current|redesigned)", info = label)
    expect_match(text, "period.*group.*name", info = label)
  }
})

test_that("turnover stitching preserves groups, identity, precedence, and provenance", {
  current_path <- fixture_path("tb_turnover_current.xlsx")
  historical_path <- fixture_path("tb_turnover.xlsx")
  current_url <- paste0(
    "https://www.aofm.gov.au/sites/default/files/2026-05-29/",
    "new_turnover_-_treasury_bonds.xlsx"
  )
  historical_url <- paste0(
    "https://www.aofm.gov.au/sites/default/files/2025-05-02/",
    "turnover_-_treasury_bonds.xlsx"
  )
  current_source <- readAOFM:::aofm_workbook_source(
    current_path,
    table_id = "tb_turnover",
    source_url = current_url,
    role = "current"
  )
  downloads <- character()

  testthat::local_mocked_bindings(
    download_aofm_table_workbook = function(aofm_table, ...) {
      path <- current_path
      attr(path, "aofm_source") <- current_source
      path
    },
    download_aofm_workbook = function(url, destfile, ...) {
      downloads <<- c(downloads, url)
      file.copy(historical_path, destfile, overwrite = TRUE)
      invisible(destfile)
    },
    .package = "readAOFM"
  )

  result <- read_secondary("tb_turnover")
  expect_named(result, c("period", "group", "name", "value"))
  expect_s3_class(result$period, "Date")
  expect_type(result$name, "character")
  expect_type(result$value, "double")
  expect_identical(
    sort(unique(result$group)),
    c("counterparty", "investor_type", "region", "security", "tenor")
  )
  expect_identical(
    range(result$period),
    as.Date(c("2025-12-31", "2026-03-31"))
  )
  expect_identical(anyDuplicated(result[c("period", "group", "name")]), 0L)
  expect_identical(downloads, historical_url)

  sources <- attr(result, "aofm_sources")
  expect_named(sources, c("historical", "current"))
  expected_fields <- c(
    "schema_version",
    "table_id",
    "role",
    "source_url",
    "source_filename",
    "raw_sha256",
    "raw_bytes",
    "retrieved_at"
  )
  expect_identical(names(sources$historical), expected_fields)
  expect_identical(names(sources$current), expected_fields)
  expect_identical(sources$historical$schema_version, 1L)
  expect_identical(sources$current$schema_version, 1L)
  expect_identical(sources$historical$role, "historical")
  expect_identical(sources$current$role, "current")
  expect_identical(sources$historical$source_url, historical_url)
  expect_identical(sources$current$source_url, current_url)
  expect_identical(
    sources$historical$source_filename,
    "turnover_-_treasury_bonds.xlsx"
  )
  expect_identical(
    sources$current$source_filename,
    "new_turnover_-_treasury_bonds.xlsx"
  )
  for (source in sources) {
    expect_match(source$raw_sha256, "^[a-f0-9]{64}$")
    expect_true(is.numeric(source$raw_bytes) && source$raw_bytes > 0)
    expect_s3_class(source$retrieved_at, "POSIXct")
  }
})

test_that("turnover stitching prefers current rows and rejects duplicate identities", {
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
  expect_identical(stitched$value, c(100, 111, 120))
  expect_identical(anyDuplicated(stitched[c("period", "group", "name")]), 0L)
  expect_error(
    readAOFM:::aofm_stitch_observations(
      rbind(historical, historical[2L, , drop = FALSE]),
      current,
      identity = c("period", "group", "name"),
      order_by = c("period", "group", "name")
    ),
    "duplicate natural observation identities"
  )
})

test_that("0.1.1 non-turnover schema corrections are explicit and offline", {
  eom <- read_aofm_file(
    fixture_path("tb_position_dealt.xlsx"),
    "tb_position_dealt"
  )
  expect_true("tb_position_dealt_Tenor" %in% names(eom))
  expect_true(all(vapply(eom, function(item) {
    all(c("Series", "date", "value") %in% names(item))
  }, logical(1))))
  expect_true(all(vapply(eom, function(item) any(!is.na(item$Series)), logical(1))))

  syndication <- read_aofm_file(
    fixture_path("tb_syndication.xlsx"),
    "tb_syndication"
  )
  expect_type(syndication$value, "double")
  expect_true(all(is.finite(syndication$value)))
})

test_that("non-turnover issuance fixture output retains the 0.1.0 identity", {
  testthat::local_mocked_bindings(
    download_aofm_table_workbook = function(aofm_table, ...) {
      fixture_path("tb_issuance.xlsx")
    },
    .package = "readAOFM"
  )
  result <- suppressMessages(read_aofm("tb", "issuance"))

  portable_column_hash <- function(column) {
    bytes <- if (inherits(column, "Date")) {
      writeBin(as.integer(column), raw(), size = 4L, endian = "little")
    } else if (is.double(column)) {
      writeBin(column, raw(), size = 8L, endian = "little")
    } else if (is.integer(column)) {
      writeBin(column, raw(), size = 4L, endian = "little")
    } else {
      values <- enc2utf8(as.character(column))
      missing <- is.na(column)
      values[missing] <- "<NA>"
      values[!missing] <- paste0(
        nchar(values[!missing], type = "bytes"),
        ":",
        values[!missing]
      )
      charToRaw(paste(values, collapse = "\n"))
    }
    digest::digest(bytes, algo = "sha256", serialize = FALSE)
  }

  expect_identical(
    dim(result),
    c(26268L, 7L)
  )
  expect_identical(
    names(result),
    c(
      "date_held", "tender_number", "maturity", "isin", "date_settled",
      "name", "value"
    )
  )
  expect_identical(class(result), c("tbl_df", "tbl", "data.frame"))
  expect_identical(row.names(result), as.character(seq_len(nrow(result))))
  expect_identical(
    vapply(result, function(column) paste(class(column), collapse = "/"), character(1)),
    c(
      date_held = "Date",
      tender_number = "character",
      maturity = "Date",
      isin = "character",
      date_settled = "Date",
      name = "character",
      value = "numeric"
    )
  )
  expect_identical(
    vapply(result, portable_column_hash, character(1)),
    c(
      date_held = "c32e1d2a7791d57e23597a9f6d210991bead1501887aef29bee4f3950cad9028",
      tender_number = "0324606619650cd96f4e10bb8d225c1c55bf4bfa775069a5d98ec129ac6cd279",
      maturity = "38b65f6f8b4ac56f29df8d02486a090334ca96c52184ffb72f50ace1221d4fa1",
      isin = "51d57b68cd6e406cd46e3d228a0134cc61f0cb78b87f76fd12e25f12296378c4",
      date_settled = "67830b37f3d392fa0545b4ccdcb47e79c6f5df555016d37e2a8104a3c89bef45",
      name = "9a3a875ba421c6f33175257456ec80d132c4d4e5ae01c92949fd35118b9b1f83",
      value = "afb95a1f065ae10c327c7968cc5558f7f23093849fb0e4d33b87d6b4d22c4b84"
    )
  )
})
