# Parse a local AOFM workbook

This function separates retrieval from parsing so callers can retain and
hash an immutable raw workbook before normalising its observations. It
is deterministic for a fixed local workbook and never contacts the AOFM
website.

## Usage

``` r
read_aofm_file(file_path, table_id, csv = FALSE)
```

## Arguments

- file_path:

  Path to an existing local AOFM `.xls` or `.xlsx` workbook. The file is
  not copied or removed.

- table_id:

  A stable parser-supported `table_id` returned by
  [`aofm_catalog()`](https://joelf01.github.io/readAOFM/reference/aofm_catalog.md).
  The ID selects the workbook-family parser and must match the local
  file's layout.

- csv:

  Logical scalar (default `FALSE`). When `TRUE`, also writes the
  parser's legacy CSV output below `output/` in the current working
  directory. Leave `FALSE` for a read-only parse.

## Value

The same family-specific data-frame or named-list result as
[`read_aofm()`](https://joelf01.github.io/readAOFM/reference/read_aofm.md),
with an `aofm_metadata` attribute containing local byte-level
provenance. Long-form results commonly contain identifier/date or period
columns, `name`, and `value`; exact measure columns and list components
follow the selected AOFM workbook family.

## Details

This local-file API performs no network request and does not use or
populate the managed `.readAOFM` cache. Use
[`download_aofm_file()`](https://joelf01.github.io/readAOFM/reference/download_aofm_file.md)
first when a verified managed retrieval is desired. Unsupported/raw-only
catalogue rows, missing files, invalid IDs, and layouts that do not
satisfy the selected parser's contract throw errors. With `csv = TRUE`,
the explicit `output/` write is the parser's legacy side effect; it is
separate from managed cache storage.

## See also

[`download_aofm_file()`](https://joelf01.github.io/readAOFM/reference/download_aofm_file.md)
for managed retrieval,
[`aofm_file_metadata()`](https://joelf01.github.io/readAOFM/reference/aofm_file_metadata.md)
for standalone provenance, and
[`read_aofm()`](https://joelf01.github.io/readAOFM/reference/read_aofm.md)
for the legacy download-and-parse workflow.

## Examples

``` r
fixture <- system.file("extdata", "tb_issuance.xlsx", package = "readAOFM")
if (nzchar(fixture)) {
  issuance <- read_aofm_file(fixture, "tb_issuance")
  utils::head(issuance[, c("date_held", "name", "value")])
  attr(issuance, "aofm_metadata")[c("table_id", "raw_sha256")]
}
#> New names:
#> • `` -> `...2`
#> • `` -> `...3`
#> • `` -> `...4`
#> • `` -> `...5`
#> • `` -> `...6`
#> • `` -> `...7`
#> • `` -> `...8`
#> • `` -> `...9`
#> • `` -> `...10`
#> • `` -> `...11`
#> • `` -> `...12`
#> • `` -> `...13`
#> • `` -> `...14`
#> • `` -> `...15`
#> • `` -> `...16`
#> • `` -> `...17`
#> • `` -> `...18`
#> • `` -> `...19`
#> • `` -> `...20`
#> $table_id
#> [1] "tb_issuance"
#> 
#> $raw_sha256
#> [1] "4f74568d37258a6fad7b80136cdd64a29341f7bfa8550d2a4d7f8cc785e2e5c9"
#> 
```
