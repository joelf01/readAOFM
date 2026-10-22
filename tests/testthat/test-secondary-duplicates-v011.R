secondary_row <- function(value) {
  data.frame(
    period = as.Date("2025-12-31"),
    group = "tenor",
    name = "0-3 years",
    value = value,
    stringsAsFactors = FALSE
  )
}

test_that("secondary parsing rejects identical duplicate source identities", {
  fixture <- fixture_path("tb_turnover.xlsx")

  expect_error(
    testthat::with_mocked_bindings(
      readAOFM:::aofm_parse_secondary_workbook(
        fixture,
        "tb_turnover"
      ),
      aofm_parse_secondary_sheet = function(...) secondary_row(1),
      .package = "readAOFM"
    ),
    "read_secondary\\(tb_turnover\\).*duplicate period/group/name"
  )
})

test_that("secondary parsing rejects conflicting duplicate source identities", {
  fixture <- fixture_path("tb_turnover.xlsx")
  call <- 0L

  expect_error(
    testthat::with_mocked_bindings(
      readAOFM:::aofm_parse_secondary_workbook(
        fixture,
        "tb_turnover"
      ),
      aofm_parse_secondary_sheet = function(...) {
        call <<- call + 1L
        secondary_row(call)
      },
      .package = "readAOFM"
    ),
    "read_secondary\\(tb_turnover\\).*duplicate period/group/name"
  )
})

test_that("stitched turnover has unique natural identities", {
  historical <- rbind(
    secondary_row(1),
    transform(secondary_row(2), period = as.Date("2026-01-31"))
  )
  current <- rbind(
    transform(secondary_row(3), period = as.Date("2026-01-31")),
    transform(secondary_row(4), period = as.Date("2026-02-28"))
  )

  result <- readAOFM:::aofm_stitch_observations(
    historical,
    current,
    identity = c("period", "group", "name")
  )

  expect_identical(
    anyDuplicated(result[c("period", "group", "name")]),
    0L
  )
  expect_identical(result$value, c(1, 3, 4))
})
