# Read a transactional AOFM workbook

`read_transactional()` handles tender, buyback, retail-facility, and
securities-lending workbooks. It downloads the selected workbook over
HTTPS without credentials, stages it in a temporary file, and pivots
numeric measures into long form. The package does not use the managed
cache unless
[`download_aofm_file()`](https://joelf01.github.io/readAOFM/reference/download_aofm_file.md)
is called explicitly and applies the public bounded timeout and size
safeguards described in
[`read_aofm()`](https://joelf01.github.io/readAOFM/reference/read_aofm.md).

## Usage

``` r
read_transactional(
  aofm_table,
  csv = FALSE,
  timeout = getOption("readAOFM.timeout", 30),
  retries = getOption("readAOFM.retries", 1L),
  max_bytes = getOption("readAOFM.max_bytes", 100 * 1024^2)
)
```

## Arguments

- aofm_table:

  One of `tb_issuance`, `tb_buyback`, `tib_issuance`, `tib_buyback`,
  `tn_issuance`, `retail`, or `slf`. It is normally selected through
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

A tibble/data frame in long form. Workbook identifier columns are
retained; numeric measures are represented by `name` and `value`. Known
date fields such as `date_held`, `date_settled`, `maturity`,
`settle_date`, `start_date`, `end_date`, and `security_maturity_date`
are normalised to `Date` where present. Exact measures and identifier
columns follow the current source workbook.

## Details

Empty files, missing required columns, non-workbook responses, and
changed AOFM layouts cause an error. Missing measure values are omitted
by the parser.

## See also

[`read_aofm()`](https://joelf01.github.io/readAOFM/reference/read_aofm.md)
for the preferred interface and
[`search_aofm()`](https://joelf01.github.io/readAOFM/reference/search_aofm.md)
for offline catalogue discovery.

## Examples

``` r
search_aofm("tb issuance")
#>   security     type          id             reader                   read_call
#> 1       tb issuance tb_issuance read_transactional read_aofm("tb", "issuance")

fixture <- system.file("extdata", "tb_issuance.xlsx", package = "readAOFM")
if (requireNamespace("testthat", quietly = TRUE) && nzchar(fixture)) {
  result <- suppressMessages(testthat::with_mocked_bindings(
    read_transactional("tb_issuance"),
    download_aofm_table_workbook = function(...) fixture,
    .package = "readAOFM"
  ))
  head(result[c("date_held", "name", "value")])
}
#> # A tibble: 6 × 3
#>   date_held  name                                value
#>   <date>     <chr>                               <dbl>
#> 1 1982-08-05 coupon                              16   
#> 2 1982-08-05 amount_offered               200000000   
#> 3 1982-08-05 amount_allotted              200000000   
#> 4 1982-08-05 amount_of_bids               580191000   
#> 5 1982-08-05 coverage_ratio                       2.91
#> 6 1982-08-05 weighted_average_issue_yield        16.4 
```
