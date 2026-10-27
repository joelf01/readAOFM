# Read AOFM secondary-market turnover

`read_secondary()` downloads and parses both official turnover sources
for Treasury Bonds or Treasury Indexed Bonds. It retains the historical
`tenor` and `investor_type` groups, adds the redesigned current
`security`, `region`, and `counterparty` groups, and returns one
continuous result. Workbooks are fetched over HTTPS without credentials
and staged in temporary files; the package does not use the managed
cache unless
[`download_aofm_file()`](https://joelf01.github.io/readAOFM/reference/download_aofm_file.md)
is called explicitly.

## Usage

``` r
read_secondary(
  aofm_table,
  csv = FALSE,
  timeout = getOption("readAOFM.timeout", 30),
  retries = getOption("readAOFM.retries", 1L),
  max_bytes = getOption("readAOFM.max_bytes", 100 * 1024^2)
)
```

## Arguments

- aofm_table:

  Either `tb_turnover` or `tib_turnover`. It is normally selected
  through
  [`read_aofm()`](https://joelf01.github.io/readAOFM/reference/read_aofm.md).

- csv:

  Logical scalar (default `FALSE`). If `TRUE`, write the parsed result
  to `output/<aofm_table>.csv` beneath the current working directory.

- timeout:

  Positive finite numeric scalar giving the per-attempt workbook
  transport timeout in seconds (default
  `getOption("readAOFM.timeout", 30)`; maximum 300 seconds).

- retries:

  Non-negative integer scalar giving the number of retries after the
  first workbook transport attempt (default
  `getOption("readAOFM.retries", 1L)`; maximum 5).

- max_bytes:

  Positive finite numeric scalar giving the maximum accepted workbook
  size in bytes (default
  `getOption("readAOFM.max_bytes", 100 * 1024^2)`; maximum 1 GiB).

## Value

A tibble/data frame in long form with `period` as a `Date`, `group` in
`tenor`, `investor_type`, `security`, `region`, or `counterparty`, and
`name`/`value` columns for numeric turnover measures. Rows are ordered
by the natural key `period`, `group`, and `name`. Attribute
`aofm_sources` is a two-record named list with `historical` and
`current` records. Each record includes `schema_version`, `table_id`,
`role`, `source_url`, URL-decoded `source_filename`, `raw_sha256`,
`raw_bytes`, and UTC `retrieved_at`.

## Details

The historical workbooks cover July 2016 through December 2025. Their
`By Tenor` observations are monthly and `By Category` observations are
quarterly. Redesigned current workbooks begin with monthly January 2026
observations. AOFM publishes updates quarterly with a two-month lag. The
sources are joined on `period`, `group`, and `name`; current-source rows
take precedence on an overlap and duplicate natural keys cause an error.
Missing sheets, periods, or changed workbook layouts also error.

## See also

[`read_aofm()`](https://joelf01.github.io/readAOFM/reference/read_aofm.md)
for the preferred interface and
[`search_aofm()`](https://joelf01.github.io/readAOFM/reference/search_aofm.md)
for offline catalogue discovery.

## Examples

``` r
search_aofm("secondary market turnover")
#>   security     type           id         reader                    read_call
#> 1       tb turnover  tb_turnover read_secondary  read_aofm("tb", "turnover")
#> 2      tib turnover tib_turnover read_secondary read_aofm("tib", "turnover")

if (interactive()) {
  read_secondary("tb_turnover")
}
```
