# Read AOFM term-premium estimates

`read_premium()` downloads the `termpremium` workbook and combines its
two source worksheets into a date-sorted long-form result. The source is
fetched over HTTPS without credentials and staged in a temporary file;
no managed cache is used. The public timeout, retry, and workbook-size
safeguards are applied.

## Usage

``` r
read_premium(
  aofm_table,
  csv = FALSE,
  timeout = getOption("readAOFM.timeout", 30),
  retries = getOption("readAOFM.retries", 1L),
  max_bytes = getOption("readAOFM.max_bytes", 100 * 1024^2)
)
```

## Arguments

- aofm_table:

  Must be the catalogue ID `termpremium`. It is normally selected
  through
  [`read_aofm()`](https://joelf01.github.io/readAOFM/reference/read_aofm.md).

- csv:

  Logical scalar (default `FALSE`). If `TRUE`, write the parsed result
  to `output/termpremium.csv` beneath the current working directory.

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

A tibble/data frame sorted by `date`, with `date` as a `Date`, `type`
identifying the source worksheet, and long-form `name` and `value`
columns. Exact measures follow the current AOFM workbook.

## Details

Missing date fields, empty workbooks, and changed worksheet layouts
cause an error.

## See also

[`read_aofm()`](https://joelf01.github.io/readAOFM/reference/read_aofm.md)
for the preferred interface and
[`search_aofm()`](https://joelf01.github.io/readAOFM/reference/search_aofm.md)
for offline catalogue discovery.

## Examples

``` r
search_aofm("term premium")
#>      security type          id       reader                read_call
#> 1 termpremium <NA> termpremium read_premium read_aofm("termpremium")

if (interactive()) {
  read_premium("termpremium")
}
```
