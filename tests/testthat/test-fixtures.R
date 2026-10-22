test_that("fixture workbooks are present and have the expected sheets", {
  expect_true(file.exists(fixture_path("tb_issuance.xlsx")))
  expect_true(file.exists(fixture_path("tib_issuance.xlsx")))
  expect_true(file.exists(fixture_path("tb_position_dealt.xlsx")))

  expect_equal(
    readxl::excel_sheets(fixture_path("tb_issuance.xlsx")),
    c("Transactions", "Notes")
  )
  expect_equal(
    readxl::excel_sheets(fixture_path("tib_issuance.xlsx")),
    c("Transactions", "Notes")
  )
  expect_equal(
    readxl::excel_sheets(fixture_path("tb_position_dealt.xlsx")),
    c("Notes", "FaceValue", "MarketValue", "Delta", "Duration", "Tenor")
  )
  expect_equal(
    readxl::excel_sheets(fixture_path("summary.xlsx")),
    c("Notes", "Portfolio")
  )
  expect_equal(
    readxl::excel_sheets(fixture_path("slf.xlsx")),
    c("Notes", "Transactions")
  )
  expect_equal(
    readxl::excel_sheets(fixture_path("tb_turnover_current.xlsx")),
    c("Notes", "Security", "Region", "Counterparty")
  )
})
