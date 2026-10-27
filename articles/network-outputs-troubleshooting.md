# Network, outputs, and troubleshooting

`readAOFM` separates local catalogue discovery from workbook I/O.
Readers fetch public AOFM Data Hub workbooks and can optionally write
parsed CSV files, while
[`search_aofm()`](https://joelf01.github.io/readAOFM/reference/search_aofm.md)
searches installed metadata. The examples below keep every write in an
isolated temporary directory and use a packaged workbook snapshot for
deterministic parsing. The package’s managed download API is explicit,
so ordinary reader calls do not create a persistent cache.

## Network and staging behavior

The reader path resolves a table from the local catalogue, requests its
AOFM workbook over HTTPS, validates that the response looks like an
Excel workbook, and stages the file in a temporary location for parsing.
Public workbooks are available without package credentials, and each
live read retrieves the current source. Transport failures, HTTP errors,
empty files, non-workbook responses, and changed source layouts are
reported with table context.

Use the offline search before a live call:

``` r

readAOFM::search_aofm("tb issuance")[, c("id", "read_call")]
#>            id                   read_call
#> 1 tb_issuance read_aofm("tb", "issuance")
```

## CSV output is opt-in

`csv = TRUE` preserves the parsed return value and asks the family
reader to write a CSV beneath `output/`. The following example uses the
real public
[`read_aofm()`](https://joelf01.github.io/readAOFM/reference/read_aofm.md)
and parser, but mocks only the internal downloader so that the result is
repeatable and no network request is made.

``` r

csv_probe <- with_temp_working_directory({
  parsed <- testthat::with_mocked_bindings(
    readAOFM::read_aofm("tb", "issuance", csv = TRUE),
    download_aofm_table_workbook = function(aofm_table, ...) {
      stopifnot(identical(aofm_table, "tb_issuance"))
      tb_issuance_fixture
    },
    .package = "readAOFM"
  )

  output_file <- file.path("output", "tb_issuance.csv")
  stopifnot(file.exists(output_file))

  list(
    parsed = parsed,
    files = list.files(".", recursive = TRUE, all.files = FALSE),
    csv = data.frame(
      path = output_file,
      bytes = unname(file.info(output_file)$size),
      stringsAsFactors = FALSE
    )
  )
})

csv_probe$files
#> [1] "output/tb_issuance.csv"
csv_probe$csv
#>                     path   bytes
#> 1 output/tb_issuance.csv 2064015
utils::head(csv_probe$parsed[c("date_held", "name", "value")], 3)
#> # A tibble: 3 × 3
#>   date_held  name                value
#>   <date>     <chr>               <dbl>
#> 1 1982-08-05 coupon                 16
#> 2 1982-08-05 amount_offered  200000000
#> 3 1982-08-05 amount_allotted 200000000
```

Leaving `csv = FALSE` (the default) does not create an `output/`
directory. The raw helper
[`download_aofm_xlsx()`](https://joelf01.github.io/readAOFM/reference/download_aofm_xlsx.md)
has different behavior: it saves source workbooks beneath `data/` and is
intended for an explicitly writable project directory. Neither output
path is a package cache. The public transport bounds are `timeout` (30
seconds per attempt by default), `retries` (one retry), and `max_bytes`
(100 MiB); pass them explicitly when a script needs tighter limits.

## Managed downloads and offline parsing

[`download_aofm_file()`](https://joelf01.github.io/readAOFM/reference/download_aofm_file.md)
is the opt-in workflow for retaining a verified current workbook. It
stores a SHA-256-named `.xls`/`.xlsx` file, `current.rds` provenance,
and a short-lived writer lock beneath the caller’s
`.readAOFM/data/<table-id>/` directory. Age, file-count, and total-byte
limits prune old entries. The cache root defaults to
[`tempdir()`](https://rdrr.io/r/base/tempfile.html) and can be set with
the function’s `path` argument. The returned path carries source URL,
filename, byte-count, SHA-256, retrieval time, and cache-hit metadata.

[`aofm_file_metadata()`](https://joelf01.github.io/readAOFM/reference/aofm_file_metadata.md)
computes local byte-level provenance without network or cache writes.
[`read_aofm_file()`](https://joelf01.github.io/readAOFM/reference/read_aofm_file.md)
parses a local workbook using the same family parser selected by its
stable table ID. This is useful for a downloaded file or an installed
fixture:

``` r

local_metadata <- readAOFM::aofm_file_metadata(
  tb_issuance_fixture,
  table_id = "tb_issuance"
)
local_parsed <- readAOFM::read_aofm_file(
  tb_issuance_fixture,
  table_id = "tb_issuance"
)
local_metadata[c("table_id", "raw_bytes", "raw_sha256")]
#> $table_id
#> [1] "tb_issuance"
#> 
#> $raw_bytes
#> [1] 209385
#> 
#> $raw_sha256
#> [1] "4f74568d37258a6fad7b80136cdd64a29341f7bfa8550d2a4d7f8cc785e2e5c9"
utils::head(local_parsed[c("date_held", "name", "value")], 3)
#> # A tibble: 3 × 3
#>   date_held  name                value
#>   <date>     <chr>               <dbl>
#> 1 1982-08-05 coupon                 16
#> 2 1982-08-05 amount_offered  200000000
#> 3 1982-08-05 amount_allotted 200000000
```

The local path is not silently treated as a current source: standalone
metadata records its local modification time and omits a source URL.
Managed cache metadata remains qualified only while its file, digest,
and catalogue identity agree.

## Multi-result calls and cost

Selectors can intentionally identify several tables. For example,
`read_aofm(type = "issuance")` returns a named list for Treasury Bond,
Treasury Indexed Bond, and Treasury Note issuance, and it downloads each
workbook. A security-only call such as `read_aofm("tb")` similarly reads
every supported Treasury Bond table. Search first to see the exact set
and generated calls:

``` r

issuance <- readAOFM::search_aofm("issuance")
issuance[, c("security", "type", "id", "read_call")]
#>   security     type           id                    read_call
#> 1       tb issuance  tb_issuance  read_aofm("tb", "issuance")
#> 2      tib issuance tib_issuance read_aofm("tib", "issuance")
#> 3       tn issuance  tn_issuance  read_aofm("tn", "issuance")
```

Start with a single `security`/`type` pair when you are exploring, then
make a multi-result call once the additional network and parsing cost is
intended.

## Common errors and recovery

Selector validation happens locally before any AOFM request:

``` r

tryCatch(
  readAOFM::read_aofm("not-a-security"),
  error = function(error) conditionMessage(error)
)
#> [1] "No supported AOFM table matched security = \"not-a-security\" and type = NULL."
```

For a live download or parse failure, check the following in order:

1.  Run
    [`search_aofm()`](https://joelf01.github.io/readAOFM/reference/search_aofm.md)
    and copy the generated `read_call` so that selectors are exact.
2.  Check network/proxy/SSL access to the AOFM source URL and retry
    once.
3.  If the error mentions HTML, HTTP status, or workbook signature, AOFM
    may have returned an error page or redirect instead of an Excel
    workbook.
4.  If the error mentions sheets or required columns, the upstream
    workbook layout may have changed. Report the table ID, full error,
    and access date.
5.  If a CSV or raw download cannot be written, switch to a writable
    project directory or leave `csv = FALSE`.

For deterministic checks, use the packaged snapshots with
[`read_aofm_file()`](https://joelf01.github.io/readAOFM/reference/read_aofm_file.md)
as above and keep any temporary working directory isolated from analysis
outputs. The legacy readers intentionally remain catalogue-first; the
local-file API separates retrieval from parsing when a caller needs that
control.

## Turnover source transition

`read_secondary("tb_turnover")` and `read_secondary("tib_turnover")`
stitch historical companions covering July 2016 through December 2025 to
redesigned current workbooks beginning in January 2026. Current
workbooks contain monthly observation periods, while the Data Hub is
updated quarterly with an approximately two-month lag. Historical **By
Tenor** observations are monthly; historical **By Category**
observations are quarterly. Current sheets provide `security`, `region`,
and `counterparty`; the combined groups are `tenor`, `investor_type`,
`security`, `region`, and `counterparty`.

The natural key is `period`, `group`, and `name`. Current rows take
precedence on overlap, duplicate keys within a source are rejected, and
the returned data frame carries a two-record `aofm_sources` attribute
with historical/current roles and raw SHA-256 metadata. See the
route-continuity record for the exact source URLs and boundary evidence.

## Optional live troubleshooting probe

This normal live call is opt-in. It is disabled during ordinary vignette
and CRAN builds, so rendering remains deterministic and offline.

``` r

if (interactive() && identical(Sys.getenv("READAOFM_RUN_LIVE_EXAMPLES"), "true")) {
  live <- readAOFM::read_aofm("tb", "issuance")
  utils::head(live, 3)
} else {
  cat("Live probe skipped; set READAOFM_RUN_LIVE_EXAMPLES=true to opt in.\n")
}
#> Live probe skipped; set READAOFM_RUN_LIVE_EXAMPLES=true to opt in.
```
