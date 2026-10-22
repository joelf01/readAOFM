test_that("read_aofm returns all supported tables when security is omitted", {
  reader_stub <- function(aofm_table, csv = FALSE, ...) {
    list(aofm_table = aofm_table, csv = csv)
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

  x <- read_aofm()

  expect_type(x, "list")
  expect_identical(length(x), 23L)
  expect_identical(names(x)[[1]], "summary")
  expect_identical(names(x)[[length(x)]], "termpremium")
  expect_true(all(vapply(x, function(item) identical(item$csv, FALSE), logical(1))))
})

test_that("read_aofm can filter by type without security", {
  reader_stub <- function(aofm_table, csv = FALSE, ...) {
    list(aofm_table = aofm_table, csv = csv)
  }

  testthat::local_mocked_bindings(
    read_eom = reader_stub,
    read_transactional = reader_stub,
    read_syndication = reader_stub,
    read_ownership = reader_stub,
    read_secondary = reader_stub,
    .package = "readAOFM"
  )

  x <- read_aofm(type = "issuance")

  expect_type(x, "list")
  expect_identical(names(x), c("tb_issuance", "tib_issuance", "tn_issuance"))
})

test_that("search_aofm returns matching catalog rows", {
  x <- search_aofm("tb issuance")

  expect_true(is.data.frame(x))
  expect_identical(x$id, "tb_issuance")
  expect_identical(x$read_call, 'read_aofm("tb", "issuance")')
})

test_that("search_aofm understands treasury bond language", {
  x <- search_aofm("treasury bond")

  expect_true(is.data.frame(x))
  expect_true(nrow(x) >= 1)
  expect_true(all(grepl("^tb_", x$id)))
  expect_setequal(
    x$id,
    c(
      "tb_buyback",
      "tb_position_dealt",
      "tb_issuance",
      "tb_position_settlement",
      "tb_syndication",
      "tb_turnover"
    )
  )
})

test_that("search_aofm understands inflation language", {
  x <- search_aofm("inflation")

  expect_true(is.data.frame(x))
  expect_true(nrow(x) >= 1)
  expect_true(all(grepl("^tib_", x$id)))
  expect_setequal(
    x$id,
    c(
      "tib_buyback",
      "tib_position_dealt",
      "tib_issuance",
      "tib_position_settlement",
      "tib_syndication",
      "tib_turnover"
    )
  )
})

test_that("search_aofm understands foreign ownership language", {
  x <- search_aofm("foreign ownership")

  expect_true(is.data.frame(x))
  expect_identical(x$id, "ownership_nonresident")
})

test_that("search_aofm can read multiple matches through read_aofm", {
  testthat::local_mocked_bindings(
    read_aofm = function(security = NULL, type = NULL, csv = FALSE, ...) {
      list(security = security, type = type, csv = csv)
    },
    .package = "readAOFM"
  )

  x <- search_aofm("issuance", read = TRUE, csv = TRUE)

  expect_type(x, "list")
  expect_identical(names(x), c("tb_issuance", "tib_issuance", "tn_issuance"))
  expect_true(all(vapply(x, function(item) identical(item$csv, TRUE), logical(1))))
})

test_that("search_aofm can read a single exact match", {
  testthat::local_mocked_bindings(
    read_aofm = function(security = NULL, type = NULL, csv = FALSE, ...) {
      data.frame(security = security, type = type, csv = csv, stringsAsFactors = FALSE)
    },
    .package = "readAOFM"
  )

  x <- search_aofm("tb syndication", read = TRUE)

  expect_true(is.data.frame(x))
  expect_identical(x$security[[1]], "tb")
  expect_identical(x$type[[1]], "syndication")
})

test_that("read_aofm returns all supported tables for a security when type is omitted", {
  testthat::local_mocked_bindings(
    read_eom = function(aofm_table, csv = FALSE, ...) {
      list(aofm_table = aofm_table, csv = csv, reader = "read_eom")
    },
    read_transactional = function(aofm_table, csv = FALSE, ...) {
      list(aofm_table = aofm_table, csv = csv, reader = "read_transactional")
    },
    read_syndication = function(aofm_table, csv = FALSE, ...) {
      list(aofm_table = aofm_table, csv = csv, reader = "read_syndication")
    },
    read_secondary = function(aofm_table, csv = FALSE, ...) {
      list(aofm_table = aofm_table, csv = csv, reader = "read_secondary")
    },
    .package = "readAOFM"
  )

  x <- read_aofm("tb")

  expect_type(x, "list")
  expect_identical(
    names(x),
    c(
      "tb_position_dealt",
      "tb_position_settlement",
      "tb_issuance",
      "tb_syndication",
      "tb_buyback",
      "tb_turnover"
    )
  )
  expect_true(all(vapply(x, function(item) identical(item$csv, FALSE), logical(1))))
})

test_that("read_aofm parses tb issuance from a fixture workbook", {
  fixture <- fixture_path("tb_issuance.xlsx")

  testthat::local_mocked_bindings(
    curl_download = function(url, destfile, ...) {
      file.copy(fixture, destfile, overwrite = TRUE)
      invisible(destfile)
    },
    curl_fetch_disk = function(url, path, ...) {
      file.copy(fixture, path, overwrite = TRUE)
      list(
        status_code = 200L,
        type = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        url = url
      )
    },
    .package = "curl"
  )

  x <- read_aofm("tb", "issuance")

  expect_true(is.data.frame(x))
  expect_true(all(c("date_held", "tender_number", "maturity", "name", "value") %in% names(x)))
  expect_true(inherits(x$date_held, "Date"))
  expect_lt(min(x$date_held, na.rm = TRUE), as.Date("1990-01-01"))
  expect_gt(nrow(x), 1000)
})

test_that("read_aofm threads csv through to the underlying reader", {
  fixture <- fixture_path("tb_issuance.xlsx")
  written <- NULL

  testthat::local_mocked_bindings(
    curl_fetch_disk = function(url, path, ...) {
      file.copy(fixture, path, overwrite = TRUE)
      list(
        status_code = 200L,
        type = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        url = url
      )
    },
    .package = "curl"
  )
  testthat::local_mocked_bindings(
    write_csv = function(x, file, ...) {
      written <<- file
      invisible(x)
    },
    .package = "readr"
  )

  read_aofm("tb", "issuance", csv = TRUE)

  expect_true(is.character(written))
  expect_match(written, "output[/\\\\]tb_issuance\\.csv$")
})

test_that("read_aofm parses tb dealt positions from a fixture workbook", {
  fixture <- fixture_path("tb_position_dealt.xlsx")

  testthat::local_mocked_bindings(
    curl_fetch_disk = function(url, path, ...) {
      file.copy(fixture, path, overwrite = TRUE)
      list(
        status_code = 200L,
        type = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        url = url
      )
    },
    .package = "curl"
  )

  x <- read_aofm("tb", "dealt")

  expect_type(x, "list")
  expect_equal(length(x), 5)
  expect_true(any(grepl("Tenor", names(x), fixed = TRUE)))
  expect_true(all(vapply(x, is.data.frame, logical(1))))
  expect_true(any(grepl("FaceValue", names(x), fixed = TRUE)))
})

test_that("read_aofm parses tb syndication from a fixture workbook", {
  fixture <- fixture_path("tb_syndication.xlsx")

  testthat::local_mocked_bindings(
    curl_fetch_disk = function(url, path, ...) {
      file.copy(fixture, path, overwrite = TRUE)
      list(
        status_code = 200L,
        type = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        url = url
      )
    },
    .package = "curl"
  )

  x <- read_aofm("tb", "syndication")

  expect_true(is.data.frame(x))
  expect_true(all(c("pricing_date", "settlement_date", "type", "name", "value") %in% names(x)))
  expect_true(inherits(x$pricing_date, "Date"))
  expect_true(all(sort(unique(x$type)) == c("new_bond", "tap")))
  expect_gt(nrow(x), 100)
})

test_that("read_aofm parses tib syndication from a fixture workbook", {
  fixture <- fixture_path("tib_syndication.xlsx")

  testthat::local_mocked_bindings(
    curl_fetch_disk = function(url, path, ...) {
      file.copy(fixture, path, overwrite = TRUE)
      list(
        status_code = 200L,
        type = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        url = url
      )
    },
    .package = "curl"
  )

  x <- read_aofm("tib", "syndication")

  expect_true(is.data.frame(x))
  expect_true(all(c("pricing_date", "settlement_date", "type", "name", "value") %in% names(x)))
  expect_true(inherits(x$pricing_date, "Date"))
  expect_true(all(sort(unique(x$type)) == c("new_bond", "tap")))
  expect_gt(nrow(x), 100)
})
