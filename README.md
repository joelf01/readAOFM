
<!-- README.md is generated from README.Rmd. Please edit that file -->

# readAOFM

[![R-CMD-check](https://github.com/joelf01/readAOFM/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/joelf01/readAOFM/actions/workflows/R-CMD-check.yaml)
[![pkgdown](https://github.com/joelf01/readAOFM/actions/workflows/pkgdown.yaml/badge.svg)](https://github.com/joelf01/readAOFM/actions/workflows/pkgdown.yaml)

`readAOFM` gives R users a reproducible path from the [Australian Office
of Financial Management (AOFM)](https://www.aofm.gov.au/) Data Hub
catalogue to tidy, workbook-derived tables. Analysts and researchers can
discover and retrieve Australian Government securities data covering
issuance, transactions, positions, ownership, turnover, and term-premium
series for analysis and reporting.

## Installation

Install the current GitHub version with [`pak`](https://pak.r-lib.org/):

``` r
install.packages("pak")
pak::pak("joelf01/readAOFM")
```

The package is awaiting its first CRAN acceptance. After acceptance,
use:

``` r
install.packages("readAOFM")
```

## Discover an AOFM table

Start with the local catalogue to identify a supported table and obtain
its ready-to-run selector. This discovery step is network-free.

``` r
catalog <- readAOFM::search_aofm("tb issuance")
catalog[, c("id", "read_call")]
#>            id                   read_call
#> 1 tb_issuance read_aofm("tb", "issuance")
```

The same helper accepts ordinary descriptions:

``` r
readAOFM::search_aofm("foreign ownership")
readAOFM::search_aofm("inflation")
readAOFM::search_aofm("secondary market")
```

## Retrieve and chart a time series

The catalogue result points to the public retrieval call below. It
downloads the current Treasury Bond issuance workbook over HTTPS and
runs the package’s transactional parser:

``` r
tb_issuance <- readAOFM::read_aofm("tb", "issuance")
```

For a deterministic README and CRAN build, the rendered output below
runs that same public dispatcher and parser against the installed
`tb_issuance.xlsx` snapshot. The snapshot was originally acquired as
AOFM media item 591; that historical acquisition identifier, SHA-256,
and provenance are recorded with the [packaged
snapshots](https://github.com/joelf01/readAOFM/blob/main/inst/extdata/README.md).
It is not the package’s live route: normal user calls use the current
direct HTTPS Data Hub workbook route from the local catalogue.

The parsed table is long-form: `date_held` and `maturity` are `Date`
columns, `name` identifies the measure, and numeric observations are in
`value`. This base-R filter selects bids and allotments for a
long-running bond maturity and expresses the source values in A\$
billions.

``` r
series_labels <- c(
  amount_allotted = "Amount allotted",
  amount_of_bids = "Bids received"
)

selected <- tb_issuance[
  tb_issuance$maturity == as.Date("2029-04-21") &
    tb_issuance$name %in% names(series_labels) &
    !is.na(tb_issuance$value),
  c("date_held", "name", "value")
]

chart_data <- data.frame(
  date = selected$date_held,
  value = selected$value / 1e9,
  series = unname(series_labels[selected$name]),
  stringsAsFactors = FALSE
)
chart_data <- chart_data[order(chart_data$series, chart_data$date), ]
utils::head(chart_data, 4)
#>         date value          series
#> 1 2012-10-10  3.26 Amount allotted
#> 2 2013-04-10  0.64 Amount allotted
#> 4 2013-05-08  0.60 Amount allotted
#> 6 2013-06-19  0.70 Amount allotted
```

``` r
if (requireNamespace("ggplot2", quietly = TRUE)) {
  ggplot2::ggplot(
    chart_data,
    ggplot2::aes(x = date, y = value, colour = series, group = series)
  ) +
    ggplot2::geom_line() +
    ggplot2::labs(
      title = "Treasury Bond tender bids and allotments",
      subtitle = "Published tender observations for the 21 April 2029 maturity",
      x = "Tender date",
      y = "A$ billions",
      colour = "Measure",
      caption = "Source: Australian Office of Financial Management Data Hub"
    ) +
    ggplot2::theme_minimal(base_size = 13)
}
```

<img src="man/figures/retrieve-chart-1.png" alt="Line chart of bids received and amounts allotted at Australian Treasury Bond tenders for the 21 April 2029 maturity, from 2012 to 2025."  />

The [Getting Started
article](https://github.com/joelf01/readAOFM/blob/main/vignettes/getting-started.Rmd)
expands this workflow and explains the return contract. `read_aofm()`
returns one parsed object for a single match and a named list when
selectors match several tables. Start with a specific pair before
requesting a whole family.

Version 0.1.1 records two intentional source-shape corrections alongside
the route update: `read_eom()` preserves the current non-Notes worksheet
components (including `Tenor` and `Series` where supplied), and
syndication measures are returned with numeric values. Existing
selectors remain valid; inspect names and classes when combining results
from different AOFM workbook families.

## Supported AOFM data

The runtime catalogue contains 30 stable table IDs: 23 parser-supported
tables and seven raw-only/unsupported rows retained for direct workbook
access. The public `read_aofm()` interface normally uses the supported
rows’ `security` and `type` selectors.
`aofm_catalog(include_unsupported = TRUE)` exposes the full 30-row map,
including each direct HTTPS source route, its filename, and its support
status. `portfolio_overview` is the one raw-only historical direct
workbook that is not currently listed on the Data Hub; the catalogue
preserves that scope rather than implying parser support.

| AOFM family | Parsed table IDs | Reader and shape |
|----|----|----|
| End-of-financial-year summary | `summary` | `read_eofy()`; one long data frame |
| End-of-month positions | `aggregate_position_dealt`, `aggregate_position_settlement`, `tb_position_dealt`, `tb_position_settlement`, `tib_position_dealt`, `tib_position_settlement`, `tn_position_dealt`, `tn_position_settlement` | `read_eom()`; named list of position data frames |
| Transactional issuance/buybacks | `tb_issuance`, `tb_buyback`, `tib_issuance`, `tib_buyback`, `tn_issuance`, `retail`, `slf` | `read_transactional()`; one long data frame |
| Syndication details | `tb_syndication`, `tib_syndication` | `read_syndication()`; one long data frame |
| Ownership | `ownership_public`, `ownership_nonresident` | `read_ownership()`; named list of data frames |
| Secondary-market turnover | `tb_turnover`, `tib_turnover` | `read_secondary()`; one long data frame |
| Term premium | `termpremium` | `read_premium()`; one long data frame |

## Common workflows

Select one table or one ownership slice:

``` r
tb_issuance <- readAOFM::read_aofm("tb", "issuance")
ownership <- readAOFM::read_aofm("ownership", "nonresident")
```

Omitting `type` returns all parsed tables for a security. Omitting
`security` and specifying `type` returns all matching securities. These
calls are live downloads:

``` r
tb_tables <- readAOFM::read_aofm("tb")
names(tb_tables)

issuance_tables <- readAOFM::read_aofm(type = "issuance")
names(issuance_tables)
```

Use the local catalogue before downloading:

``` r
readAOFM::search_aofm("issuance")
readAOFM::search_aofm("treasury bond")
```

For stable IDs, inspect the complete offline catalogue before choosing a
download workflow:

``` r
readAOFM::aofm_catalog(include_unsupported = TRUE)[,
  c("table_id", "source_url", "file_name", "supported")
]
```

Most parsed frames are long, retain source identifiers, and expose
`name` and `value` measurement columns. Dates handled by a reader are
returned as `Date` objects. Inspect the actual workbook-derived columns
before writing analysis code:

``` r
names(tb_issuance)
str(tb_issuance)
```

EOM and ownership readers return named lists; inspect both levels with
`names(result)` and `names(result[[1]])`.

### CSV and raw workbook output

`csv = TRUE` keeps returning the parsed object and additionally writes
under `output/` relative to the current working directory. The
`download_aofm_xlsx()` helper saves raw workbooks under `data/` and
prints selected table IDs.

``` r
# Run in a project directory where writing is intentional:
# x <- readAOFM::read_aofm("tb", "issuance", csv = TRUE)
# file.exists(file.path("output", "tb_issuance.csv"))

# readAOFM::download_aofm_xlsx("tb", "issuance")
# file.exists(file.path("data", "tb_issuance.xlsx"))
```

Transactional, syndication, secondary, and premium readers use
`output/<table-id>.csv`; EOFY, EOM, and ownership readers may write one
file per workbook sheet.

For a caller-managed, verified local copy, use the opt-in integration
API:

``` r
cache_root <- tempfile("readAOFM-cache-")
workbook <- readAOFM::download_aofm_file(
  "tb_issuance", path = cache_root, overwrite = FALSE,
  timeout = 5, retries = 0, max_bytes = 50 * 1024^2
)
readAOFM::aofm_file_metadata(workbook)
readAOFM::read_aofm_file(workbook, "tb_issuance")
```

`download_aofm_file()` stores a SHA-256-named workbook, metadata, and a
short-lived writer lock below the caller’s `.readAOFM/data/<table-id>/`
directory, then prunes entries using its age, count, and byte limits.
The returned path carries the verified source and digest metadata. This
managed cache is explicit and caller-owned; it is separate from the
readers’ temporary staging and from the legacy `data/` and `output/`
side effects. Use `aofm_file_metadata()` and `read_aofm_file()` for
offline provenance and local parsing without another network request.

### Turnover across the AOFM source transition

`read_secondary("tb_turnover")` and `read_secondary("tib_turnover")`
join the historical and redesigned current workbooks into one series.
The historical companions cover July 2016 through December 2025; the
redesigned current workbooks provide January 2026 onward. The transition
has no December-to-January gap. Current workbooks contain monthly
observation periods, while AOFM updates the Data Hub quarterly with an
approximately two-month lag. Historical turnover has source-specific
granularity: **By Tenor** is monthly and **By Category** is quarterly.
Current sheets cover `security`, `region`, and `counterparty`; the
combined result uses the groups `tenor`, `investor_type`, `security`,
`region`, and `counterparty`.

Rows are joined by the natural key `period`, `group`, and `name`. If
sources overlap, the current workbook takes precedence; duplicate keys
within a source are rejected. The returned data frame has an
`aofm_sources` attribute containing the historical/current source URLs,
roles, filenames, byte counts, and SHA-256 digests. The [AOFM Data
Hub](https://www.aofm.gov.au/data-hub) is the primary source; exact
route and boundary evidence is kept in the package file
`inst/extdata/README-aofm-route-continuity.md`.

## Retrieval and reproducibility

- `search_aofm(query)` with `read = FALSE` is local and network-free.
- Readers and `search_aofm(..., read = TRUE)` fetch public AOFM
  workbooks over HTTPS.
- Downloads use a 30-second per-attempt timeout by default, retry once,
  and reject workbooks larger than 100 MiB by default. Set `timeout`,
  `retries`, and `max_bytes` on public readers/downloaders to apply
  tighter bounds.
- Public AOFM workbooks are available without a package username,
  password, or API key.
- Readers stage each workbook in a temporary file and fetch the current
  source on each call; repeating a read can therefore return a newer
  workbook. They do not create a persistent package cache.
- `download_aofm_file()` is the opt-in managed cache API. It uses a
  caller- selected root (default `tempdir()`), writes only beneath
  `.readAOFM/data/<table-id>/`, and exposes bounded pruning and
  provenance metadata. It never writes to the package installation or
  global workspace.
- `csv = TRUE` writes to `output/` and `download_aofm_xlsx()` writes to
  `data/` relative to the current working directory.

## Scope and limitations

The parser-supported catalogue contains the 23 tables listed above.
Seven additional catalogue entries are raw-only/unsupported and
available through direct raw workbook download:
`tb_issuance_conversion`, `indexation_factors`, `rmbs_transactions`,
`rmbs_auctions`, `interest_rate_swaps`, `cross_currency_swaps`, and
`portfolio_overview`. Their selector fields are empty, so an unfiltered
`download_aofm_xlsx()` call is the available route and also selects the
rest of the catalogue. `aofm_catalog(include_unsupported = TRUE)` shows
their verified direct source URLs and `.xls`/`.xlsx` destination names;
the extension is kept aligned for each raw-only row. `search_aofm()`
excludes these entries from its supported rows; its fallback token
matching can still return a supported row for a query that contains a
raw-only ID, so use the IDs shown in the returned result.

AOFM controls the source URLs and workbook layouts. Changed URLs, an
HTML error page, network failure, or changed sheets/columns can make a
read fail. The package validates HTTP responses, workbook signatures,
sheet counts, and required columns and reports the table context.

Public readers focus on catalogue-selected AOFM sources. Use
`read_aofm_file()` when a local workbook path is intentional; it
validates the parser-supported table ID and performs no download.
Identifier columns follow each workbook family and can differ across
sources. Live reads represent the current AOFM workbook rather than a
versioned data snapshot, while the five packaged snapshots provide fixed
inputs for documentation and tests.

| Symptom | What to check |
|----|----|
| No supported table matched | Use `search_aofm()` and its generated `read_call`. |
| Download or HTTP error | Check network, proxy, and SSL access to AOFM, then retry. |
| HTML or invalid-workbook error | The source may have redirected or returned an error page instead of an Excel workbook; report the table ID and URL if it persists. |
| Missing sheet or required-column error | AOFM may have changed the workbook layout; report the table ID, error, and access date. |
| Cannot create `data/` or `output/` | Use a writable project directory, or leave `csv = FALSE` and avoid raw downloads. |
| Managed cache cannot be written or verified | Choose a caller-owned writable `path`, inspect `aofm_file_metadata()`, or parse a local workbook directly with `read_aofm_file()`. |

## Citation, licensing, and attribution

Package code and documentation are released under the MIT license and
are copyright joelf01; see
[`LICENSE`](https://github.com/joelf01/readAOFM/blob/main/LICENSE).
Use `citation("readAOFM")` for the package citation. The package author
and maintainer is joelf01.

Data are sourced from the AOFM Data Hub. Follow the AOFM’s current
[copyright and licence terms](https://www.aofm.gov.au/copyright),
including attribution requirements and exclusions for third-party
material. Identify the Australian Office of Financial Management and the
AOFM Data Hub in downstream work and do not imply AOFM endorsement.
`readAOFM` is independent and is not affiliated with or endorsed by
AOFM.

## Contributing and reporting issues

Please report reproducible parser failures, changed AOFM workbook
layouts, or documentation problems through the [GitHub issue
tracker](https://github.com/joelf01/readAOFM/issues). Pull requests
can be proposed through the repository’s [pull-request
page](https://github.com/joelf01/readAOFM/pulls); detailed development
guidance is in `CONTRIBUTING.md` at the repository root.
