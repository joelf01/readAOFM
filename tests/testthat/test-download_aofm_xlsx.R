test_that("download_aofm_xlsx targets the matched file", {
  old <- getwd()
  setwd(tempdir())
  on.exit(setwd(old), add = TRUE)

  fixture <- fixture_path("tb_issuance.xlsx")
  seen <- list()

  testthat::local_mocked_bindings(
    download_aofm_workbook = function(url, destfile, ...) {
      seen[[length(seen) + 1L]] <<- list(url = url, destfile = destfile)
      dir.create(dirname(destfile), recursive = TRUE, showWarnings = FALSE)
      file.copy(fixture, destfile, overwrite = TRUE)
      invisible(destfile)
    },
    .package = "readAOFM"
  )

  download_aofm_xlsx("tb", "issuance")

  expect_true(dir.exists("data"))
  expect_true(length(seen) >= 1L)
  expect_true(any(grepl(
    "treasury%20bonds%20-%20issuance",
    vapply(seen, `[[`, character(1), "url"),
    ignore.case = TRUE
  )))
  expect_true(any(grepl("data[/\\\\]tb_issuance\\.xlsx$", vapply(seen, `[[`, character(1), "destfile"))))
})
