aofm_normalize_search_text <- function(x) {
  x <- tolower(x)
  x <- gsub("[^a-z0-9]+", " ", x)
  x <- gsub("\\s+", " ", x)
  trimws(x)
}

aofm_search_aliases <- function(security, type, id) {
  security_aliases <- c(
    tb = "treasury bond treasury bonds australian government bond australian government bonds",
    tib = "treasury indexed bond treasury indexed bonds indexed bond indexed bonds inflation inflation linked inflation linked bond inflation linked bonds index linked cpi linked linker linkers",
    tn = "treasury note treasury notes note notes short term debt short dated",
    slf = "securities lending facility security lending facility stock lending lending facility",
    summary = "summary executive summary overview",
    aggregate = "aggregate aggregated combined total",
    ownership = "ownership holders holdings investors investor base",
    retail = "retail retail investors retail bonds",
    termpremium = "term premium termpremium premium yield premium"
  )

  type_aliases <- c(
    dealt = "dealt position positions stock on issue outstanding",
    settlement = "settlement settled settlements",
    issuance = "issuance issue issues auction auctions tender tenders primary market sale sales",
    syndication = "syndication syndicated syndications syndicate",
    buyback = "buyback buy back repurchase repurchases",
    turnover = "turnover trading secondary market liquidity",
    public = "public domestic public sector",
    nonresident = "nonresident non resident foreign overseas offshore international"
  )

  id_aliases <- c(
    ownership_nonresident = "foreign ownership offshore ownership non resident ownership",
    ownership_public = "public ownership domestic ownership",
    aggregate_position_dealt = "aggregate positions dealt aggregate outstanding",
    aggregate_position_settlement = "aggregate positions settlement aggregate settled",
    summary = "executive summary"
  )

  paste(
    c(
      unname(security_aliases[security]),
      unname(type_aliases[type]),
      unname(id_aliases[id])
    ),
    collapse = " "
  )
}

aofm_search_catalog <- function() {
  catalog <- aofm_index[aofm_index$fn != "no function exists", , drop = FALSE]
  alias_text <- vapply(
    seq_len(nrow(catalog)),
    function(i) aofm_search_aliases(catalog$p.security[[i]], catalog$p.type[[i]], catalog$id[[i]]),
    character(1)
  )

  data.frame(
    security = catalog$p.security,
    type = catalog$p.type,
    id = catalog$id,
    reader = catalog$fn,
    read_call = vapply(
      seq_len(nrow(catalog)),
      function(i) {
        if (is.na(catalog$p.type[[i]])) {
          sprintf('read_aofm("%s")', catalog$p.security[[i]])
        } else {
          sprintf('read_aofm("%s", "%s")', catalog$p.security[[i]], catalog$p.type[[i]])
        }
      },
      character(1)
    ),
    search_text = paste(
      gsub("[_.]", " ", catalog$id),
      ifelse(is.na(catalog$p.security), "", catalog$p.security),
      ifelse(is.na(catalog$p.type), "", catalog$p.type),
      alias_text
    ),
    stringsAsFactors = FALSE
  )
}

aofm_search_score <- function(query, tokens, text, security, type, id) {
  score <- 0L

  if (query == aofm_normalize_search_text(id)) {
    score <- score + 200L
  }
  if (!is.na(type) && query == aofm_normalize_search_text(type)) {
    score <- score + 120L
  }
  if (!is.na(security) && query == aofm_normalize_search_text(security)) {
    score <- score + 100L
  }
  if (grepl(query, text, fixed = TRUE)) {
    score <- score + 80L
  }

  score + length(tokens) * 10L
}

#' Search the supported AOFM table catalogue
#'
#' `search_aofm()` searches the package's local catalogue without downloading
#' a workbook or contacting the AOFM website. Matching is case-insensitive and
#' accepts stable IDs, security/type values, and useful aliases such as
#' "treasury bond", "inflation", "foreign ownership", "turnover", and
#' "term premium". Use the returned `read_call` column to pass a selected table
#' to [read_aofm()].
#'
#' With `read = TRUE`, each match is immediately passed to [read_aofm()] and
#' therefore requires an HTTPS request for every selected workbook. The
#' package does not require credentials; the reader stages workbooks in
#' temporary files and does not use the managed cache unless the caller chooses
#' [download_aofm_file()] explicitly.
#'
#' @param query One non-empty search string. Phrases are preferred when they
#'   match; otherwise all query tokens or any matching token are used.
#' @param read Logical scalar (default `FALSE`). If `FALSE`, return catalogue rows.
#'   If `TRUE`, read each matching table and return the parsed result.
#' @param csv Logical scalar (default `FALSE`). When `read = TRUE` and `csv = TRUE`, pass the
#'   option to [read_aofm()] so parsed CSVs are written below `output/` in the
#'   current working directory. It has no effect when `read = FALSE`.
#' @param timeout Positive finite numeric scalar giving the per-attempt timeout
#'   used for `read = TRUE` (default
#'   `getOption("readAOFM.search_timeout", 3)` seconds; maximum 300 seconds).
#'   Search itself is offline, but the value is still validated on every call.
#' @param retries Non-negative integer scalar giving retries after the first
#'   attempt when `read = TRUE` (default
#'   `getOption("readAOFM.search_retries", 0L)`; maximum 5).
#' @param max_bytes Positive finite numeric scalar giving the maximum accepted
#'   workbook size when `read = TRUE` (default
#'   `getOption("readAOFM.max_bytes", 100 * 1024^2)`; maximum 1 GiB).
#' @returns When `read = FALSE`, a base data frame with columns `security`,
#'   `type`, `id`, `reader`, and `read_call`; rows are reset to consecutive
#'   integers and unsupported/raw-only catalogue rows are not included. A
#'   query with no match returns a zero-row data frame. When `read = TRUE`, a
#'   single parsed table is returned for one match, or a named list keyed by
#'   table ID for multiple matches. A no-match `read = TRUE` call throws an
#'   error before any download.
#'
#' @details
#' Invalid queries (non-character, length other than one, `NA`, or blank after
#' trimming), invalid logical flags, or invalid transport bounds throw an
#' error. Search results are deterministic for a fixed local catalogue and do
#' not create files. With `read = TRUE`, `csv = TRUE` writes parsed results
#' beneath `output/` in the current working directory; parsed values and
#' available source files depend on the live AOFM workbooks.
#'
#' @seealso [read_aofm()] for downloading and parsing, and
#'   [download_aofm_xlsx()] for saving raw workbooks.
#' @examples
#' # All of these searches are offline.
#' search_aofm("tb issuance")
#' search_aofm("issuance")
#' search_aofm("treasury bond")
#' search_aofm("inflation")
#'
#' # Reading a match is opt-in and network-dependent; keep it interactive.
#' if (interactive()) {
#'   search_aofm("tb issuance", read = TRUE)
#' }
#' @export
search_aofm <- function(
    query,
    read = FALSE,
    csv = FALSE,
    timeout = getOption("readAOFM.search_timeout", 3),
    retries = getOption("readAOFM.search_retries", 0L),
    max_bytes = getOption("readAOFM.max_bytes", 100 * 1024^2)) {
  if (!is.character(query) || length(query) != 1 || is.na(query) || !nzchar(trimws(query))) {
    stop("`query` must be a single non-empty string.", call. = FALSE)
  }
  if (!is.logical(read) || length(read) != 1L || is.na(read)) {
    stop("`read` must be one non-missing logical value.", call. = FALSE)
  }
  if (!is.logical(csv) || length(csv) != 1L || is.na(csv)) {
    stop("`csv` must be one non-missing logical value.", call. = FALSE)
  }
  aofm_validate_transport_bounds(timeout, retries, max_bytes)

  catalog <- aofm_search_catalog()
  normalized_query <- aofm_normalize_search_text(query)
  tokens <- unique(strsplit(normalized_query, "\\s+")[[1]])
  tokens <- tokens[nzchar(tokens)]
  catalog$search_text <- aofm_normalize_search_text(catalog$search_text)

  token_hits <- lapply(
    catalog$search_text,
    function(text) tokens[vapply(tokens, grepl, logical(1), x = text, fixed = TRUE)]
  )
  phrase_match <- vapply(
    catalog$search_text,
    function(text) grepl(normalized_query, text, fixed = TRUE),
    logical(1)
  )
  full_match <- vapply(token_hits, function(hits) length(hits) == length(tokens), logical(1))
  any_match <- vapply(token_hits, function(hits) length(hits) > 0, logical(1))

  keep <- if (any(phrase_match)) {
    phrase_match
  } else if (any(full_match)) {
    full_match
  } else {
    any_match
  }

  scores <- vapply(
    seq_len(nrow(catalog)),
    function(i) aofm_search_score(
      query = normalized_query,
      tokens = token_hits[[i]],
      text = catalog$search_text[[i]],
      security = catalog$security[[i]],
      type = catalog$type[[i]],
      id = catalog$id[[i]]
    ),
    integer(1)
  )

  matches <- catalog[keep, c("security", "type", "id", "reader", "read_call"), drop = FALSE]
  matches$score <- as.integer(scores[keep])
  matches <- matches[order(-matches$score, matches$security, matches$type, matches$id), , drop = FALSE]
  matches$score <- NULL
  rownames(matches) <- NULL

  if (!isTRUE(read)) {
    return(matches)
  }

  if (nrow(matches) == 0) {
    stop(sprintf("No supported AOFM table matched query %s.", dQuote(query)), call. = FALSE)
  }

  results <- lapply(seq_len(nrow(matches)), function(i) {
    type <- matches$type[[i]]
    if (is.na(type)) type <- NULL
    read_aofm(
      matches$security[[i]],
      type,
      csv = csv,
      timeout = timeout,
      retries = retries,
      max_bytes = max_bytes
    )
  })
  names(results) <- matches$id

  if (length(results) == 1) {
    return(results[[1]])
  }

  results
}
