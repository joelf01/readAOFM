# The synthetic /media error URLs below exercise transport failures only. The
# successful path uses the current direct catalogue route.

test_that("workbook downloads use bounded transport settings", {
  captured <- new.env(parent = emptyenv())
  fixture <- tempfile(fileext = ".xlsx")

  testthat::local_mocked_bindings(
    curl_options = function() c(protocols_str = 1L, redir_protocols_str = 2L),
    new_handle = function(...) {
      captured$handle <- list(...)
      captured$handle
    },
    curl_fetch_disk = function(url, path, handle) {
      captured$url <- url
      captured$path <- path
      captured$handle_received <- handle
      writeBin(as.raw(c(0x50, 0x4b, 0x03, 0x04)), path)
      list(
        status_code = 200L,
        type = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
      )
    },
    .package = "curl"
  )

  url <- paste0(
    "https://www.aofm.gov.au/sites/default/files/2025-06-20/",
    "treasury%20bonds%20-%20issuance.xlsx"
  )
  result <- readAOFM:::download_aofm_workbook(url, fixture)

  expect_identical(result, fixture)
  expect_identical(captured$url, url)
  expect_identical(dirname(captured$path), dirname(fixture))
  expect_match(basename(captured$path), "[.]part$")
  expect_identical(captured$handle_received, captured$handle)
  expect_false(captured$handle$followlocation)
  expect_identical(captured$handle$http_version, 2L)
  expect_equal(captured$handle$connecttimeout, 10)
  expect_equal(captured$handle$timeout, 30)
  expect_equal(captured$handle$maxfilesize_large, 100 * 1024^2)
  expect_identical(captured$handle$protocols_str, "https")
  expect_identical(captured$handle$redir_protocols_str, "https")
  expect_match(captured$handle$useragent, "^readAOFM/0[.]1[.]2$")
})

test_that("HTTPS restrictions select only supported protocol options", {
  expect_identical(
    readAOFM:::aofm_https_protocol_options(c("protocols_str", "redir_protocols_str")),
    list(protocols_str = "https", redir_protocols_str = "https")
  )
  expect_identical(
    readAOFM:::aofm_https_protocol_options(c("protocols", "redir_protocols")),
    list(protocols = 2L, redir_protocols = 2L)
  )
  expect_error(
    readAOFM:::aofm_https_protocol_options(c("protocols_str", "protocols")),
    "cannot enforce HTTPS-only"
  )
})

test_that("older curl options preserve bounded official workbook retrieval", {
  seen <- NULL
  source <- fixture_path("tb_issuance.xlsx")
  destination <- tempfile(fileext = ".xlsx")
  on.exit(unlink(destination), add = TRUE)
  testthat::local_mocked_bindings(
    curl_options = function() c(protocols = 1L, redir_protocols = 2L),
    new_handle = function(...) {
      seen <<- list(...)
      if (any(c("protocols_str", "redir_protocols_str") %in% names(seen))) {
        stop("Unknown options: protocols_str, redir_protocols_str")
      }
      seen
    },
    curl_fetch_disk = function(url, path, handle) {
      file.copy(source, path, overwrite = TRUE)
      list(status_code = 200L, type = "application/octet-stream", url = url)
    },
    .package = "curl"
  )
  result <- readAOFM:::download_aofm_workbook(
    "https://www.aofm.gov.au/sites/default/files/2025-06-20/treasury%20bonds%20-%20issuance.xlsx",
    destination,
    timeout = 7,
    retries = 0L,
    max_bytes = 1024^2,
    official_only = TRUE
  )
  expect_identical(result, destination)
  expect_identical(readBin(result, "raw", file.info(result)$size),
                   readBin(source, "raw", file.info(source)$size))
  expect_false(seen$followlocation)
  expect_identical(seen$http_version, 2L)
  expect_equal(seen$connecttimeout, 7)
  expect_equal(seen$timeout, 7)
  expect_equal(seen$maxfilesize_large, 1024^2)
  expect_identical(seen$protocols, 2L)
  expect_identical(seen$redir_protocols, 2L)
})

test_that("legacy HTTPS protocol masks reject HTTP and file URLs", {
  options <- readAOFM:::aofm_https_protocol_options(c("protocols", "redir_protocols"))
  handle <- do.call(curl::new_handle, c(list(timeout = 1), options))
  expect_error(curl::curl_fetch_memory("http://127.0.0.1:1", handle),
               "[Pp]rotocol|[Uu]nsupported")
  expect_error(curl::curl_fetch_memory("file:///not-a-workbook.xlsx", handle),
               "[Pp]rotocol|[Uu]nsupported")
})

test_that("workbook downloads retain HTTP and content-type errors", {
  fixture <- tempfile(fileext = ".xlsx")

  testthat::local_mocked_bindings(
    curl_fetch_disk = function(url, path, handle) {
      writeBin(charToRaw("not-found"), path)
      list(status_code = 404L, type = "text/html")
    },
    .package = "curl"
  )

  expect_error(
    readAOFM:::download_aofm_workbook("https://www.aofm.gov.au/media/404", fixture),
    "HTTP 404"
  )

  testthat::local_mocked_bindings(
    curl_fetch_disk = function(url, path, handle) {
      writeBin(charToRaw("error page"), path)
      list(status_code = 200L, type = "text/html")
    },
    .package = "curl"
  )

  expect_error(
    readAOFM:::download_aofm_workbook("https://www.aofm.gov.au/media/error", fixture),
    "instead of a workbook"
  )
})

test_that("workbook downloads retain transport and signature errors", {
  fixture <- tempfile(fileext = ".xlsx")

  testthat::local_mocked_bindings(
    curl_fetch_disk = function(url, path, handle) {
      stop("simulated connection failure")
    },
    .package = "curl"
  )

  expect_error(
    readAOFM:::download_aofm_workbook("https://www.aofm.gov.au/media/failure", fixture),
    "Failed to download workbook.*simulated connection failure"
  )

  testthat::local_mocked_bindings(
    curl_fetch_disk = function(url, path, handle) {
      writeBin(charToRaw("plain text"), path)
      list(status_code = 200L, type = "application/octet-stream")
    },
    .package = "curl"
  )

  expect_error(
    readAOFM:::download_aofm_workbook("https://www.aofm.gov.au/media/plain", fixture),
    "did not look like a valid .xlsx workbook"
  )
})
