# Download one AOFM workbook by stable table ID

This is the explicit, managed-download API. It retrieves one current
AOFM workbook over HTTPS, verifies its size and SHA-256 digest, and
stores it in a content-addressed cache. Use
[`read_aofm_file()`](https://joelf01.github.io/readAOFM/reference/read_aofm_file.md)
to parse a retained local file without another network request.

## Usage

``` r
download_aofm_file(
  table_id,
  path = tempdir(),
  overwrite = TRUE,
  timeout = getOption("readAOFM.timeout", 30),
  retries = getOption("readAOFM.retries", 1L),
  max_bytes = getOption("readAOFM.max_bytes", 100 * 1024^2),
  max_age = getOption("readAOFM.max_age", 7 * 24 * 60^2),
  max_files = getOption("readAOFM.max_files", 100L),
  max_cache_bytes = getOption("readAOFM.max_cache_bytes", 500 * 1024^2),
  lock_timeout = getOption("readAOFM.lock_timeout", 10)
)
```

## Arguments

- table_id:

  A stable, parser-supported `table_id` returned by
  [`aofm_catalog()`](https://joelf01.github.io/readAOFM/reference/aofm_catalog.md).
  Raw-only/unsupported rows are rejected because no local parser
  contract exists for them.

- path:

  Root directory selected by the caller for the managed cache (default
  [`tempdir()`](https://rdrr.io/r/base/tempfile.html)). The function
  creates `.readAOFM/data/<table_id>/` below this root; it does not
  write to the package installation, the global workspace, or the user's
  home directory unless that location is explicitly supplied as `path`.

- overwrite:

  Logical scalar (default `TRUE`). Download and verify the current
  workbook even when a valid content-addressed cache entry exists. Set
  `FALSE` to reuse a valid entry within `max_age`.

- timeout:

  Per-attempt HTTPS transport timeout in seconds (default from
  `getOption("readAOFM.timeout", 30)`).

- retries:

  Non-negative number of retries after the first transport attempt
  (default from `getOption("readAOFM.retries", 1L)`).

- max_bytes:

  Maximum accepted workbook size in bytes (default from
  `getOption("readAOFM.max_bytes", 100 * 1024^2)`).

- max_age:

  Maximum age of a cache entry in seconds when `overwrite = FALSE`
  (default from `getOption("readAOFM.max_age", 7 * 24 * 60^2)`). Expired
  entries are refreshed.

- max_files:

  Maximum number of content-addressed workbooks retained below the
  selected cache root (default from
  `getOption("readAOFM.max_files", 100L)`).

- max_cache_bytes:

  Maximum combined byte size of retained workbooks (default from
  `getOption("readAOFM.max_cache_bytes", 500 * 1024^2)`).

- lock_timeout:

  Maximum seconds to wait for another writer for the same table (default
  from `getOption("readAOFM.lock_timeout", 10)`).

## Value

A normalized character path to the verified workbook. The returned path
has `table_id`, `source_url`, `raw_sha256`, `raw_bytes`, `retrieved_at`,
`cache_hit`, and `aofm_metadata` attributes. The metadata list records
the schema version, source filename, content-addressed cache filename,
exact byte count, SHA-256 digest, and UTC retrieval time.

## Details

Each table cache contains a SHA-256-named `.xls`/`.xlsx` file, a
`current.rds` metadata record, and a short-lived writer lock. Successful
downloads prune old entries according to `max_age`, `max_files`, and
`max_cache_bytes`; the current verified file is retained. Temporary
staging files and atomic metadata replacement prevent partial downloads
from being exposed. The managed cache is opt-in through this function;
the legacy
[`download_aofm_xlsx()`](https://joelf01.github.io/readAOFM/reference/download_aofm_xlsx.md)
and
[`read_aofm()`](https://joelf01.github.io/readAOFM/reference/read_aofm.md)
workflows retain their existing temporary staging and explicit
`data/`/`output/` side effects. On Windows, an old same-host lock is
conservatively treated as active because base R has no non-terminating
process-liveness probe there; the caller receives the usual lock-timeout
error instead of the package risking termination of the lock owner.

Invalid table IDs, unsupported rows, unsafe paths or bounds, lock
timeouts, HTTP/transport failures, non-workbook responses, oversized
files, and failed integrity checks throw errors. No credentials are
required. AOFM controls the remote URL and workbook layout, so a source
change can require a package update.

## See also

[`aofm_catalog()`](https://joelf01.github.io/readAOFM/reference/aofm_catalog.md)
for offline discovery,
[`aofm_file_metadata()`](https://joelf01.github.io/readAOFM/reference/aofm_file_metadata.md)
for local provenance,
[`read_aofm_file()`](https://joelf01.github.io/readAOFM/reference/read_aofm_file.md)
for offline parsing, and
[`download_aofm_xlsx()`](https://joelf01.github.io/readAOFM/reference/download_aofm_xlsx.md)
for the legacy explicit `data/` download workflow.

## Examples

``` r
# Downloading is deliberately interactive because it contacts the live
# AOFM website. The bounds keep an example transfer finite.
if (interactive()) {
  cache_root <- tempfile("readAOFM-cache-")
  workbook <- download_aofm_file(
    "tb_issuance",
    path = cache_root,
    overwrite = FALSE,
    timeout = 5,
    retries = 0,
    max_bytes = 50 * 1024^2,
    max_age = 24 * 60^2,
    max_files = 2,
    max_cache_bytes = 100 * 1024^2,
    lock_timeout = 5
  )
  c(path = workbook, sha256 = attr(workbook, "raw_sha256"))
}
```
