# Resolve internal AOFM table IDs from security and type arguments

This internal helper performs a local lookup in the package catalogue.
It does not download data or query the AOFM website. It is used by
[`download_aofm_xlsx()`](https://joelf01.github.io/readAOFM/reference/download_aofm_xlsx.md);
users should generally start with
[`search_aofm()`](https://joelf01.github.io/readAOFM/reference/search_aofm.md)
or
[`read_aofm()`](https://joelf01.github.io/readAOFM/reference/read_aofm.md)
instead.

## Usage

``` r
find_file(security = NULL, type = NULL)
```

## Arguments

- security:

  Optional exact security family. Supported values include `summary`,
  `aggregate`, `tb`, `tib`, `tn`, `slf`, `ownership`, `retail`, and
  `termpremium`.

- type:

  Optional exact table type. Supported values include `dealt`,
  `settlement`, `issuance`, `syndication`, `buyback`, `turnover`,
  `public`, and `nonresident`.

## Value

A character vector of matching catalogue IDs. `NULL` is returned when
there is no match. Multiple matches are printed and returned; the
catalogue includes seven rows that have no parser and can therefore be
downloaded only as raw workbooks.
