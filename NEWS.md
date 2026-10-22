# readAOFM 0.1.1

* Replaced retired `/media/{id}` routes with direct AOFM Data Hub workbook
  URLs for the complete 30-entry catalogue. The 23 parser-supported tables
  use current Data Hub routes; the seven raw-only entries retain their
  `supported = FALSE` semantics and use verified direct workbook routes,
  including the explicitly historical Portfolio Overview file.
* Added support for Notes-first workbooks and POSIX-second date headers used by
  current AOFM files.
* Updated Treasury Bond and Treasury Indexed Bond turnover parsing for the
  redesigned `Security`, `Region`, and `Counterparty` worksheets, and added
  the historical/current source join. Historical sources cover July 2016
  through December 2025; redesigned current sources begin with January 2026
  observations. The source-specific observation periods are retained: the
  historical By Tenor sheet is monthly, the historical By Category sheet is
  quarterly, and current sheets are monthly observations within the quarterly
  publication cycle, which has an approximately two-month lag.
* `read_secondary()` now combines turnover groups `tenor`, `investor_type`,
  `security`, `region`, and `counterparty` by the natural key
  `period` + `group` + `name`. Current rows take precedence on overlap,
  duplicate keys are rejected, ordering is deterministic, and the result
  carries named historical/current SHA-256 source provenance in
  `aofm_sources`.
* Added the public `aofm_catalog()`, `download_aofm_file()`,
  `aofm_file_metadata()`, and `read_aofm_file()` APIs. The opt-in file API
  provides a bounded, content-addressed cache under a caller-selected root
  (default `tempdir()`), with metadata, locking, and pruning; legacy readers
  continue to use temporary staging and explicit caller output paths.
* Made same-host stale-lock handling fail closed on Windows, where base R's
  process signal API cannot probe liveness without terminating the target.
* Added backward-compatible `timeout`, `retries`, and `max_bytes` controls to
  public search, download, and reader calls, with documented bounds and
  defaults for live retrieval.
* Corrected the EOM output contract to include its `Tenor` and `Series`
  components where supplied by the workbook, and normalized syndication
  measure values to numeric. These are intentional v0.1.1 schema/type changes;
  existing calling syntax remains valid, while consumers should use component
  names and documented column types rather than assuming the former shape.

# readAOFM 0.1.0

This release prepares readAOFM for an initial CRAN submission. CRAN acceptance
remains pending.

* Documented the package's ten exported functions, including their return
  shapes, errors, network requirements, and opt-in file-writing behaviour.
* Added a task-oriented path from offline catalogue search to a selected live
  AOFM workbook and clarified the supported source families and raw-only
  catalogue entries.
* Added a deterministic end-to-end example that retrieves Treasury Bond
  issuance through the public API and charts bids and allotments from a
  provenance-documented official snapshot.
* Standardized the package author, maintainer, and copyright-holder display as
  joelf01 across package and repository metadata.
* Added deterministic, fixture-backed documentation and examples for the
  workbook readers, together with troubleshooting guidance for changed source
  URLs and layouts.
* Added fixed connection, transfer, low-speed, and workbook-size bounds to live
  downloads so unavailable or oversized sources fail within defined limits.
* Updated package metadata, licensing attribution, community guidance, and
  release checks for portable R-package builds, including multi-platform
  R CMD check, coverage, and pkgdown workflows.
