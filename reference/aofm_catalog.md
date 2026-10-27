# List AOFM data tables known to the package

Returns the package's local table catalogue without downloading a
workbook or contacting the AOFM website. Stable `table_id` values can be
passed to
[`download_aofm_file()`](https://joelf01.github.io/readAOFM/reference/download_aofm_file.md)
and
[`read_aofm_file()`](https://joelf01.github.io/readAOFM/reference/read_aofm_file.md).

## Usage

``` r
aofm_catalog(include_unsupported = FALSE)
```

## Arguments

- include_unsupported:

  Logical scalar (default `FALSE`). Include the seven catalogue rows
  without a package parser when `TRUE`.

## Value

A base `data.frame` with one row per selected table and these columns:
`security`, `type`, `table_id`, `reader`, `category`, `title`,
`description`, `source_url`, `file_name`, and logical `supported`.
Character columns are returned as character vectors, not factors. The
`source_url` values for parser-supported rows are the current HTTPS AOFM
workbook routes used by the package; raw-only rows are retained for
catalogue continuity and may use their verified raw-download routes.

## Details

The catalogue contains 23 parser-supported rows by default. Seven
additional rows are retained as raw-only/unsupported source records and
can be included for catalogue or raw-download workflows with
`include_unsupported = TRUE`; they are not accepted by the parser APIs.

Catalogue lookup is deterministic and offline. It does not validate a
URL by making a network request. A non-missing logical scalar is
required for `include_unsupported`; invalid values throw an error.

## See also

[`search_aofm()`](https://joelf01.github.io/readAOFM/reference/search_aofm.md)
for text search,
[`download_aofm_file()`](https://joelf01.github.io/readAOFM/reference/download_aofm_file.md)
for the opt-in managed download/cache workflow, and
[`read_aofm_file()`](https://joelf01.github.io/readAOFM/reference/read_aofm_file.md)
for parsing a local workbook.

## Examples

``` r
catalog <- aofm_catalog()
catalog[, c("table_id", "reader", "supported")]
#>                         table_id             reader supported
#> 1                        summary          read_eofy      TRUE
#> 2       aggregate_position_dealt           read_eom      TRUE
#> 3  aggregate_position_settlement           read_eom      TRUE
#> 4              tb_position_dealt           read_eom      TRUE
#> 5         tb_position_settlement           read_eom      TRUE
#> 6             tib_position_dealt           read_eom      TRUE
#> 7        tib_position_settlement           read_eom      TRUE
#> 8              tn_position_dealt           read_eom      TRUE
#> 9         tn_position_settlement           read_eom      TRUE
#> 10                   tb_issuance read_transactional      TRUE
#> 11                tb_syndication   read_syndication      TRUE
#> 12                    tb_buyback read_transactional      TRUE
#> 13                  tib_issuance read_transactional      TRUE
#> 14               tib_syndication   read_syndication      TRUE
#> 15                   tib_buyback read_transactional      TRUE
#> 16                   tn_issuance read_transactional      TRUE
#> 17                        retail read_transactional      TRUE
#> 18                           slf read_transactional      TRUE
#> 19              ownership_public     read_ownership      TRUE
#> 20         ownership_nonresident     read_ownership      TRUE
#> 21                   tb_turnover     read_secondary      TRUE
#> 22                  tib_turnover     read_secondary      TRUE
#> 23                   termpremium       read_premium      TRUE

all_catalogue_rows <- aofm_catalog(include_unsupported = TRUE)
table(all_catalogue_rows$supported)
#> 
#> FALSE  TRUE 
#>     7    23 
```
