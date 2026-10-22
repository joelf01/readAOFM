test_that("the public API export and formal contract is stable", {
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

  expect_identical(
    formals_text("download_aofm_xlsx"),
    c(
      security = "NULL",
      type = "NULL",
      timeout = "getOption(\"readAOFM.timeout\", 30)",
      retries = "getOption(\"readAOFM.retries\", 1L)",
      max_bytes = "getOption(\"readAOFM.max_bytes\", 100 * 1024^2)"
    )
  )
  expect_identical(
    formals_text("read_aofm"),
    c(
      security = "NULL",
      type = "NULL",
      csv = "FALSE",
      timeout = "getOption(\"readAOFM.timeout\", 30)",
      retries = "getOption(\"readAOFM.retries\", 1L)",
      max_bytes = "getOption(\"readAOFM.max_bytes\", 100 * 1024^2)"
    )
  )
  for (name in c(
    "read_eofy",
    "read_eom",
    "read_ownership",
    "read_premium",
    "read_secondary",
    "read_syndication",
    "read_transactional"
  )) {
    expect_identical(
      formals_text(name),
      c(
        aofm_table = "",
        csv = "FALSE",
        timeout = "getOption(\"readAOFM.timeout\", 30)",
        retries = "getOption(\"readAOFM.retries\", 1L)",
        max_bytes = "getOption(\"readAOFM.max_bytes\", 100 * 1024^2)"
      )
    )
  }
  expect_identical(
    formals_text("search_aofm"),
    c(
      query = "",
      read = "FALSE",
      csv = "FALSE",
      timeout = "getOption(\"readAOFM.search_timeout\", 3)",
      retries = "getOption(\"readAOFM.search_retries\", 0L)",
      max_bytes = "getOption(\"readAOFM.max_bytes\", 100 * 1024^2)"
    )
  )

  expect_identical(formals_text("aofm_catalog"), c(include_unsupported = "FALSE"))
  expect_identical(
    formals_text("aofm_file_metadata"),
    c(file_path = "", table_id = "NULL")
  )
  expect_identical(
    formals_text("read_aofm_file"),
    c(file_path = "", table_id = "", csv = "FALSE")
  )
})

test_that("the embedded catalogue preserves the 23 supported and 7 unsupported identities", {
  index <- readAOFM:::aofm_index
  supported <- index$fn != "no function exists"

  expected_supported <- c(
    "summary",
    "aggregate_position_dealt",
    "aggregate_position_settlement",
    "tb_position_dealt",
    "tb_position_settlement",
    "tib_position_dealt",
    "tib_position_settlement",
    "tn_position_dealt",
    "tn_position_settlement",
    "tb_issuance",
    "tb_syndication",
    "tb_buyback",
    "tib_issuance",
    "tib_syndication",
    "tib_buyback",
    "tn_issuance",
    "retail",
    "slf",
    "ownership_public",
    "ownership_nonresident",
    "tb_turnover",
    "tib_turnover",
    "termpremium"
  )
  expected_unsupported <- c(
    "tb_issuance_conversion",
    "indexation_factors",
    "rmbs_transactions",
    "rmbs_auctions",
    "interest_rate_swaps",
    "cross_currency_swaps",
    "portfolio_overview"
  )

  expect_identical(nrow(index), 30L)
  expect_identical(index$id[supported], expected_supported)
  expect_identical(index$id[!supported], expected_unsupported)
  expect_identical(sum(supported), 23L)
  expect_identical(sum(!supported), 7L)
  expect_identical(anyDuplicated(index$id), 0L)
})

test_that("read_aofm dispatches each supported table once in catalogue order", {
  expected_ids <- readAOFM:::aofm_index$id[
    readAOFM:::aofm_index$fn != "no function exists"
  ]
  calls <- character()
  reader_stub <- function(aofm_table, csv = FALSE, ...) {
    calls <<- c(calls, aofm_table)
    list(table_id = aofm_table, csv = csv)
  }

  testthat::local_mocked_bindings(
    read_eofy = reader_stub,
    read_eom = reader_stub,
    read_transactional = reader_stub,
    read_syndication = reader_stub,
    read_ownership = reader_stub,
    read_secondary = reader_stub,
    read_premium = reader_stub,
    .package = "readAOFM"
  )

  result <- read_aofm()

  expect_identical(calls, expected_ids)
  expect_identical(names(result), expected_ids)
  expect_true(all(vapply(result, function(x) identical(x$csv, FALSE), logical(1))))
})

test_that("search_aofm has a stable offline result schema and errors", {
  result <- search_aofm("tb issuance")
  expect_identical(
    names(result),
    c("security", "type", "id", "reader", "read_call")
  )
  expect_identical(nrow(result), 1L)
  expect_identical(result$id, "tb_issuance")
  expect_identical(result$reader, "read_transactional")
  expect_identical(result$read_call, 'read_aofm("tb", "issuance")')

  no_match <- search_aofm("zzzzzzzzzz")
  expect_identical(names(no_match), names(result))
  expect_identical(nrow(no_match), 0L)
  expect_error(
    search_aofm("zzzzzzzzzz", read = TRUE),
    "No supported AOFM table matched query"
  )

  for (query in list(NULL, character(), NA_character_, "", "  ")) {
    expect_error(search_aofm(query), "`query` must be a single non-empty string.")
  }
})

test_that("packaged workbook fixtures are present in source and installed extdata", {
  fixture_sheets <- list(
    tb_issuance.xlsx = c("Transactions", "Notes"),
    tib_issuance.xlsx = c("Transactions", "Notes"),
    tb_position_dealt.xlsx = c(
      "Notes", "FaceValue", "MarketValue", "Delta", "Duration", "Tenor"
    ),
    tb_syndication.xlsx = c("Notes", "New Bond Syndications", "Tap Syndications "),
    tib_syndication.xlsx = c("Notes", "New Bond Syndications", "Tap Syndications")
  )

  for (fixture in names(fixture_sheets)) {
    source_path <- fixture_source_path(fixture)
    installed_path <- fixture_installed_path(fixture)
    expect_true(
      file.exists(source_path) ||
        (nzchar(installed_path) && file.exists(installed_path)),
      info = fixture
    )
    expect_identical(readxl::excel_sheets(fixture_path(fixture)), fixture_sheets[[fixture]])
  }
})

test_that("official fixtures preserve representative output identities and invariants", {
  fixture_map <- c(
    tb_issuance = fixture_path("tb_issuance.xlsx"),
    tb_position_dealt = fixture_path("tb_position_dealt.xlsx"),
    tb_syndication = fixture_path("tb_syndication.xlsx"),
    tib_issuance = fixture_path("tib_issuance.xlsx"),
    tib_syndication = fixture_path("tib_syndication.xlsx")
  )

  testthat::local_mocked_bindings(
    download_aofm_table_workbook = function(aofm_table, ...) fixture_map[[aofm_table]],
    .package = "readAOFM"
  )

  tb_issuance <- suppressMessages(read_aofm("tb", "issuance"))
  expect_identical(dim(tb_issuance), c(26268L, 7L))
  expect_identical(
    names(tb_issuance),
    c("date_held", "tender_number", "maturity", "isin", "date_settled", "name", "value")
  )
  expect_identical(
    unname(vapply(tb_issuance, function(x) paste(class(x), collapse = "/"), character(1))),
    c("Date", "character", "Date", "character", "Date", "character", "numeric")
  )
  expect_identical(unname(range(tb_issuance$date_held)), as.Date(c("1982-08-05", "2025-05-27")))
  expect_identical(unname(range(tb_issuance$date_settled)), as.Date(c("1982-08-10", "2025-05-29")))
  expect_true(all(is.finite(tb_issuance$value)))
  expect_false(anyNA(tb_issuance$value))

  tb_position_dealt <- suppressMessages(read_aofm("tb", "dealt"))
  expect_identical(
    names(tb_position_dealt),
    c(
      "tb_position_dealt_FaceValue",
      "tb_position_dealt_MarketValue",
      "tb_position_dealt_Delta",
      "tb_position_dealt_Duration",
      "tb_position_dealt_Tenor"
    )
  )
  expect_identical(
    unname(t(vapply(tb_position_dealt, dim, integer(2)))),
    rbind(
      c(5450L, 8L),
      c(5450L, 8L),
      c(5450L, 8L),
      c(5450L, 8L),
      c(5450L, 8L)
    )
  )
  for (table in tb_position_dealt) {
    expect_identical(
      names(table),
      c(
        "Liability / Asset",
        "Currency of Issue (all figures in AUD equivalent)",
        "Instrument",
        "Maturity",
        "Coupon (%)",
        "Series",
        "date",
        "value"
      )
    )
    expect_s3_class(table$date, "Date")
    expect_type(table$value, "double")
    expect_true(all(is.finite(table$value)))
  }

  tb_syndication <- suppressMessages(read_aofm("tb", "syndication"))
  expect_identical(dim(tb_syndication), c(578L, 11L))
  expect_identical(
    names(tb_syndication),
    c(
      "bond_line",
      "pricing_date",
      "settlement_date",
      "pricing_reference",
      "initial_price_guidance_bp",
      "final_spread_bp",
      "curve_extension",
      "joint_lead_managers",
      "type",
      "name",
      "value"
    )
  )
  expect_s3_class(tb_syndication$pricing_date, "Date")
  expect_s3_class(tb_syndication$settlement_date, "Date")
  expect_type(tb_syndication$value, "double")
  expect_setequal(unique(tb_syndication$type), c("new_bond", "tap"))

  tib_issuance <- suppressMessages(read_aofm("tib", "issuance"))
  expect_identical(dim(tib_issuance), c(3944L, 7L))
  expect_identical(names(tib_issuance), names(tb_issuance))
  expect_identical(
    unname(vapply(tib_issuance, function(x) paste(class(x), collapse = "/"), character(1))),
    c("Date", "character", "Date", "character", "Date", "character", "numeric")
  )
  expect_true(all(is.finite(tib_issuance$value)))

  tib_syndication <- suppressMessages(read_aofm("tib", "syndication"))
  expect_identical(dim(tib_syndication), c(187L, 11L))
  expect_identical(names(tib_syndication), names(tb_syndication))
  expect_s3_class(tib_syndication$pricing_date, "Date")
  expect_s3_class(tib_syndication$settlement_date, "Date")
  expect_type(tib_syndication$value, "double")
  expect_setequal(unique(tib_syndication$type), c("new_bond", "tap"))
})

test_that("CSV output is opt-in and readers use temporary download staging", {
  fixture <- fixture_path("tb_issuance.xlsx")
  old <- getwd()
  target <- tempfile("readAOFM-contract-")
  dir.create(target)
  setwd(target)
  on.exit(setwd(old), add = TRUE)

  testthat::local_mocked_bindings(
    download_aofm_table_workbook = function(aofm_table, ...) fixture,
    .package = "readAOFM"
  )

  result <- suppressMessages(read_aofm("tb", "issuance", csv = TRUE))

  expect_true(file.exists(file.path("output", "tb_issuance.csv")))
  expect_gt(file.info(file.path("output", "tb_issuance.csv"))$size, 0)
  expect_false(dir.exists("data"))
  expect_identical(nrow(result), 26268L)
})

test_that("selection and downloader validation failures are deterministic and local", {
  expect_error(
    read_aofm("not-a-security"),
    "No supported AOFM table matched security = \"not-a-security\" and type = NULL\\."
  )
  expect_error(
    read_aofm("tb", "not-a-type"),
    "No supported AOFM table matched security = \"tb\" and type = \"not-a-type\"\\."
  )

  destination <- tempfile(fileext = ".xlsx")
  expect_error(
    readAOFM:::download_aofm_workbook("", destination),
    "`url` must be a single non-empty string\\."
  )
  expect_false(file.exists(destination))
  expect_error(
    readAOFM:::download_aofm_workbook("https://example.invalid/file", tempfile(fileext = ".txt")),
    "`destfile` must end in \\.xls or \\.xlsx\\."
  )
})
