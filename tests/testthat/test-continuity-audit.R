test_that("the checked continuity audit covers every public route", {
  path <- system.file(
    "extdata",
    "aofm-route-continuity-2026-07-27.csv",
    package = "readAOFM"
  )
  expect_true(nzchar(path))
  audit <- utils::read.csv(path, stringsAsFactors = FALSE)

  expect_identical(audit$table_id, aofm_catalog()$table_id)
  expect_identical(nrow(audit), 23L)
  expect_setequal(
    audit$table_id[audit$stitch_required == "yes"],
    c("tb_turnover", "tib_turnover")
  )
  expect_true(all(as.Date(audit$combined_min) <= as.Date(audit$legacy_min)))
  expect_true(all(as.Date(audit$combined_max) >= as.Date(audit$legacy_max)))

  urls <- utils::read.csv(
    system.file(
      "extdata",
      "aofm-live-source-urls-2026-07-27.csv",
      package = "readAOFM"
    ),
    stringsAsFactors = FALSE
  )
  expect_identical(urls$table_id, audit$table_id)
  expect_true(all(startsWith(
    urls$current_source_url,
    "https://www.aofm.gov.au/"
  )))
  expect_setequal(
    urls$table_id[nzchar(urls$historical_source_url)],
    c("tb_turnover", "tib_turnover")
  )
})
