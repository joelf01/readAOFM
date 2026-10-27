# Read AOFM syndication details

`read_syndication()` reads the syndicated-issue workbooks for Treasury
Bonds or Treasury Indexed Bonds. It downloads over HTTPS without
credentials, stages the workbook in a temporary file, and combines the
source sheets into a single long-form result. No managed cache is used;
the public timeout, retry, and workbook-size safeguards are applied.

## Usage

``` r
read_syndication(
  aofm_table,
  csv = FALSE,
  timeout = getOption("readAOFM.timeout", 30),
  retries = getOption("readAOFM.retries", 1L),
  max_bytes = getOption("readAOFM.max_bytes", 100 * 1024^2)
)
```

## Arguments

- aofm_table:

  Either `tb_syndication` or `tib_syndication`. It is normally selected
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

A tibble/data frame with source identifier columns, `pricing_date` and
`settlement_date` as `Date` values where present, a `type` identifying
`new_bond` or `tap`, and long-form `name` and numeric `value` columns.
Exact source fields follow the current AOFM workbook.

## Details

Notes worksheets are excluded. Empty files, missing required date fields
or value columns, and changed source layouts cause an error.

## See also

[`read_aofm()`](https://joelf01.github.io/readAOFM/reference/read_aofm.md)
for the preferred interface and
[`search_aofm()`](https://joelf01.github.io/readAOFM/reference/search_aofm.md)
for offline catalogue discovery.

## Examples

``` r
search_aofm("tb syndication")
#>   security        type             id           reader
#> 1       tb syndication tb_syndication read_syndication
#>                        read_call
#> 1 read_aofm("tb", "syndication")

fixture <- system.file("extdata", "tb_syndication.xlsx", package = "readAOFM")
if (requireNamespace("testthat", quietly = TRUE) && nzchar(fixture)) {
  result <- suppressMessages(testthat::with_mocked_bindings(
    read_syndication("tb_syndication"),
    download_aofm_table_workbook = function(...) fixture,
    .package = "readAOFM"
  ))
  head(result[c("pricing_date", "type", "name", "value")])
}
#> # A tibble: 6 × 4
#>   pricing_date type     name                       value
#>   <date>       <chr>    <chr>                      <dbl>
#> 1 2011-10-20   new_bond face_value_issued_m      3260   
#> 2 2011-10-20   new_bond bids_at_clearing_price_m 3433   
#> 3 2011-10-20   new_bond yield_percent               4.88
#> 4 2011-10-20   new_bond domestic                   81.3 
#> 5 2011-10-20   new_bond offshore                   18.7 
#> 6 2011-10-20   new_bond asia_ex_japan               7.4 
```
