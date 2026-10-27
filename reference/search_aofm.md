# Search the supported AOFM table catalogue

`search_aofm()` searches the package's local catalogue without
downloading a workbook or contacting the AOFM website. Matching is
case-insensitive and accepts stable IDs, security/type values, and
useful aliases such as "treasury bond", "inflation", "foreign
ownership", "turnover", and "term premium". Use the returned `read_call`
column to pass a selected table to
[`read_aofm()`](https://joelf01.github.io/readAOFM/reference/read_aofm.md).

## Usage

``` r
search_aofm(
  query,
  read = FALSE,
  csv = FALSE,
  timeout = getOption("readAOFM.search_timeout", 3),
  retries = getOption("readAOFM.search_retries", 0L),
  max_bytes = getOption("readAOFM.max_bytes", 100 * 1024^2)
)
```

## Arguments

- query:

  One non-empty search string. Phrases are preferred when they match;
  otherwise all query tokens or any matching token are used.

- read:

  Logical scalar (default `FALSE`). If `FALSE`, return catalogue rows.
  If `TRUE`, read each matching table and return the parsed result.

- csv:

  Logical scalar (default `FALSE`). When `read = TRUE` and `csv = TRUE`,
  pass the option to
  [`read_aofm()`](https://joelf01.github.io/readAOFM/reference/read_aofm.md)
  so parsed CSVs are written below `output/` in the current working
  directory. It has no effect when `read = FALSE`.

- timeout:

  Positive finite numeric scalar giving the per-attempt timeout used for
  `read = TRUE` (default `getOption("readAOFM.search_timeout", 3)`
  seconds; maximum 300 seconds). Search itself is offline, but the value
  is still validated on every call.

- retries:

  Non-negative integer scalar giving retries after the first attempt
  when `read = TRUE` (default
  `getOption("readAOFM.search_retries", 0L)`; maximum 5).

- max_bytes:

  Positive finite numeric scalar giving the maximum accepted workbook
  size when `read = TRUE` (default
  `getOption("readAOFM.max_bytes", 100 * 1024^2)`; maximum 1 GiB).

## Value

When `read = FALSE`, a base data frame with columns `security`, `type`,
`id`, `reader`, and `read_call`; rows are reset to consecutive integers
and unsupported/raw-only catalogue rows are not included. A query with
no match returns a zero-row data frame. When `read = TRUE`, a single
parsed table is returned for one match, or a named list keyed by table
ID for multiple matches. A no-match `read = TRUE` call throws an error
before any download.

## Details

With `read = TRUE`, each match is immediately passed to
[`read_aofm()`](https://joelf01.github.io/readAOFM/reference/read_aofm.md)
and therefore requires an HTTPS request for every selected workbook. The
package does not require credentials; the reader stages workbooks in
temporary files and does not use the managed cache unless the caller
chooses
[`download_aofm_file()`](https://joelf01.github.io/readAOFM/reference/download_aofm_file.md)
explicitly.

Invalid queries (non-character, length other than one, `NA`, or blank
after trimming), invalid logical flags, or invalid transport bounds
throw an error. Search results are deterministic for a fixed local
catalogue and do not create files. With `read = TRUE`, `csv = TRUE`
writes parsed results beneath `output/` in the current working
directory; parsed values and available source files depend on the live
AOFM workbooks.

## See also

[`read_aofm()`](https://joelf01.github.io/readAOFM/reference/read_aofm.md)
for downloading and parsing, and
[`download_aofm_xlsx()`](https://joelf01.github.io/readAOFM/reference/download_aofm_xlsx.md)
for saving raw workbooks.

## Examples

``` r
# All of these searches are offline.
search_aofm("tb issuance")
#>   security     type          id             reader                   read_call
#> 1       tb issuance tb_issuance read_transactional read_aofm("tb", "issuance")
search_aofm("issuance")
#>   security     type           id             reader
#> 1       tb issuance  tb_issuance read_transactional
#> 2      tib issuance tib_issuance read_transactional
#> 3       tn issuance  tn_issuance read_transactional
#>                      read_call
#> 1  read_aofm("tb", "issuance")
#> 2 read_aofm("tib", "issuance")
#> 3  read_aofm("tn", "issuance")
search_aofm("treasury bond")
#>   security        type                     id             reader
#> 1       tb     buyback             tb_buyback read_transactional
#> 2       tb       dealt      tb_position_dealt           read_eom
#> 3       tb    issuance            tb_issuance read_transactional
#> 4       tb  settlement tb_position_settlement           read_eom
#> 5       tb syndication         tb_syndication   read_syndication
#> 6       tb    turnover            tb_turnover     read_secondary
#>                        read_call
#> 1     read_aofm("tb", "buyback")
#> 2       read_aofm("tb", "dealt")
#> 3    read_aofm("tb", "issuance")
#> 4  read_aofm("tb", "settlement")
#> 5 read_aofm("tb", "syndication")
#> 6    read_aofm("tb", "turnover")
search_aofm("inflation")
#>   security        type                      id             reader
#> 1      tib     buyback             tib_buyback read_transactional
#> 2      tib       dealt      tib_position_dealt           read_eom
#> 3      tib    issuance            tib_issuance read_transactional
#> 4      tib  settlement tib_position_settlement           read_eom
#> 5      tib syndication         tib_syndication   read_syndication
#> 6      tib    turnover            tib_turnover     read_secondary
#>                         read_call
#> 1     read_aofm("tib", "buyback")
#> 2       read_aofm("tib", "dealt")
#> 3    read_aofm("tib", "issuance")
#> 4  read_aofm("tib", "settlement")
#> 5 read_aofm("tib", "syndication")
#> 6    read_aofm("tib", "turnover")

# Reading a match is opt-in and network-dependent; keep it interactive.
if (interactive()) {
  search_aofm("tb issuance", read = TRUE)
}
```
