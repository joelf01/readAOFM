#' Read the AOFM end-of-financial-year executive summary
#'
#' `read_eofy()` downloads the `summary` workbook from the AOFM Data Hub and
#' tidies its first worksheet into long form. The source is fetched over HTTPS
#' without credentials and staged in a temporary file; the package
#' does not use the managed cache unless [download_aofm_file()] is called
#' explicitly. Transport is bounded by the public `timeout`, `retries`, and
#' `max_bytes` arguments. A changed workbook layout or missing required columns
#' causes an error.
#'
#' @param aofm_table Must be the catalogue ID `summary`. It is normally selected
#'   through [read_aofm()] rather than called directly.
#' @param csv Logical scalar (default `FALSE`). If `TRUE`, also write the parsed data to
#'   `output/eofy_executive_summary.csv` beneath the current working directory.
#' @param timeout Positive finite numeric scalar giving the per-attempt workbook
#'   transport timeout in seconds (default `getOption("readAOFM.timeout", 30)`;
#'   maximum 300 seconds).
#' @param retries Non-negative integer scalar giving the number of retries after
#'   the first workbook transport attempt (default
#'   `getOption("readAOFM.retries", 1L)`; maximum 5).
#' @param max_bytes Positive finite numeric scalar giving the maximum accepted
#'   workbook size in bytes (default
#'   `getOption("readAOFM.max_bytes", 100 * 1024^2)`; maximum 1 GiB).
#' @returns A tibble/data frame in long form. It contains the source identifier
#'   columns plus `date` (a `Date`) and `value`; duplicate and missing
#'   observations are removed by the parser. Exact identifier columns follow
#'   the current AOFM workbook.
#' @seealso [read_aofm()] for the preferred interface and [search_aofm()] for
#'   offline catalogue discovery.
#' @examples
#' search_aofm("executive summary")
#'
#' # A live workbook read is opt-in so package examples remain offline.
#' if (interactive()) {
#'   read_eofy("summary")
#' }
#'
#' @export

read_eofy <- function(aofm_table
                      , csv = FALSE
                      , timeout = getOption("readAOFM.timeout", 30)
                      , retries = getOption("readAOFM.retries", 1L)
                      , max_bytes = getOption("readAOFM.max_bytes", 100 * 1024^2)
) {
  tmp0 <- download_aofm_table_workbook(aofm_table, timeout, retries, max_bytes)
  aofm_parse_eofy_workbook(tmp0, csv = csv)
}








#' Read an AOFM end-of-month positions workbook
#'
#' `read_eom()` downloads and tidies one of the eight end-of-month position
#' workbooks. It returns one named component for each non-Notes data worksheet.
#' Current Treasury Bond and Treasury Indexed Bond workbooks provide
#' `FaceValue`, `MarketValue`, `Delta`, `Duration`, and `Tenor` components;
#' AOFM may add or remove worksheets, so callers should inspect the names of
#' the returned list. For Treasury Bond, Treasury Indexed Bond, and Treasury
#' Note tables, each component includes a `Series` identifier when repeated
#' security identities occur. Dates are normalised to `Date` and measures to
#' numeric values.
#'
#' @param aofm_table One of `aggregate_position_dealt`,
#'   `aggregate_position_settlement`, `tb_position_dealt`,
#'   `tb_position_settlement`, `tib_position_dealt`,
#'   `tib_position_settlement`, `tn_position_dealt`, or
#'   `tn_position_settlement`. It is normally selected through [read_aofm()].
#' @param csv Logical scalar (default `FALSE`). If `TRUE`, write one CSV per returned component
#'   to `output/` beneath the current working directory.
#' @param timeout Positive finite numeric scalar giving the per-attempt workbook
#'   transport timeout in seconds (default `getOption("readAOFM.timeout", 30)`;
#'   maximum 300 seconds).
#' @param retries Non-negative integer scalar giving the number of retries after
#'   the first workbook transport attempt (default
#'   `getOption("readAOFM.retries", 1L)`; maximum 5).
#' @param max_bytes Positive finite numeric scalar giving the maximum accepted
#'   workbook size in bytes (default
#'   `getOption("readAOFM.max_bytes", 100 * 1024^2)`; maximum 1 GiB).
#' @returns A named list with one tibble/data-frame component per non-Notes
#'   worksheet. Each component preserves workbook identity fields, adds `date`
#'   as a `Date`, and contains numeric `value` observations in long form.
#'   Treasury Bond, Treasury Indexed Bond, and Treasury Note components include
#'   a `Series` identifier where applicable. Component names are the stable table
#'   ID followed by the worksheet name, for example
#'   `tb_position_dealt_FaceValue`.
#' @details The workbook is fetched over HTTPS without credentials and staged
#'   in a temporary file. Missing worksheets, rows, columns, or an incompatible
#'   AOFM layout cause an error; no managed cache is used. Transport has the
#'   public bounded timeout and size safeguards described above. Set `csv = TRUE`
#'   to write one CSV per component beneath `output/` in the current working
#'   directory.
#' @seealso [read_aofm()] for the preferred interface and [search_aofm()] for
#'   offline catalogue discovery.
#' @examples
#' search_aofm("tb dealt")
#'
#' # This is a complete official snapshot with five long data worksheets;
#' # run the offline parse interactively because it can take several seconds.
#' fixture <- system.file("extdata", "tb_position_dealt.xlsx", package = "readAOFM")
#' if (interactive() && requireNamespace("testthat", quietly = TRUE) && nzchar(fixture)) {
#'   result <- suppressMessages(testthat::with_mocked_bindings(
#'     read_eom("tb_position_dealt"),
#'     download_aofm_table_workbook = function(...) fixture,
#'     .package = "readAOFM"
#'   ))
#'   names(result)
#' }
#'
#' @export

read_eom <- function(aofm_table
                     , csv = FALSE
                     , timeout = getOption("readAOFM.timeout", 30)
                     , retries = getOption("readAOFM.retries", 1L)
                     , max_bytes = getOption("readAOFM.max_bytes", 100 * 1024^2)
) {
  tmp0 <- download_aofm_table_workbook(aofm_table, timeout, retries, max_bytes)
  aofm_parse_eom_workbook(tmp0, aofm_table = aofm_table, csv = csv)
}














#' Read a transactional AOFM workbook
#'
#' `read_transactional()` handles tender, buyback, retail-facility, and
#' securities-lending workbooks. It downloads the selected workbook over HTTPS
#' without credentials, stages it in a temporary file, and pivots numeric
#' measures into long form. The package does not use the managed cache unless
#' [download_aofm_file()] is called explicitly and applies the public bounded
#' timeout and size safeguards described in [read_aofm()].
#'
#' @param aofm_table One of `tb_issuance`, `tb_buyback`, `tib_issuance`,
#'   `tib_buyback`, `tn_issuance`, `retail`, or `slf`. It is normally selected
#'   through [read_aofm()].
#' @param csv Logical scalar (default `FALSE`). If `TRUE`, write the parsed result to
#'   `output/<aofm_table>.csv` beneath the current working directory.
#' @param timeout Positive finite numeric scalar giving the per-attempt workbook
#'   transport timeout in seconds (default `getOption("readAOFM.timeout", 30)`;
#'   maximum 300 seconds).
#' @param retries Non-negative integer scalar giving the number of retries after
#'   the first workbook transport attempt (default
#'   `getOption("readAOFM.retries", 1L)`; maximum 5).
#' @param max_bytes Positive finite numeric scalar giving the maximum accepted
#'   workbook size in bytes (default
#'   `getOption("readAOFM.max_bytes", 100 * 1024^2)`; maximum 1 GiB).
#' @returns A tibble/data frame in long form. Workbook identifier columns are
#'   retained; numeric measures are represented by `name` and `value`. Known
#'   date fields such as `date_held`, `date_settled`, `maturity`, `settle_date`,
#'   `start_date`, `end_date`, and `security_maturity_date` are normalised to
#'   `Date` where present. Exact measures and identifier columns follow the
#'   current source workbook.
#' @details Empty files, missing required columns, non-workbook responses, and
#'   changed AOFM layouts cause an error. Missing measure values are omitted by
#'   the parser.
#' @seealso [read_aofm()] for the preferred interface and [search_aofm()] for
#'   offline catalogue discovery.
#' @examples
#' search_aofm("tb issuance")
#'
#' fixture <- system.file("extdata", "tb_issuance.xlsx", package = "readAOFM")
#' if (requireNamespace("testthat", quietly = TRUE) && nzchar(fixture)) {
#'   result <- suppressMessages(testthat::with_mocked_bindings(
#'     read_transactional("tb_issuance"),
#'     download_aofm_table_workbook = function(...) fixture,
#'     .package = "readAOFM"
#'   ))
#'   head(result[c("date_held", "name", "value")])
#' }
#'
#' @export

read_transactional <- function(aofm_table
                               , csv = FALSE
                               , timeout = getOption("readAOFM.timeout", 30)
                               , retries = getOption("readAOFM.retries", 1L)
                               , max_bytes = getOption("readAOFM.max_bytes", 100 * 1024^2)
) {
  tmp0 <- download_aofm_table_workbook(aofm_table, timeout, retries, max_bytes)
  aofm_parse_transactional_workbook(tmp0, aofm_table = aofm_table, csv = csv)
}









#' Read AOFM syndication details
#'
#' `read_syndication()` reads the syndicated-issue workbooks for Treasury Bonds
#' or Treasury Indexed Bonds. It downloads over HTTPS without credentials,
#' stages the workbook in a temporary file, and combines the source sheets into
#' a single long-form result. No managed cache is used; the public timeout,
#' retry, and workbook-size safeguards are applied.
#'
#' @param aofm_table Either `tb_syndication` or `tib_syndication`. It is
#'   normally selected through [read_aofm()].
#' @param csv Logical scalar (default `FALSE`). If `TRUE`, write the parsed result to
#'   `output/<aofm_table>.csv` beneath the current working directory.
#' @param timeout Positive finite numeric scalar giving the per-attempt workbook
#'   transport timeout in seconds (default `getOption("readAOFM.timeout", 30)`;
#'   maximum 300 seconds).
#' @param retries Non-negative integer scalar giving the number of retries after
#'   the first workbook transport attempt (default
#'   `getOption("readAOFM.retries", 1L)`; maximum 5).
#' @param max_bytes Positive finite numeric scalar giving the maximum accepted
#'   workbook size in bytes (default
#'   `getOption("readAOFM.max_bytes", 100 * 1024^2)`; maximum 1 GiB).
#' @returns A tibble/data frame with source identifier columns, `pricing_date`
#'   and `settlement_date` as `Date` values where present, a `type` identifying
#'   `new_bond` or `tap`, and long-form `name` and numeric `value` columns. Exact
#'   source fields follow the current AOFM workbook.
#' @details Notes worksheets are excluded. Empty files, missing required date
#'   fields or value columns, and changed source layouts cause an error.
#' @seealso [read_aofm()] for the preferred interface and [search_aofm()] for
#'   offline catalogue discovery.
#' @examples
#' search_aofm("tb syndication")
#'
#' fixture <- system.file("extdata", "tb_syndication.xlsx", package = "readAOFM")
#' if (requireNamespace("testthat", quietly = TRUE) && nzchar(fixture)) {
#'   result <- suppressMessages(testthat::with_mocked_bindings(
#'     read_syndication("tb_syndication"),
#'     download_aofm_table_workbook = function(...) fixture,
#'     .package = "readAOFM"
#'   ))
#'   head(result[c("pricing_date", "type", "name", "value")])
#' }
#'
#' @export


read_syndication <- function(aofm_table
                             , csv = FALSE
                             , timeout = getOption("readAOFM.timeout", 30)
                             , retries = getOption("readAOFM.retries", 1L)
                             , max_bytes = getOption("readAOFM.max_bytes", 100 * 1024^2)
) {
  tmp0 <- download_aofm_table_workbook(aofm_table, timeout, retries, max_bytes)
  aofm_parse_syndication_workbook(tmp0, aofm_table = aofm_table, csv = csv)
}









#' Read AOFM secondary-market turnover
#'
#' `read_secondary()` downloads and parses both official turnover sources for
#' Treasury Bonds or Treasury Indexed Bonds. It retains the historical
#' `tenor` and `investor_type` groups, adds the redesigned current `security`,
#' `region`, and `counterparty` groups, and returns one continuous result.
#' Workbooks are fetched over HTTPS without credentials and staged in temporary
#' files; the package does not use the managed cache unless
#' [download_aofm_file()] is called explicitly.
#'
#' @param aofm_table Either `tb_turnover` or `tib_turnover`. It is normally
#'   selected through [read_aofm()].
#' @param csv Logical scalar (default `FALSE`). If `TRUE`, write the parsed result to
#'   `output/<aofm_table>.csv` beneath the current working directory.
#' @param timeout Positive finite numeric scalar giving the per-attempt workbook
#'   transport timeout in seconds (default `getOption("readAOFM.timeout", 30)`;
#'   maximum 300 seconds).
#' @param retries Non-negative integer scalar giving the number of retries after
#'   the first workbook transport attempt (default
#'   `getOption("readAOFM.retries", 1L)`; maximum 5).
#' @param max_bytes Positive finite numeric scalar giving the maximum accepted
#'   workbook size in bytes (default
#'   `getOption("readAOFM.max_bytes", 100 * 1024^2)`; maximum 1 GiB).
#' @returns A tibble/data frame in long form with `period` as a `Date`, `group`
#'   in `tenor`, `investor_type`, `security`, `region`, or `counterparty`, and
#'   `name`/`value` columns for numeric turnover measures. Rows are ordered by
#'   the natural key `period`, `group`, and `name`. Attribute `aofm_sources` is a
#'   two-record named list with `historical` and `current` records. Each record
#'   includes `schema_version`, `table_id`, `role`, `source_url`, URL-decoded
#'   `source_filename`, `raw_sha256`, `raw_bytes`, and UTC `retrieved_at`.
#' @details The historical workbooks cover July 2016 through December 2025.
#'   Their `By Tenor` observations are monthly and `By Category` observations
#'   are quarterly. Redesigned current workbooks begin with monthly January
#'   2026 observations. AOFM publishes updates quarterly with a two-month lag.
#'   The sources are joined on `period`, `group`, and `name`; current-source
#'   rows take precedence on an overlap and duplicate natural keys cause an
#'   error. Missing sheets, periods, or changed workbook layouts also error.
#' @seealso [read_aofm()] for the preferred interface and [search_aofm()] for
#'   offline catalogue discovery.
#' @examples
#' search_aofm("secondary market turnover")
#'
#' if (interactive()) {
#'   read_secondary("tb_turnover")
#' }
#'
#' @export

read_secondary <- function(aofm_table
                           , csv = FALSE
                           , timeout = getOption("readAOFM.timeout", 30)
                           , retries = getOption("readAOFM.retries", 1L)
                           , max_bytes = getOption("readAOFM.max_bytes", 100 * 1024^2)
) {
  tmp0 <- download_aofm_table_workbook(aofm_table, timeout, retries, max_bytes)
  current_source <- attr(tmp0, "aofm_source")
  if (is.null(current_source)) {
    row <- aofm_table_row(aofm_table)
    current_source <- aofm_workbook_source(
      tmp0,
      table_id = aofm_table,
      source_url = row$file.path[[1]],
      role = "current"
    )
  }
  current <- aofm_parse_secondary_workbook(
    tmp0,
    aofm_table = aofm_table,
    csv = FALSE
  )
  history_urls <- aofm_turnover_history_urls()
  history_url <- unname(history_urls[aofm_table])
  if (!length(history_url) || is.na(history_url)) {
    result <- current
  } else {
    history_path <- tempfile(fileext = ".xlsx")
    download_aofm_workbook(
      history_url,
      history_path,
      timeout = timeout,
      retries = retries,
      max_bytes = max_bytes,
      official_only = TRUE
    )
    history_source <- aofm_workbook_source(
      history_path,
      table_id = aofm_table,
      source_url = history_url,
      role = "historical"
    )
    history <- aofm_parse_secondary_workbook(
      history_path,
      aofm_table = aofm_table,
      csv = FALSE
    )
    result <- aofm_stitch_observations(
      historical = history,
      current = current,
      identity = c("period", "group", "name"),
      order_by = c("period", "group", "name")
    )
    attr(result, "aofm_sources") <- list(
      historical = history_source,
      current = current_source
    )
  }
  aofm_write_csv_if_requested(
    result,
    csv,
    file.path("output", paste0(aofm_table, ".csv"))
  )
  result
}







#' Read AOFM term-premium estimates
#'
#' `read_premium()` downloads the `termpremium` workbook and combines its two
#' source worksheets into a date-sorted long-form result. The source is fetched
#' over HTTPS without credentials and staged in a temporary file; no managed
#' cache is used. The public timeout, retry, and workbook-size safeguards are
#' applied.
#'
#' @param aofm_table Must be the catalogue ID `termpremium`. It is normally
#'   selected through [read_aofm()].
#' @param csv Logical scalar (default `FALSE`). If `TRUE`, write the parsed result to
#'   `output/termpremium.csv` beneath the current working directory.
#' @param timeout Positive finite numeric scalar giving the per-attempt workbook
#'   transport timeout in seconds (default `getOption("readAOFM.timeout", 30)`;
#'   maximum 300 seconds).
#' @param retries Non-negative integer scalar giving the number of retries after
#'   the first workbook transport attempt (default
#'   `getOption("readAOFM.retries", 1L)`; maximum 5).
#' @param max_bytes Positive finite numeric scalar giving the maximum accepted
#'   workbook size in bytes (default
#'   `getOption("readAOFM.max_bytes", 100 * 1024^2)`; maximum 1 GiB).
#' @returns A tibble/data frame sorted by `date`, with `date` as a `Date`,
#'   `type` identifying the source worksheet, and long-form `name` and `value`
#'   columns. Exact measures follow the current AOFM workbook.
#' @details Missing date fields, empty workbooks, and changed worksheet layouts
#'   cause an error.
#' @seealso [read_aofm()] for the preferred interface and [search_aofm()] for
#'   offline catalogue discovery.
#' @examples
#' search_aofm("term premium")
#'
#' if (interactive()) {
#'   read_premium("termpremium")
#' }
#'
#' @export

read_premium <- function(aofm_table
                         , csv = FALSE
                         , timeout = getOption("readAOFM.timeout", 30)
                         , retries = getOption("readAOFM.retries", 1L)
                         , max_bytes = getOption("readAOFM.max_bytes", 100 * 1024^2)
) {
  tmp0 <- download_aofm_table_workbook(aofm_table, timeout, retries, max_bytes)
  aofm_parse_premium_workbook(tmp0, aofm_table = aofm_table, csv = csv)
}









#' Read AOFM ownership of Australian Government Securities
#'
#' `read_ownership()` reads the public register or non-resident holdings
#' workbook and returns one long-form data frame per source worksheet. It
#' downloads over HTTPS without credentials and stages the workbook in a
#' temporary file; the package does not use the managed cache unless
#' [download_aofm_file()] is called explicitly. The public timeout, retry, and
#' workbook-size safeguards are applied.
#'
#' @param aofm_table Either `ownership_public` or `ownership_nonresident`. It is
#'   normally selected through [read_aofm()].
#' @param csv Logical scalar (default `FALSE`). If `TRUE`, write one CSV per returned worksheet
#'   beneath `output/` in the current working directory.
#' @param timeout Positive finite numeric scalar giving the per-attempt workbook
#'   transport timeout in seconds (default `getOption("readAOFM.timeout", 30)`;
#'   maximum 300 seconds).
#' @param retries Non-negative integer scalar giving the number of retries after
#'   the first workbook transport attempt (default
#'   `getOption("readAOFM.retries", 1L)`; maximum 5).
#' @param max_bytes Positive finite numeric scalar giving the maximum accepted
#'   workbook size in bytes (default
#'   `getOption("readAOFM.max_bytes", 100 * 1024^2)`; maximum 1 GiB).
#' @returns A named list of data frames. Public ownership returns the first two
#'   source worksheets; non-resident ownership returns source worksheets two
#'   through four. Each component preserves its source identity columns and
#'   contains `date` as a `Date` plus numeric `value` observations in long form.
#'   Component names combine the table ID and source worksheet name.
#' @details Missing sheets, rows, columns, or changed source layouts cause an
#'   error. The exact identity columns follow the current AOFM workbook.
#' @seealso [read_aofm()] for the preferred interface and [search_aofm()] for
#'   offline catalogue discovery.
#' @examples
#' search_aofm("foreign ownership")
#'
#' if (interactive()) {
#'   read_ownership("ownership_nonresident")
#' }
#'
#' @export
#

read_ownership <- function(aofm_table
                           , csv = FALSE
                           , timeout = getOption("readAOFM.timeout", 30)
                           , retries = getOption("readAOFM.retries", 1L)
                           , max_bytes = getOption("readAOFM.max_bytes", 100 * 1024^2)
) {
  tmp0 <- download_aofm_table_workbook(aofm_table, timeout, retries, max_bytes)
  aofm_parse_ownership_workbook(tmp0, aofm_table = aofm_table, csv = csv)
}
