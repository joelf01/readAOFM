#!/usr/bin/env Rscript

# Regenerate the package's catalogue objects from the tracked source map.
# Run from the package root with:
#   Rscript data-raw/generate_sysdata.R

source_path <- file.path("data-raw", "aofm_catalog_source.csv")
if (!file.exists(source_path)) {
  stop("Run this generator from the readAOFM package root.", call. = FALSE)
}

catalog <- utils::read.csv(
  source_path,
  stringsAsFactors = FALSE,
  check.names = FALSE,
  na.strings = c("", "NA"),
  colClasses = "character"
)

core_columns <- c(
  "p.security", "p.type", "id", "fn", "category", "title",
  "despription", "file.path", "file.save"
)
source_columns <- c(
  core_columns, "supported", "route_status", "route_note"
)
if (!identical(names(catalog), source_columns)) {
  stop(
    "The catalogue source map must have the documented columns in order.",
    call. = FALSE
  )
}

expected_ids <- c(
  "summary",
  "aggregate_position_dealt",
  "aggregate_position_settlement",
  "tb_position_dealt",
  "tb_position_settlement",
  "tib_position_dealt",
  "tib_position_settlement",
  "tn_position_dealt",
  "tn_position_settlement",
  "tb_issuance",
  "tb_issuance_conversion",
  "tb_syndication",
  "tb_buyback",
  "tib_issuance",
  "tib_syndication",
  "tib_buyback",
  "tn_issuance",
  "retail",
  "slf",
  "ownership_public",
  "ownership_nonresident",
  "tb_turnover",
  "tib_turnover",
  "termpremium",
  "indexation_factors",
  "rmbs_transactions",
  "rmbs_auctions",
  "interest_rate_swaps",
  "cross_currency_swaps",
  "portfolio_overview"
)
if (nrow(catalog) != length(expected_ids) || !identical(catalog$id, expected_ids)) {
  stop("The catalogue source map must preserve the 30-row ID order.", call. = FALSE)
}
if (anyDuplicated(catalog$id)) {
  stop("Catalogue IDs must be unique.", call. = FALSE)
}

expected_supported <- catalog$fn != "no function exists"
if (!identical(catalog$supported, ifelse(expected_supported, "TRUE", "FALSE"))) {
  stop("The supported column must agree with the parser function column.", call. = FALSE)
}
if (sum(expected_supported) != 23L || sum(!expected_supported) != 7L) {
  stop("The catalogue must contain 23 parser-supported and 7 raw-only rows.", call. = FALSE)
}

if (anyNA(catalog$file.path) || any(!grepl("^https://", catalog$file.path))) {
  stop("Every catalogue route must be an HTTPS URL.", call. = FALSE)
}
if (any(grepl("/media/", catalog$file.path, fixed = TRUE))) {
  stop("The generated catalogue cannot contain retired /media routes.", call. = FALSE)
}
if (any(!grepl(
  "^https://www\\.aofm\\.gov\\.au/sites/default/files/",
  catalog$file.path
))) {
  stop("Every catalogue route must be a direct AOFM Data Hub file route.", call. = FALSE)
}

url_extension <- tolower(sub(
  ".*\\.([[:alnum:]]+)(?:[?#].*)?$", "\\1", catalog$file.path,
  perl = TRUE
))
save_extension <- tolower(sub(".*\\.", "", catalog$file.save))
if (any(!nzchar(url_extension)) || any(url_extension != save_extension)) {
  stop("Each URL extension must match its file.save extension.", call. = FALSE)
}

raw_only <- !expected_supported
if (!identical(
  catalog$id[raw_only],
  c(
    "tb_issuance_conversion", "indexation_factors", "rmbs_transactions",
    "rmbs_auctions", "interest_rate_swaps", "cross_currency_swaps",
    "portfolio_overview"
  )
)) {
  stop("The raw-only catalogue IDs are not the documented seven rows.", call. = FALSE)
}
if (!identical(catalog$route_status[catalog$id == "portfolio_overview"], "historical_raw_only")) {
  stop("Portfolio Overview must be labelled historical raw-only.", call. = FALSE)
}
if (any(catalog$route_status[raw_only & catalog$id != "portfolio_overview"] != "current_direct")) {
  stop("The six non-Portfolio raw-only routes must be current direct routes.", call. = FALSE)
}

turnover <- catalog$id %in% c("tb_turnover", "tib_turnover")
turnover_terms <- c(
  "By Tenor", "monthly", "By Category", "quarterly", "December 2025",
  "Security", "Region", "Counterparty", "January 2026", "two-month lag",
  "period, group and name", "current precedence",
  "duplicate keys", "SHA-256"
)
if (any(!vapply(catalog$despription[turnover], function(text) {
  all(vapply(turnover_terms, grepl, logical(1), x = text, fixed = TRUE))
}, logical(1)))) {
  stop("Turnover descriptions must carry the full cadence and join contract.", call. = FALSE)
}

aofm_index <- catalog[core_columns]
aofm_index_nav <- data.frame(
  "Argument 1" = catalog$p.security,
  "Argument 2" = catalog$p.type,
  "AOFM Category" = catalog$category,
  "AOFM Title" = catalog$title,
  "AOFM Description" = catalog$despription,
  check.names = FALSE,
  stringsAsFactors = FALSE
)
if (!identical(names(aofm_index), core_columns)) {
  stop("Generated aofm_index has an unexpected schema.", call. = FALSE)
}
if (!identical(names(aofm_index_nav), c(
  "Argument 1", "Argument 2", "AOFM Category", "AOFM Title",
  "AOFM Description"
))) {
  stop("Generated aofm_index_nav has an unexpected schema.", call. = FALSE)
}

output_path <- Sys.getenv("READAOFM_SYSDATA", unset = file.path("R", "sysdata.rda"))
dir.create(dirname(output_path), recursive = TRUE, showWarnings = FALSE)
save(
  aofm_index,
  aofm_index_nav,
  file = output_path,
  version = 3,
  compress = "xz"
)
message(
  sprintf(
    "Wrote %s (%d catalogue rows; %d supported, %d raw-only; md5 %s).",
    output_path,
    nrow(aofm_index),
    sum(expected_supported),
    sum(raw_only),
    unname(tools::md5sum(output_path))
  )
)
