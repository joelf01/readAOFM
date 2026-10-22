# readAOFM API and behaviour contract 0.1.1

This post-integration record describes the intentional public delta from the
immutable `inst/contract/api-behavior-0.1.0.md` baseline. It records the route
migration, turnover continuity work, transport controls, and local-file
integration API; it is not a substitute for the package documentation.

## Public API and formals

The exported set is exactly these 14 names:

```text
aofm_catalog
aofm_file_metadata
download_aofm_file
download_aofm_xlsx
read_aofm
read_aofm_file
read_eofy
read_eom
read_ownership
read_premium
read_secondary
read_syndication
read_transactional
search_aofm
```

The pre-existing arguments retain their order and defaults. The following
transport controls are appended to the existing workbook readers and to
`download_aofm_xlsx()`:

```text
timeout = getOption("readAOFM.timeout", 30)
retries = getOption("readAOFM.retries", 1L)
max_bytes = getOption("readAOFM.max_bytes", 100 * 1024^2)
```

`search_aofm()` appends the bounded search defaults
`getOption("readAOFM.search_timeout", 3)`,
`getOption("readAOFM.search_retries", 0L)`, and
`getOption("readAOFM.max_bytes", 100 * 1024^2)`. The controls are a real,
backward-compatible API addition: calls using only the 0.1.0 arguments keep
their argument order and defaults, while callers can bound network time,
retries, and accepted workbook size.

`download_aofm_file()` is the explicit managed-cache API. Its additional
cache controls are `max_age`, `max_files`, `max_cache_bytes`, and
`lock_timeout`, with the defaults documented by its generated reference page.
`read_aofm_file()` parses an existing local workbook without network access.

## Catalogue and current route authority

The catalogue identity and legacy row order remain a 30-row contract. These
23 IDs are parser-supported (the raw-only conversion row remains interleaved
at row 11 in the full catalogue):

```text
summary
aggregate_position_dealt
aggregate_position_settlement
tb_position_dealt
tb_position_settlement
tib_position_dealt
tib_position_settlement
tn_position_dealt
tn_position_settlement
tb_issuance
tb_syndication
tb_buyback
tib_issuance
tib_syndication
tib_buyback
tn_issuance
retail
slf
ownership_public
ownership_nonresident
tb_turnover
tib_turnover
termpremium
```

Seven IDs are deliberately retained as raw-only catalogue entries without
parsers:

```text
tb_issuance_conversion
indexation_factors
rmbs_transactions
rmbs_auctions
interest_rate_swaps
cross_currency_swaps
portfolio_overview
```

Every public catalogue row is resolved through the current direct URL map
below. The supported rows use the current AOFM Data Hub workbook assets; no
supported public route contains `/media/`. The seven raw-only rows retain a
verified direct workbook target for raw download, but they are not parser
support. The `portfolio_overview` target is a resolved historical direct
asset and is not presented as a current Data Hub listing. URL and catalogue
`file_name` extensions remain aligned (`.xls` with `.xls`, `.xlsx` with
`.xlsx`).

| table ID | status | direct source URL |
| --- | --- | --- |
| `summary` | supported | `https://www.aofm.gov.au/sites/default/files/2025-06-06/portfolio_aggregate_-_executive_summary_-_dealt.xlsx` |
| `aggregate_position_dealt` | supported | `https://www.aofm.gov.au/sites/default/files/2025-05-02/portfolio_aggregate_-_dealt_4.xlsx` |
| `aggregate_position_settlement` | supported | `https://www.aofm.gov.au/sites/default/files/2025-05-02/portfolio_aggregate_-_settlement.xlsx` |
| `tb_position_dealt` | supported | `https://www.aofm.gov.au/sites/default/files/2025-05-02/portfolio_aggregate_-_treasury_bonds_-_dealt.xlsx` |
| `tb_position_settlement` | supported | `https://www.aofm.gov.au/sites/default/files/2025-05-02/portfolio_aggregate_-_treasury_bonds_-_settlement.xlsx` |
| `tib_position_dealt` | supported | `https://www.aofm.gov.au/sites/default/files/2025-05-02/portfolio_aggregate_-_treasury_indexed_bonds_-_dealt.xlsx` |
| `tib_position_settlement` | supported | `https://www.aofm.gov.au/sites/default/files/2025-05-02/portfolio_aggregate_-_treasury_indexed_bonds_-_settlement.xlsx` |
| `tn_position_dealt` | supported | `https://www.aofm.gov.au/sites/default/files/2025-05-02/portfolio_aggregate_-_treasury_notes_-_dealt_1.xlsx` |
| `tn_position_settlement` | supported | `https://www.aofm.gov.au/sites/default/files/2025-05-02/portfolio_aggregate_-_treasury_notes_-_settlement.xlsx` |
| `tb_issuance` | supported | `https://www.aofm.gov.au/sites/default/files/2025-06-20/treasury%20bonds%20-%20issuance.xlsx` |
| `tb_issuance_conversion` | raw-only | `https://www.aofm.gov.au/sites/default/files/2025-06-06/treasury%20bonds%20-%20conversion%20and%20switch.xlsx` |
| `tb_syndication` | supported | `https://www.aofm.gov.au/sites/default/files/2025-06-06/TB%20Syndications.xlsx` |
| `tb_buyback` | supported | `https://www.aofm.gov.au/sites/default/files/2025-06-06/treasury%20bonds%20-%20buybacks.xlsx` |
| `tib_issuance` | supported | `https://www.aofm.gov.au/sites/default/files/2025-07-10/Treasury%20Indexed%20Bonds%20-%20Issuance_0.xlsx` |
| `tib_syndication` | supported | `https://www.aofm.gov.au/sites/default/files/2025-06-06/TIB%20syndications.xlsx` |
| `tib_buyback` | supported | `https://www.aofm.gov.au/sites/default/files/2025-06-06/treasury%20indexed%20bonds%20-%20buybacks.xlsx` |
| `tn_issuance` | supported | `https://www.aofm.gov.au/sites/default/files/2025-06-05/Treasury%20Notes%20-%20Issuance.xlsx` |
| `retail` | supported | `https://www.aofm.gov.au/sites/default/files/2025-06-06/retail%20register%20buybacks.xlsx` |
| `slf` | supported | `https://www.aofm.gov.au/sites/default/files/2025-06-06/securities%20lending%20facility.xlsx` |
| `ownership_public` | supported | `https://www.aofm.gov.au/sites/default/files/2025-05-02/register_of_government_borrowing.xlsx` |
| `ownership_nonresident` | supported | `https://www.aofm.gov.au/sites/default/files/2025-05-02/foreign_holdings.xlsx` |
| `tb_turnover` | supported | `https://www.aofm.gov.au/sites/default/files/2026-05-29/new_turnover_-_treasury_bonds.xlsx` |
| `tib_turnover` | supported | `https://www.aofm.gov.au/sites/default/files/2026-05-29/new_turnover_-_treasury_indexed_bonds.xlsx` |
| `termpremium` | supported | `https://www.aofm.gov.au/sites/default/files/2025-06-06/term%20premium.xlsx` |
| `indexation_factors` | raw-only | `https://www.aofm.gov.au/sites/default/files/2025-05-02/treasury_indexed_bonds_-_indexation_factors_1.xlsx` |
| `rmbs_transactions` | raw-only | `https://www.aofm.gov.au/sites/default/files/2025-05-02/rmbs_-_transactions_0.xlsx` |
| `rmbs_auctions` | raw-only | `https://www.aofm.gov.au/sites/default/files/2025-05-02/rmbs_-_auction_results.xlsx` |
| `interest_rate_swaps` | raw-only | `https://www.aofm.gov.au/sites/default/files/2025-05-02/interest_rate_swaps_-_australian_dollar.xlsx` |
| `cross_currency_swaps` | raw-only | `https://www.aofm.gov.au/sites/default/files/2025-05-02/interest_rate_swaps_-_cross_currency.xlsx` |
| `portfolio_overview` | raw-only historical asset | `https://www.aofm.gov.au/sites/default/files/2019-06/australian_government_securities_on_issue_-_1983_to_2002.xlsx` |

The tracked `data-raw/aofm_catalog_source.csv` is the catalogue authority.
Running `Rscript data-raw/generate_sysdata.R` validates the schema, exact
30-row order, explicit 23/7 support split, direct HTTPS routes, filename
extensions, raw-only scope, and turnover descriptions, then deterministically
regenerates both `aofm_index` (30 x 9) and `aofm_index_nav` (30 x 5) in
`R/sysdata.rda`. The intentional internal field spelling `despription` is
preserved for compatibility. Repeated generation is byte-identical. The
source-map SHA-256 is
`3a0ba9bfbac04ca623ed2da5a1783078352badf624e85375ffdd134a3be526b1` and the
generated `R/sysdata.rda` SHA-256 is
`985ca7d08373871c1f2f2a92514fec8326742602a47d24c7e0ecf844e7218a29`.
`aofm_catalog()`, `aofm_table_row()`, raw download, managed download, and
reader dispatch use the generated catalogue by default; validated
`readAOFM.url_overrides` are an explicit caller option layered on top.

## Turnover continuity and provenance

`tb_turnover` and `tib_turnover` combine the explicit historical workbooks

```text
https://www.aofm.gov.au/sites/default/files/2025-05-02/turnover_-_treasury_bonds.xlsx
https://www.aofm.gov.au/sites/default/files/2025-05-02/turnover_-_treasury_indexed_bonds.xlsx
```

with the current redesigned workbooks in the route table. Historical
`By Tenor` observations are monthly by `Month`; historical `By Category`
observations are quarterly by `Quarter`. The redesigned current
`Security`, `Region`, and `Counterparty` sheets contain monthly periods from
January 2026 onward. AOFM publishes or updates the current workbook
quarterly with a two-month lag; the first redesigned release describes the
March 2026 quarter. The source boundary is therefore December 2025 to
January 2026, not an invented gap.

The stitched long result has columns `period`, `group`, `name`, and `value`.
Its natural observation identity is `(period, group, name)`, and group values
are `tenor`, `investor_type`, `security`, `region`, and `counterparty`. If a
current source revises an overlapping natural identity, the current row wins
deterministically. Duplicate identities within either source, or after
stitching, are rejected rather than silently aggregated.

Stitched turnover results carry an `aofm_sources` attribute containing exactly
two records named `historical` and `current`. Each record has exactly:
`schema_version` (1), `table_id`, `role`, `source_url`, URL-decoded
`source_filename`, `raw_sha256`, `raw_bytes`, and UTC `retrieved_at`. Fixture
and live-source tests assert this schema without depending on network
availability.

## Intentional non-turnover corrections

The 0.1.1 EOM parser retains the previous component outputs and also exposes
the `Tenor` component when present in the official workbook. Treasury,
indexed-bond, and note EOM rows include a deterministic `Series` identity
column so repeated security rows remain distinct. For the TB dealt fixture,
the five components are `FaceValue`, `MarketValue`, `Delta`, `Duration`, and
`Tenor`; each has 5,450 rows and 8 columns, including `Series`, `date`, and
numeric `value`. TB and TIB syndication outputs remain 578 x 11 and 187 x 11,
respectively, while their `value` columns are now numeric (`double`) after
strict source conversion; this is a deliberate type correction, while the
identifiers and ordering remain the existing contract.

Other representative non-turnover fixture outputs are unchanged from the
0.1.0 fingerprints. In particular, the TB issuance fixture remains 26,268 x
7 with its original names, Date columns, classes, and serialized output
identity.

## Local-file, cache, and offline boundaries

`read_aofm_file()` and the packaged fixtures exercise parsing without network
access. Legacy readers stage downloads in temporary files and retain their
existing explicit CSV/output side effects. `download_aofm_file()` is opt-in:
it stores verified content-addressed workbooks and metadata under the caller's
`.readAOFM/data/<table_id>` root, with bounded size, age, file-count, and lock
controls. It does not install or download anything at package load, and it
does not write to a user's home or global workspace unless the caller
explicitly supplies that root.
