# readAOFM API and behaviour contract 0.1.0

This record captures the public API and representative output behaviour at
baseline commit `796d4c2733f09accb798009c7c88a1e59ff1315c` (2026-08-24). It is
an evidence record for documentation and release work, not a new API surface.
The source catalogue identity below is shared with downstream consumers and is
not limited to any one pinned downstream commit.

## Public API and formals

The exact exported set is:

```text
download_aofm_xlsx
read_aofm
read_eofy
read_eom
read_ownership
read_premium
read_secondary
read_syndication
read_transactional
search_aofm
```

The baseline formals are:

```text
download_aofm_xlsx(security = NULL, type = NULL)
read_aofm(security = NULL, type = NULL, csv = FALSE)
read_eofy(aofm_table, csv = FALSE)
read_eom(aofm_table, csv = FALSE)
read_ownership(aofm_table, csv = FALSE)
read_premium(aofm_table, csv = FALSE)
read_secondary(aofm_table, csv = FALSE)
read_syndication(aofm_table, csv = FALSE)
read_transactional(aofm_table, csv = FALSE)
search_aofm(query, read = FALSE, csv = FALSE)
```

## Runtime source fingerprints

These SHA-256 values are hashes of the executable source files at the baseline
commit. They are recorded to make an executable-code comparison explicit; a
comment-only edit will also change a file hash and must therefore be reviewed
as source drift rather than silently treated as proof of equivalence.

| File | SHA-256 at baseline |
| --- | --- |
| `R/aofm_parse_helpers.R` | `f14309371b63cdc93593b96321ccc98d73b12a3e06903fc1c140d97a28a38913` |
| `R/download_excel.R` | `3c8b59045659566ce28d23688cb43e580f02b620f82567067ee30d497cc9d2e3` |
| `R/download_helpers.R` | `f4f3d04533dde3a14aa4326b575964c5cb4d1956a65beece80ebecf61df0f1ba` |
| `R/globals.R` | `9378f0837d4f93943337ba6a45d98ab6bd1c85ab9042bea62b9c8ebd37a3cd84` |
| `R/helper_functions.R` | `a1595ed2f9f105e7ab4374825bd93507ea57c7e59bcd862a6de1b1a22d101902` |
| `R/individual_table_functions.R` | `562adb822999c7fe4d73a5c47d17e9f5d690385d680e860d0d4e24754c935a56` |
| `R/read_aofm.R` | `2263dd30cb8d48d6ccde8188da1e6374005d75edf400398ead62836ac607fac9` |
| `R/search_aofm.R` | `2cd5bbc29b6fb50c06e8a1bda1bda78058eb4ab6f80d714659df59890add0388` |
| `R/sysdata.rda` | `e74b71a3bf575837c37f484434d9f0a29a6525d6d6190900efe63890cf0e0f49` |

## Source catalogue identity

The embedded `aofm_index` contains 30 rows in this order. The first 23 rows
have readers and are the supported rows:

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

The remaining seven rows are catalogue entries without a parser and are
excluded from `read_aofm()` and `search_aofm()`:

```text
tb_issuance_conversion
indexation_factors
rmbs_transactions
rmbs_auctions
interest_rate_swaps
cross_currency_swaps
portfolio_overview
```

The 23-supported/7-unsupported identity and order are a shared downstream
constraint. They are not merely the identity of one pinned downstream API
version. Source URLs and workbook names are embedded with the catalogue; the
five deterministic snapshots used by tests and examples are documented in
`inst/extdata/README.md`.

## Side effects and transport

- `search_aofm(read = FALSE)` is local and offline. It returns a base data
  frame with columns `security`, `type`, `id`, `reader`, and `read_call`.
- Reader calls use HTTPS AOFM workbook URLs, require no credentials, stage the
  workbook in a temporary file, and do not maintain a persistent package
  cache.
- `csv = TRUE` writes parsed output under `output/` in the current working
  directory. End-of-month and ownership readers can write one CSV per returned
  component.
- `download_aofm_xlsx()` writes raw workbooks under `data/` in the current
  working directory and prints status messages. It does not return parsed data.
- A live AOFM request, changed URL, non-workbook response, empty download,
  missing required sheet/column, or incompatible workbook layout can fail.
  Tests and examples use the packaged snapshots or mocks and do not require
  network availability.

## Representative fixture output fingerprints

The following digests use `digest::digest(..., algo = "sha256", serialize = TRUE,
serializeVersion = 3)` under R 4.5.1. They fingerprint the complete parsed
object, including names, classes, row names, and attributes.

| Call/input | Class and dimensions | SHA-256 of parsed object |
| --- | --- | --- |
| `read_aofm("tb", "issuance")` using `tb_issuance.xlsx` | `tbl_df/tbl/data.frame`, 26,268 × 7 | `e169ddd250ca52b0a10c4b6a4d9818d6b54da28d3d327ee758f100896dba2ac2` |
| `read_aofm("tb", "dealt")` using `tb_position_dealt.xlsx` | named list of 4 tibbles; 5,430 × 7, then 5,450 × 7, 5,450 × 7, 5,450 × 7 | `4d08917af2bf48c2d507e62da41d8d1805144c88f97f0b241af74fa0b6a0a6bb` |
| `read_aofm("tb", "syndication")` using `tb_syndication.xlsx` | `tbl_df/tbl/data.frame`, 578 × 11 | `c24854e8a350eadc1d4ae589db64907cb165885827fdeb531265274262feec4b` |
| `read_aofm("tib", "issuance")` using `tib_issuance.xlsx` | `tbl_df/tbl/data.frame`, 3,944 × 7 | `53eadda0ba4b690043f914109c0e9a807938e3d4731fd9cb64e4a70e6b62318c` |
| `read_aofm("tib", "syndication")` using `tib_syndication.xlsx` | `tbl_df/tbl/data.frame`, 187 × 11 | `41b272ffc2a0095df5bb6f3a3c994c1be7ca3b02bc406a0c4f524dfe5f7bd06a` |

Transactional output columns are, in order,
`date_held`, `tender_number`, `maturity`, `isin`, `date_settled`,
`name`, `value`; date columns are `Date`, identifier/name columns are
character, and `value` is numeric with no missing or non-finite values in the
two issuance snapshots. The `tb_issuance` date ranges are 1982-08-05..2025-05-27
for `date_held`, 1982-08-10..2025-05-29 for `date_settled`, and
1984-04-15..2054-06-21 for `maturity`; its numeric value range is
0..2.5047e+10. The `tib_issuance` date ranges are 1985-07-31..2025-04-11,
1985-08-03..2025-04-15, and 1995-08-21..2050-02-22; its numeric value range is
-1.1625..4e+09.

Syndication output columns are, in order,
`bond_line`, `pricing_date`, `settlement_date`, `pricing_reference`,
`initial_price_guidance_bp`, `final_spread_bp`, `curve_extension`,
`joint_lead_managers`, `type`, `name`, `value`; date columns are `Date`
and `value` remains character. `type` contains `new_bond` and `tap`.

EOM output names are `tb_position_dealt_FaceValue`,
`tb_position_dealt_MarketValue`, `tb_position_dealt_Delta`, and
`tb_position_dealt_Duration`; each component has the five source identifier
columns followed by `date` (`Date`) and numeric `value`.

## Representative errors and limitations

These errors are call-free and deterministic before any network request:

```text
read_aofm("not-a-security"): No supported AOFM table matched security = "not-a-security" and type = NULL.
read_aofm("tb", "not-a-type"): No supported AOFM table matched security = "tb" and type = "not-a-type".
search_aofm(NULL) or search_aofm(""): `query` must be a single non-empty string.
download_aofm_workbook("", ...): `url` must be a single non-empty string.
download_aofm_workbook(..., "file.txt"): `destfile` must end in .xls or .xlsx.
```

The package is intentionally limited to the 23 parser-supported catalogue
rows. It does not provide credentials, a persistent cache, or an offline
replacement for the live AOFM source. Upstream workbook changes can alter
available rows or parser-compatible columns and should be treated as a source
contract change requiring review.
