# Exact provenance for a local AOFM workbook

Computes byte-level provenance without downloading or modifying the
workbook. It can inspect a packaged fixture, an arbitrary local
workbook, or a path returned by
[`download_aofm_file()`](https://joelf01.github.io/readAOFM/reference/download_aofm_file.md).

## Usage

``` r
aofm_file_metadata(file_path, table_id = NULL)
```

## Arguments

- file_path:

  A path to one existing local `.xls` or `.xlsx` workbook. The file is
  read to compute its byte count and SHA-256 digest.

- table_id:

  Optional parser-supported stable AOFM table ID. Supply it when
  checking a standalone local file; a managed-cache path can carry the
  table ID in its download metadata.

## Value

A named list with `table_id`, `source_url`, `source_filename`, numeric
`raw_bytes`, lowercase hexadecimal `raw_sha256`, UTC POSIXct
`retrieved_at`, `package_version`, and logical `cache_hit`. For a
standalone local file, `source_url` is `NA` and `retrieved_at` is the
file's modification time; managed-cache provenance is retained only when
its metadata and bytes still agree.

## Details

This function performs no network request, creates no cache, and has no
output side effect. Invalid paths, unsupported file extensions,
malformed managed-cache metadata, and unknown table IDs are reported as
errors or as unqualified local provenance rather than being silently
treated as current AOFM data.

## See also

[`download_aofm_file()`](https://joelf01.github.io/readAOFM/reference/download_aofm_file.md)
for verified managed retrieval and
[`read_aofm_file()`](https://joelf01.github.io/readAOFM/reference/read_aofm_file.md)
for parsing a local workbook.

## Examples

``` r
fixture <- system.file("extdata", "tb_issuance.xlsx", package = "readAOFM")
if (nzchar(fixture)) {
  metadata <- aofm_file_metadata(fixture, table_id = "tb_issuance")
  metadata[c("table_id", "source_filename", "raw_bytes", "raw_sha256")]
}
#> $table_id
#> [1] "tb_issuance"
#> 
#> $source_filename
#> [1] "tb_issuance.xlsx"
#> 
#> $raw_bytes
#> [1] 209385
#> 
#> $raw_sha256
#> [1] "4f74568d37258a6fad7b80136cdd64a29341f7bfa8550d2a4d7f8cc785e2e5c9"
#> 
```
