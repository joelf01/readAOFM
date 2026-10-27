# Read AOFM Data Hub workbooks in R

readAOFM provides a reproducible, table-oriented interface to workbooks
published by the Australian Office of Financial Management (AOFM). Users
can discover supported tables with
[`search_aofm()`](https://joelf01.github.io/readAOFM/reference/search_aofm.md),
retrieve and parse one or more tables with
[`read_aofm()`](https://joelf01.github.io/readAOFM/reference/read_aofm.md),
use a family-specific reader when needed, or save raw workbooks with
[`download_aofm_xlsx()`](https://joelf01.github.io/readAOFM/reference/download_aofm_xlsx.md).
The opt-in managed workflow
[`download_aofm_file()`](https://joelf01.github.io/readAOFM/reference/download_aofm_file.md)
verifies and retains one workbook in a bounded, content-addressed cache;
[`read_aofm_file()`](https://joelf01.github.io/readAOFM/reference/read_aofm_file.md)
parses a retained local file without another network request. Parsed
results are returned in long-form data frames or named lists of data
frames, depending on the workbook family.

## Details

Public AOFM workbooks are available without package credentials. Reads
and raw downloads use HTTPS. The legacy readers stage workbooks in
temporary files and retrieve the current source on each call. Parsed CSV
output is an explicit opt-in side effect under `output/`; legacy raw
workbook downloads are an explicit operation under `data/` in the
current working directory. The managed API instead stores SHA-256-named
workbooks, metadata, and locks under caller-selected
`.readAOFM/data/<table_id>/` and prunes entries using explicit
age/count/byte bounds. It never writes to a package installation;
callers choose whether a cache root is temporary or persistent.

AOFM secondary-market turnover uses separate historical and redesigned
current workbooks.
[`read_secondary()`](https://joelf01.github.io/readAOFM/reference/read_secondary.md)
joins both official sources into a continuous result across the December
2025/January 2026 boundary, retains their source-specific
monthly/quarterly observation granularity, and records both workbook
hashes in provenance. AOFM publishes current updates quarterly with a
two-month lag.

Package code is distributed under the MIT licence with copyright
attributed to joelf01. AOFM source data, publications, workbook
structure, and any bundled snapshots remain subject to their original
publisher terms and attribution; using this package does not imply AOFM
endorsement. Consult
[`aofm_file_metadata()`](https://joelf01.github.io/readAOFM/reference/aofm_file_metadata.md)
and the packaged provenance notes when retaining a source workbook.

## See also

[`search_aofm()`](https://joelf01.github.io/readAOFM/reference/search_aofm.md),
[`read_aofm()`](https://joelf01.github.io/readAOFM/reference/read_aofm.md),
[`download_aofm_xlsx()`](https://joelf01.github.io/readAOFM/reference/download_aofm_xlsx.md),
[`aofm_catalog()`](https://joelf01.github.io/readAOFM/reference/aofm_catalog.md),
[`download_aofm_file()`](https://joelf01.github.io/readAOFM/reference/download_aofm_file.md),
[`aofm_file_metadata()`](https://joelf01.github.io/readAOFM/reference/aofm_file_metadata.md),
and
[`read_aofm_file()`](https://joelf01.github.io/readAOFM/reference/read_aofm_file.md)

## Author

joelf01
