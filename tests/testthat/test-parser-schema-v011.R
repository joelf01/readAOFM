test_that("v0.1.1 EOM parsing retains all official components and Series", {
  result <- suppressMessages(readAOFM:::aofm_parse_eom_workbook(
    fixture_path("tb_position_dealt.xlsx"),
    "tb_position_dealt"
  ))

  expect_identical(
    names(result),
    paste0(
      "tb_position_dealt_",
      c("FaceValue", "MarketValue", "Delta", "Duration", "Tenor")
    )
  )
  expect_length(result, 5L)

  expected_columns <- c(
    "Liability / Asset",
    "Currency of Issue (all figures in AUD equivalent)",
    "Instrument",
    "Maturity",
    "Coupon (%)",
    "Series",
    "date",
    "value"
  )
  expect_true(all(vapply(
    result,
    function(x) identical(names(x), expected_columns),
    logical(1)
  )))
  expect_true(all(vapply(
    result,
    function(x) identical(dim(x), c(5450L, 8L)),
    logical(1)
  )))
  expect_true(all(vapply(result, function(x) inherits(x$date, "Date"), logical(1))))
  expect_true(all(vapply(result, function(x) is.integer(x$Series), logical(1))))
  expect_true(all(vapply(result, function(x) is.double(x$value), logical(1))))
  expect_identical(sort(unique(result[[1]]$Series)), 1:2)
})

test_that("v0.1.1 syndication parsing normalizes value to numeric", {
  fixture_names <- c("tb_syndication.xlsx", "tib_syndication.xlsx")

  for (fixture_name in fixture_names) {
    table_id <- sub("\\.xlsx$", "", fixture_name)
    result <- suppressMessages(readAOFM:::aofm_parse_syndication_workbook(
      fixture_path(fixture_name),
      table_id
    ))

    expect_type(result$value, "double")
    expect_true(all(is.finite(result$value)), info = table_id)
    expect_true(all(c("pricing_date", "settlement_date", "name", "value") %in% names(result)))
  }
})
