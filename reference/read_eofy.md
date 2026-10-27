# Read the AOFM end-of-financial-year executive summary

`read_eofy()` downloads the `summary` workbook from the AOFM Data Hub
and tidies its first worksheet into long form. The source is fetched
over HTTPS without credentials and staged in a temporary file; the
package does not use the managed cache unless
[`download_aofm_file()`](https://joelf01.github.io/readAOFM/reference/download_aofm_file.md)
is called explicitly. Transport is bounded by the public `timeout`,
`retries`, and `max_bytes` arguments. A changed workbook layout or
missing required columns causes an error.

## Usage

``` r
read_eofy(
  aofm_table,
  csv = FALSE,
  timeout = getOption("readAOFM.timeout", 30),
  retries = getOption("readAOFM.retries", 1L),
  max_bytes = getOption("readAOFM.max_bytes", 100 * 1024^2)
)
```

## Arguments

- aofm_table:

  Must be the catalogue ID `summary`. It is normally selected through
  [`read_aofm()`](https://joelf01.github.io/readAOFM/reference/read_aofm.md)
  rather than called directly.

- csv:

  Logical scalar (default `FALSE`). If `TRUE`, also write the parsed
  data to `output/eofy_executive_summary.csv` beneath the current
  working directory.

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

A tibble/data frame in long form. It contains the source identifier
columns plus `date` (a `Date`) and `value`; duplicate and missing
observations are removed by the parser. Exact identifier columns follow
the current AOFM workbook.

## See also

[`read_aofm()`](https://joelf01.github.io/readAOFM/reference/read_aofm.md)
for the preferred interface and
[`search_aofm()`](https://joelf01.github.io/readAOFM/reference/search_aofm.md)
for offline catalogue discovery.

## Examples

``` r
search_aofm("executive summary")
#>   security type      id    reader            read_call
#> 1  summary <NA> summary read_eofy read_aofm("summary")

# A live workbook read is opt-in so package examples remain offline.
if (interactive()) {
  read_eofy("summary")
}
```
