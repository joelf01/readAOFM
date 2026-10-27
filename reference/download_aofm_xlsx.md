# Download raw AOFM Data Hub workbooks

`download_aofm_xlsx()` resolves exact `security` and `type` values
against the package's local AOFM catalogue, then downloads the matching
`.xls` or `.xlsx` workbooks over HTTPS. Raw files are written beneath
`data/` in the current working directory. The function does not require
credentials and does not maintain a managed package cache. Use
[`read_aofm()`](https://joelf01.github.io/readAOFM/reference/read_aofm.md)
for the usual download-and-parse workflow,
[`download_aofm_file()`](https://joelf01.github.io/readAOFM/reference/download_aofm_file.md)
when an explicit content-addressed cache is wanted, and
[`search_aofm()`](https://joelf01.github.io/readAOFM/reference/search_aofm.md)
to discover valid tables without a network request.

## Usage

``` r
download_aofm_xlsx(
  security = NULL,
  type = NULL,
  timeout = getOption("readAOFM.timeout", 30),
  retries = getOption("readAOFM.retries", 1L),
  max_bytes = getOption("readAOFM.max_bytes", 100 * 1024^2)
)
```

## Arguments

- security:

  Optional exact security family (default `NULL`). Supported values are
  `summary`, `aggregate`, `tb`, `tib`, `tn`, `slf`, `ownership`,
  `retail`, and `termpremium`.

- type:

  Optional exact table type (default `NULL`). Supported values are
  `dealt`, `settlement`, `issuance`, `syndication`, `buyback`,
  `turnover`, `public`, and `nonresident`. If either argument is
  omitted, every matching catalogue row is selected.

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

A character vector of matched table IDs, returned invisibly after the
files have been downloaded. If no row matches, `NULL` is returned and an
explanatory message is printed. The files themselves are written to
`data/` and are not returned as R objects. The function creates `data/`
before checking whether a selector matched, so a no-match call can
create an empty directory.

## Details

The `timeout`, `retries`, and `max_bytes` arguments provide bounded live
transfers. They default to 30 seconds, one retry, and 100 MiB
respectively (through the corresponding `readAOFM.*` options).

The catalogue contains 23 parser-supported rows and seven raw-only
(unsupported) rows without parsers. Their selector fields are not
populated, so raw-only rows cannot be selected individually; an
unfiltered `download_aofm_xlsx()` call includes all 30 catalogue
workbooks. They cannot be read by
[`read_aofm()`](https://joelf01.github.io/readAOFM/reference/read_aofm.md)
or
[`read_aofm_file()`](https://joelf01.github.io/readAOFM/reference/read_aofm_file.md)
because no parser contract exists for them. A changed AOFM URL,
non-workbook response, or changed workbook layout causes an error from
the downloader or the subsequent parser.

Invalid selectors and transport bounds, HTTP/transport failures,
non-workbook responses, oversized files, and incompatible source layouts
throw errors. The function writes only to the caller's current-working
directory `data/` path; it does not write to the package installation or
user-level cache.

## Examples

``` r
# Catalogue discovery is offline and does not create files.
search_aofm("tb issuance")[, c("id", "read_call")]
#>            id                   read_call
#> 1 tb_issuance read_aofm("tb", "issuance")

# Downloading is opt-in in examples because it requires the live AOFM site.
if (interactive()) {
  download_in_temporary_directory <- function() {
    old <- getwd()
    on.exit(setwd(old), add = TRUE)
    setwd(tempdir())
    download_aofm_xlsx("tb", "issuance")
  }
  download_in_temporary_directory()
}
```
