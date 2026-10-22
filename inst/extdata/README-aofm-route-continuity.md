# AOFM route continuity audit

`aofm-route-continuity-2026-07-27.csv` records a live comparison of the 23
supported readAOFM routes against the workbooks downloaded by package commit
`8d9cdffa0cf5fe94aa363afe15e15ff1f9dad5b9`.
`aofm-live-source-urls-2026-07-27.csv` records the exact active and historical
AOFM Data Hub URLs used in the audit.

At runtime, `aofm_catalog(include_unsupported = TRUE)` normalizes all 30
catalogue rows to verified direct HTTPS AOFM file routes: 23 parser-supported
rows and seven raw-only/unsupported rows. The raw-only rows retain
`supported = FALSE` and have no parser contract. Their `.xls`/`.xlsx` filenames
remain aligned with their direct source extensions. `portfolio_overview` is a
verified historical direct workbook that is not currently listed on the Data
Hub; it is retained for raw download continuity and is not presented as a
current or parsed source.

The audit parses each workbook through the package parser and compares its
primary observation dates and natural identities. Natural identities use all
published hierarchy fields for position and ownership data; stable transaction
identifiers plus measure names for transactional data; `period`, `group`, and
`name` for turnover; and `date`, `type`, and `name` for term-premium data.
Whitespace in stable identifiers and hierarchy labels is normalized before
comparison.

The active turnover workbooks contain the redesigned current observations from
January 2026 onward. The AOFM Data Hub separately publishes historical
workbooks covering July 2016 through December 2025. Those are the only routes
that require source stitching, and the combined series has no missing month at
the December 2025 / January 2026 boundary. Current workbooks contain monthly
observation periods; AOFM updates the Data Hub quarterly with an approximately
two-month lag. Historical **By Tenor** observations are monthly, whereas
historical **By Category** observations are quarterly.

`read_secondary()` normalizes the source families to the groups `tenor`,
`investor_type`, `security`, `region`, and `counterparty`, then joins by the
natural key `period`, `group`, and `name`. Current rows take precedence when
sources overlap, and duplicate natural keys within a source are rejected. A
successful turnover result carries a two-record `aofm_sources` attribute, with
one record for each `historical`/`current` role and the source URL, decoded
filename, raw byte count, retrieval time, and SHA-256 digest. This keeps the
two source bytes auditable even when AOFM republishes or revises a workbook.

The continuity CSV's `legacy_max = 2024-12-31` is the end of the pinned
retired-baseline comparison, not the end of the replacement historical source.
The replacement historical workbooks extend through `2025-12-31`; the current
workbooks begin at `2026-01-31`, so the documented stitched result has no gap.

The current full-history workbooks intentionally withdraw a small number of
superseded observations: the executive summary's provisional 30 April 2025
snapshot and invalid derived duration/tenor cells in several dealt-basis
position files. These are current-source revisions, not truncated history, and
are not reintroduced from retired workbooks.

Exact repeated rows in TIB issuance, retail buyback, and Securities Lending
Facility data are present in the AOFM source itself. They are retained because
the public schema does not expose a transaction identifier that would prove
the records are accidental duplicates.
