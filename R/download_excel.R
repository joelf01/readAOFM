#' Download raw AOFM Data Hub workbooks
#'
#' `download_aofm_xlsx()` resolves exact `security` and `type` values against
#' the package's local AOFM catalogue, then downloads the matching `.xls` or
#' `.xlsx` workbooks over HTTPS. Raw files are written beneath `data/` in the
#' current working directory. The function does not require credentials and
#' does not maintain a managed package cache. Use [read_aofm()] for the usual
#' download-and-parse workflow, [download_aofm_file()] when an explicit
#' content-addressed cache is wanted, and [search_aofm()] to discover valid
#' tables without a network request.
#'
#' The `timeout`, `retries`, and `max_bytes` arguments provide bounded live
#' transfers. They default to 30 seconds, one retry, and 100 MiB respectively
#' (through the corresponding `readAOFM.*` options).
#'
#' The catalogue contains 23 parser-supported rows and seven raw-only
#' (unsupported) rows without parsers. Their selector fields are not populated,
#' so raw-only rows cannot be selected individually;
#' an unfiltered `download_aofm_xlsx()` call includes all 30 catalogue
#' workbooks. They cannot be read by [read_aofm()] or [read_aofm_file()] because
#' no parser contract exists for them. A changed AOFM URL, non-workbook
#' response, or changed workbook layout causes an error from the downloader or
#' the subsequent parser.
#'
#' @param security Optional exact security family (default `NULL`). Supported values are
#'   `summary`, `aggregate`, `tb`, `tib`, `tn`, `slf`, `ownership`, `retail`,
#'   and `termpremium`.
#' @param type Optional exact table type (default `NULL`). Supported values are `dealt`,
#'   `settlement`, `issuance`, `syndication`, `buyback`, `turnover`, `public`,
#'   and `nonresident`. If either argument is omitted, every matching catalogue
#'   row is selected.
#' @param timeout Positive finite numeric scalar giving the per-attempt workbook
#'   transport timeout in seconds (default `getOption("readAOFM.timeout", 30)`;
#'   maximum 300 seconds).
#' @param retries Non-negative integer scalar giving the number of retries after
#'   the first workbook transport attempt (default
#'   `getOption("readAOFM.retries", 1L)`; maximum 5).
#' @param max_bytes Positive finite numeric scalar giving the maximum accepted
#'   workbook size in bytes (default
#'   `getOption("readAOFM.max_bytes", 100 * 1024^2)`; maximum 1 GiB).
#' @returns A character vector of matched table IDs, returned invisibly after
#'   the files have been downloaded. If no row matches, `NULL` is returned and
#'   an explanatory message is printed. The files themselves are written to
#'   `data/` and are not returned as R objects. The function creates `data/`
#'   before checking whether a selector matched, so a no-match call can create
#'   an empty directory.
#' @details Invalid selectors and transport bounds, HTTP/transport failures,
#'   non-workbook responses, oversized files, and incompatible source layouts
#'   throw errors. The function writes only to the caller's current-working
#'   directory `data/` path; it does not write to the package installation or
#'   user-level cache.
#' @examples
#' # Catalogue discovery is offline and does not create files.
#' search_aofm("tb issuance")[, c("id", "read_call")]
#'
#' # Downloading is opt-in in examples because it requires the live AOFM site.
#' if (interactive()) {
#'   download_in_temporary_directory <- function() {
#'     old <- getwd()
#'     on.exit(setwd(old), add = TRUE)
#'     setwd(tempdir())
#'     download_aofm_xlsx("tb", "issuance")
#'   }
#'   download_in_temporary_directory()
#' }
#'
#' @export


download_aofm_xlsx <- function(security = NULL ## options include; tb, tib, tn, slf, summary, aggregate, ownership, retail, term.premium
                               , type =  NULL ## options include;
                               , timeout = getOption("readAOFM.timeout", 30)
                               , retries = getOption("readAOFM.retries", 1L)
                               , max_bytes = getOption(
                                 "readAOFM.max_bytes",
                                 100 * 1024^2
                               )
) {

  # run find_file function to determine which file to download
  aofm_table <- find_file(security, type)

  # check if /data sub folder exists and create if not
  if (dir.exists("data") == F) {
    dir.create("data")
  }

  if (is.null(aofm_table)==T){
    print(aofm_table)

  } else {
    for (table_id in aofm_table){
      file.row <- aofm_table_row(table_id)
      file.name <- file.row %>%
        pull(file.save)

      download_aofm_workbook(
        file.row$file.path[[1]],
        file.path("data", file.name),
        timeout = timeout,
        retries = retries,
        max_bytes = max_bytes,
        official_only = TRUE
      )
    }
    print("The following files have been downloaded to: data")
    print(aofm_table)
  }
}
