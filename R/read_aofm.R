aofm_dispatch_read <- function(
    aofm_table,
    child_fn,
    csv = FALSE,
    timeout = getOption("readAOFM.timeout", 30),
    retries = getOption("readAOFM.retries", 1L),
    max_bytes = getOption("readAOFM.max_bytes", 100 * 1024^2)) {
  switch(
    child_fn,
    read_eofy = read_eofy(aofm_table, csv, timeout, retries, max_bytes),
    read_eom = read_eom(aofm_table, csv, timeout, retries, max_bytes),
    read_transactional =
      read_transactional(aofm_table, csv, timeout, retries, max_bytes),
    read_syndication =
      read_syndication(aofm_table, csv, timeout, retries, max_bytes),
    read_ownership =
      read_ownership(aofm_table, csv, timeout, retries, max_bytes),
    read_secondary =
      read_secondary(aofm_table, csv, timeout, retries, max_bytes),
    read_premium =
      read_premium(aofm_table, csv, timeout, retries, max_bytes),
    stop(sprintf("No reader exists for table id '%s'.", aofm_table), call. = FALSE)
  )
}

#' Read and tidy one or more AOFM Data Hub tables
#'
#' `read_aofm()` is the preferred high-level interface to readAOFM. It maps
#' the optional `security` and `type` filters to the package's supported AOFM
#' table catalogue, downloads each selected workbook over HTTPS, and dispatches
#' to the appropriate family reader. The package does not require credentials
#' and the reader stages each workbook in a temporary file rather than
#' maintaining a managed cache. Use `timeout`, `retries`, and `max_bytes` to
#' bound live transfers. For a caller-selected content-addressed cache, use
#' [download_aofm_file()] and then parse the retained workbook with
#' [read_aofm_file()].
#'
#' The transport controls default to 30 seconds per attempt, one retry, and
#' 100 MiB through `getOption("readAOFM.timeout")`,
#' `getOption("readAOFM.retries")`, and `getOption("readAOFM.max_bytes")`.
#' They must be finite scalar values with `0 < timeout <= 300`, integer
#' `0 <= retries <= 5`, and `0 < max_bytes <= 1 GiB`.
#'
#' Supported table IDs cover end-of-financial-year positions, end-of-month
#' positions, Treasury Bond, Treasury Indexed Bond and Treasury Note
#' transactions, syndications, buybacks, retail and securities-lending data,
#' public and non-resident ownership, secondary-market turnover, and term
#' premium estimates. The full catalogue also contains seven raw-only
#' (unsupported) rows without parsers; those rows are excluded here. Use
#' [aofm_catalog()] with `include_unsupported = TRUE` to inspect all 30 routes and
#' [download_aofm_xlsx()] for an unfiltered raw download of the full catalogue.
#'
#' @param security Optional exact security family (default `NULL`). Supported values are
#'   `summary`, `aggregate`, `tb`, `tib`, `tn`, `slf`, `ownership`, `retail`,
#'   and `termpremium`. If omitted, all supported families are considered.
#' @param type Optional exact table type (default `NULL`). Supported values are `dealt`,
#'   `settlement`, `issuance`, `syndication`, `buyback`, `turnover`, `public`,
#'   and `nonresident`. If omitted, all supported types for `security` are
#'   considered.
#' @param csv Logical scalar (default `FALSE`). If `TRUE`, pass the option to each family reader;
#'   parsed output is also written beneath `output/` in the current working
#'   directory. For a list result, one CSV is written per component.
#' @param timeout Positive finite numeric scalar giving the per-attempt workbook
#'   transport timeout in seconds (default `getOption("readAOFM.timeout", 30)`;
#'   maximum 300 seconds).
#' @param retries Non-negative integer scalar giving the number of retries after
#'   the first workbook transport attempt (default
#'   `getOption("readAOFM.retries", 1L)`; maximum 5).
#' @param max_bytes Positive finite numeric scalar giving the maximum accepted
#'   workbook size in bytes (default
#'   `getOption("readAOFM.max_bytes", 100 * 1024^2)`; maximum 1 GiB).
#' @returns If the filters identify one table, the corresponding reader result:
#'   usually a long-form tibble/data frame with identifier columns, `date` or
#'   `period`, `name`, and `value`, or a named list of such data frames for
#'   multi-sheet workbook families. If the filters identify multiple tables,
#'   returns a named list keyed by stable table ID. With no filters, the list
#'   has one element for each of the 23 parser-supported tables.
#'
#'   Transactional and syndication results preserve workbook identifier fields
#'   and pivot measures to `name`/`value`; parsed dates are `Date` objects where
#'   the source provides dates. Syndication `value` is numeric. End-of-month
#'   results contain one named component per non-Notes worksheet (the current
#'   Treasury Bond/Treasury Indexed Bond workbooks include `FaceValue`,
#'   `MarketValue`, `Delta`, `Duration`, and `Tenor`; source layouts may vary).
#'   For Treasury Bond, Treasury Indexed Bond, and Treasury Note end-of-month
#'   outputs, each component also carries a `Series` identifier for repeated
#'   security identities. Ownership readers return named lists of component data
#'   frames. Exact measure columns follow the current AOFM workbook and may
#'   change if AOFM changes its source layout.
#'   Turnover results join the historical and redesigned current workbooks on
#'   `period`, `group`, and `name`, and include an `aofm_sources` attribute with
#'   named `historical` and `current` records containing source URLs, roles,
#'   table IDs, filenames, byte counts, UTC retrieval times, and SHA-256 hashes.
#'   Historical turnover covers July 2016 through December 2025: `By Tenor`
#'   observations are monthly and `By Category` observations are quarterly.
#'   Redesigned `Security`, `Region`, and `Counterparty` sheets begin with
#'   monthly January 2026 observations. AOFM publishes updates quarterly with a
#'   two-month lag. Current rows take precedence for an overlapping natural key,
#'   and duplicate `period`/`group`/`name` identities are rejected.
#'
#' @details
#' A selection that matches no supported table throws an error. Transport
#' failures, non-workbook responses, empty files, missing sheets, missing
#' required columns, and incompatible upstream layouts also throw errors. The
#' `csv = TRUE` side effect writes parsed data under `output/` in the current
#' working directory. The AOFM source is external, so examples and tests should
#' use local fixtures or mocks when deterministic, offline execution is
#' required.
#'
#' @seealso [search_aofm()] for offline discovery, [download_aofm_xlsx()] for
#'   raw workbook downloads, and the family readers [read_eom()],
#'   [read_transactional()], [read_syndication()], [read_ownership()],
#'   [read_secondary()], [read_premium()], and [read_eofy()].
#' @examples
#' # Discovery is local and does not contact AOFM.
#' search_aofm("tb issuance")[, c("id", "reader", "read_call")]
#'
#' # Exercise the real transactional parser without a network request when the
#' # package's tb_issuance fixture is installed.
#' if (requireNamespace("testthat", quietly = TRUE)) {
#'   fixture <- system.file("extdata", "tb_issuance.xlsx", package = "readAOFM")
#'   if (nzchar(fixture)) {
#'     result <- suppressMessages(testthat::with_mocked_bindings(
#'       read_aofm("tb", "issuance"),
#'       download_aofm_table_workbook = function(...) fixture,
#'       .package = "readAOFM"
#'     ))
#'     c(rows = nrow(result), columns = ncol(result))
#'   }
#' }
#'
#' @export

read_aofm <- function(security = NULL
                      , type = NULL
                      , csv = FALSE
                      , timeout = getOption("readAOFM.timeout", 30)
                      , retries = getOption("readAOFM.retries", 1L)
                      , max_bytes = getOption(
                        "readAOFM.max_bytes",
                        100 * 1024^2
                      )
) {
  for (name in c("security", "type")) {
    value <- get(name)
    if (
      !is.null(value) &&
        (
          !is.character(value) ||
            length(value) != 1L ||
            is.na(value) ||
            !nzchar(trimws(value))
        )
    ) {
      stop(
        sprintf("`%s` must be NULL or one non-empty string.", name),
        call. = FALSE
      )
    }
  }
  if (!is.logical(csv) || length(csv) != 1L || is.na(csv)) {
    stop("`csv` must be one non-missing logical value.", call. = FALSE)
  }
  aofm_validate_transport_bounds(timeout, retries, max_bytes)

  matches <- aofm_index
  matches <- matches[matches$fn != "no function exists", , drop = FALSE]

  if (!is.null(security)) {
    matches <- matches[!is.na(matches$p.security) & matches$p.security == security, , drop = FALSE]
  }

  if (!is.null(type)) {
    matches <- matches[!is.na(matches$p.type) & matches$p.type == type, , drop = FALSE]
  }

  if (nrow(matches) == 0) {
    stop(
      sprintf(
        "No supported AOFM table matched security = %s and type = %s.",
        if (is.null(security)) "NULL" else dQuote(security),
        if (is.null(type)) "NULL" else dQuote(type)
      ),
      call. = FALSE
    )
  }

  if (nrow(matches) == 1) {
    return(aofm_dispatch_read(
      matches$id[[1]],
      matches$fn[[1]],
      csv = csv,
      timeout = timeout,
      retries = retries,
      max_bytes = max_bytes
    ))
  }

  results <- lapply(seq_len(nrow(matches)), function(i) {
    aofm_dispatch_read(
      matches$id[[i]],
      matches$fn[[i]],
      csv = csv,
      timeout = timeout,
      retries = retries,
      max_bytes = max_bytes
    )
  })
  names(results) <- matches$id

  results
}
