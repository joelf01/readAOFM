# Packaged AOFM workbook snapshots

These five Excel files are small, read-only snapshots of workbooks published by
the Australian Office of Financial Management (AOFM) Data Hub. They are shipped
so tests, examples, and vignettes can exercise the workbook readers without a
live network request. The snapshots are not a cache used by the package's
runtime download functions.

The files first appeared in this repository on 2026-04-01. The original
download date was not recorded.

| File | Original acquisition URL (historical snapshot provenance) | SHA-256 |
| --- | --- | --- |
| `tb_issuance.xlsx` | <https://www.aofm.gov.au/media/591> | `4f74568d37258a6fad7b80136cdd64a29341f7bfa8550d2a4d7f8cc785e2e5c9` |
| `tb_position_dealt.xlsx` | <https://www.aofm.gov.au/media/578> | `c9edb2c66d1b0dc8944ef2dbb1ebb1d4b2d7b619ae9912a268d38dc163f8e4fa` |
| `tb_syndication.xlsx` | <https://www.aofm.gov.au/media/632> | `56b4a69ffa6e40aab457eb2976247714979c0f834837a9d9ee47da1a8936052e` |
| `tib_issuance.xlsx` | <https://www.aofm.gov.au/media/429> | `bbd545880fc522dec2bf2e011e1846124706aec891e463654c5d458e42536c5d` |
| `tib_syndication.xlsx` | <https://www.aofm.gov.au/media/631> | `f0676f18700d787c8f8c8d3486bf6528453df23db6350f8359c2aafc982eaf77` |

These `/media/` links record where the snapshots were originally obtained;
they are historical acquisition provenance, not package runtime routes. They
are retained so the fixed bytes can be distinguished from later AOFM
republishing. As verified on 2026-08-25, the runtime catalogue uses direct Data
Hub files rather than these retired acquisition links:

| Table ID | Current runtime source | Relationship to packaged snapshot |
| --- | --- | --- |
| `tb_issuance` | <https://www.aofm.gov.au/sites/default/files/2025-06-20/treasury%20bonds%20-%20issuance.xlsx> | Different current bytes; the packaged file remains the earlier snapshot above. |
| `tb_position_dealt` | <https://www.aofm.gov.au/sites/default/files/2025-05-02/portfolio_aggregate_-_treasury_bonds_-_dealt.xlsx> | Different current bytes; the packaged file remains the earlier snapshot above. |
| `tb_syndication` | <https://www.aofm.gov.au/sites/default/files/2025-06-06/TB%20Syndications.xlsx> | Different current bytes; the packaged file remains the earlier snapshot above. |
| `tib_issuance` | <https://www.aofm.gov.au/sites/default/files/2025-07-10/Treasury%20Indexed%20Bonds%20-%20Issuance_0.xlsx> | Different current bytes; the packaged file remains the earlier snapshot above. |
| `tib_syndication` | <https://www.aofm.gov.au/sites/default/files/2025-06-06/TIB%20syndications.xlsx> | Byte-identical to the packaged snapshot at verification time. |

The current files were compared by SHA-256. A later AOFM update can change the
bytes available at a direct URL without changing this snapshot's recorded
hash or acquisition history.

The five rows above are the packaged fixtures. For the complete runtime map,
`aofm_catalog(include_unsupported = TRUE)` reports all 30 direct HTTPS file
routes: 23 parser-supported rows and seven raw-only/unsupported rows. The
raw-only rows retain their verified source scope and extension-compatible
`.xls`/`.xlsx` filenames. `portfolio_overview` is a verified historical direct
workbook that is not currently listed on the Data Hub; it remains raw-only and
is not a parser input.

## Documentation chart

The README and Getting Started chart is rendered from `tb_issuance.xlsx`
through the public `read_aofm("tb", "issuance")` dispatcher and its production
parser, with this installed snapshot substituted only at the HTTPS transport
boundary during documentation builds. The historical media item 591 is the
snapshot's acquisition identifier; the live dispatcher uses the current direct
catalogue route. The chart selects `amount_allotted` and `amount_of_bids` for
the 21 April 2029 maturity, uses the source `date_held`, `name`, and `value`
columns, and converts the dollar observations to A$ billions. The README image
under `man/figures/` is generated from that code.

## Attribution and terms

Please attribute the source as **Australian Office of Financial Management
(AOFM), Data Hub** and link to the relevant source URL above. The applicable
Creative Commons reference is [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/).
Check the AOFM source page and current terms before redistributing or relying
on a snapshot; this package does not replace the source's terms.

`readAOFM` is an independent, third-party R package. It is not affiliated with,
endorsed by, or sponsored by the AOFM. AOFM source URLs, workbook contents,
licensing terms, and availability may change after these snapshots were
packaged.
