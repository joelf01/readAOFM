# Read an AOFM end-of-month positions workbook

`read_eom()` downloads and tidies one of the eight end-of-month position
workbooks. It returns one named component for each non-Notes data
worksheet. Current Treasury Bond and Treasury Indexed Bond workbooks
provide `FaceValue`, `MarketValue`, `Delta`, `Duration`, and `Tenor`
components; AOFM may add or remove worksheets, so callers should inspect
the names of the returned list. For Treasury Bond, Treasury Indexed
Bond, and Treasury Note tables, each component includes a `Series`
identifier when repeated security identities occur. Dates are normalised
to `Date` and measures to numeric values.

## Usage

``` r
read_eom(
  aofm_table,
  csv = FALSE,
  timeout = getOption("readAOFM.timeout", 30),
  retries = getOption("readAOFM.retries", 1L),
  max_bytes = getOption("readAOFM.max_bytes", 100 * 1024^2)
)
```

## Arguments

- aofm_table:

  One of `aggregate_position_dealt`, `aggregate_position_settlement`,
  `tb_position_dealt`, `tb_position_settlement`, `tib_position_dealt`,
  `tib_position_settlement`, `tn_position_dealt`, or
  `tn_position_settlement`. It is normally selected through
  [`read_aofm()`](https://joelf01.github.io/readAOFM/reference/read_aofm.md).

- csv:

  Logical scalar (default `FALSE`). If `TRUE`, write one CSV per
  returned component to `output/` beneath the current working directory.

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

A named list with one tibble/data-frame component per non-Notes
worksheet. Each component preserves workbook identity fields, adds
`date` as a `Date`, and contains numeric `value` observations in long
form. Treasury Bond, Treasury Indexed Bond, and Treasury Note components
include a `Series` identifier where applicable. Component names are the
stable table ID followed by the worksheet name, for example
`tb_position_dealt_FaceValue`.

## Details

The workbook is fetched over HTTPS without credentials and staged in a
temporary file. Missing worksheets, rows, columns, or an incompatible
AOFM layout cause an error; no managed cache is used. Transport has the
public bounded timeout and size safeguards described above. Set
`csv = TRUE` to write one CSV per component beneath `output/` in the
current working directory.

## See also

[`read_aofm()`](https://joelf01.github.io/readAOFM/reference/read_aofm.md)
for the preferred interface and
[`search_aofm()`](https://joelf01.github.io/readAOFM/reference/search_aofm.md)
for offline catalogue discovery.

## Examples

``` r
search_aofm("tb dealt")
#>   security  type                id   reader                read_call
#> 1       tb dealt tb_position_dealt read_eom read_aofm("tb", "dealt")

# This is a complete official snapshot with five long data worksheets;
# run the offline parse interactively because it can take several seconds.
fixture <- system.file("extdata", "tb_position_dealt.xlsx", package = "readAOFM")
if (interactive() && requireNamespace("testthat", quietly = TRUE) && nzchar(fixture)) {
  result <- suppressMessages(testthat::with_mocked_bindings(
    read_eom("tb_position_dealt"),
    download_aofm_table_workbook = function(...) fixture,
    .package = "readAOFM"
  ))
  names(result)
}
```
