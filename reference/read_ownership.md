# Read AOFM ownership of Australian Government Securities

`read_ownership()` reads the public register or non-resident holdings
workbook and returns one long-form data frame per source worksheet. It
downloads over HTTPS without credentials and stages the workbook in a
temporary file; the package does not use the managed cache unless
[`download_aofm_file()`](https://joelf01.github.io/readAOFM/reference/download_aofm_file.md)
is called explicitly. The public timeout, retry, and workbook-size
safeguards are applied.

## Usage

``` r
read_ownership(
  aofm_table,
  csv = FALSE,
  timeout = getOption("readAOFM.timeout", 30),
  retries = getOption("readAOFM.retries", 1L),
  max_bytes = getOption("readAOFM.max_bytes", 100 * 1024^2)
)
```

## Arguments

- aofm_table:

  Either `ownership_public` or `ownership_nonresident`. It is normally
  selected through
  [`read_aofm()`](https://joelf01.github.io/readAOFM/reference/read_aofm.md).

- csv:

  Logical scalar (default `FALSE`). If `TRUE`, write one CSV per
  returned worksheet beneath `output/` in the current working directory.

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

A named list of data frames. Public ownership returns the first two
source worksheets; non-resident ownership returns source worksheets two
through four. Each component preserves its source identity columns and
contains `date` as a `Date` plus numeric `value` observations in long
form. Component names combine the table ID and source worksheet name.

## Details

Missing sheets, rows, columns, or changed source layouts cause an error.
The exact identity columns follow the current AOFM workbook.

## See also

[`read_aofm()`](https://joelf01.github.io/readAOFM/reference/read_aofm.md)
for the preferred interface and
[`search_aofm()`](https://joelf01.github.io/readAOFM/reference/search_aofm.md)
for offline catalogue discovery.

## Examples

``` r
search_aofm("foreign ownership")
#>    security        type                    id         reader
#> 1 ownership nonresident ownership_nonresident read_ownership
#>                               read_call
#> 1 read_aofm("ownership", "nonresident")

if (interactive()) {
  read_ownership("ownership_nonresident")
}
```
