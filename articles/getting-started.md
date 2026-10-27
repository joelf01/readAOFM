# Getting started with readAOFM

`readAOFM` connects local catalogue discovery with retrieval and parsing
of workbooks published by the Australian Office of Financial Management
(AOFM) Data Hub. This article follows a complete workflow: identify
Treasury Bond issuance, retrieve its long-form observations, select a
representative series, and create a chart. A packaged official snapshot
makes the rendered article deterministic while the user-facing call
remains the normal public API.

## Discover a table locally

[`search_aofm()`](https://joelf01.github.io/readAOFM/reference/search_aofm.md)
searches the package’s local catalogue and returns metadata and
ready-to-run calls. The default `read = FALSE` keeps discovery
network-free.

``` r

readAOFM::search_aofm("tb issuance")[, c("id", "reader", "read_call")]
#>            id             reader                   read_call
#> 1 tb_issuance read_transactional read_aofm("tb", "issuance")
```

The search accepts ordinary descriptions as well as exact terminology.
For example, these searches identify the indexed-bond and non-resident
ownership families:

``` r

readAOFM::search_aofm("inflation")
#>   security        type                      id             reader
#> 1      tib     buyback             tib_buyback read_transactional
#> 2      tib       dealt      tib_position_dealt           read_eom
#> 3      tib    issuance            tib_issuance read_transactional
#> 4      tib  settlement tib_position_settlement           read_eom
#> 5      tib syndication         tib_syndication   read_syndication
#> 6      tib    turnover            tib_turnover     read_secondary
#>                         read_call
#> 1     read_aofm("tib", "buyback")
#> 2       read_aofm("tib", "dealt")
#> 3    read_aofm("tib", "issuance")
#> 4  read_aofm("tib", "settlement")
#> 5 read_aofm("tib", "syndication")
#> 6    read_aofm("tib", "turnover")
readAOFM::search_aofm("foreign ownership")
#>    security        type                    id         reader
#> 1 ownership nonresident ownership_nonresident read_ownership
#>                               read_call
#> 1 read_aofm("ownership", "nonresident")
```

The `read_call` column is useful when a query returns more than one
table. For example, `search_aofm("issuance")` finds Treasury Bond,
Treasury Indexed Bond, and Treasury Note issuance; retrieving that full
result would request three workbooks.

## Retrieve and chart a time series

The public entry point is `read_aofm(security, type, csv = FALSE)`. The
`security` and `type` values are exact selectors. For the current AOFM
source, run:

``` r

tb_issuance <- readAOFM::read_aofm("tb", "issuance")
```

The rendered article executes that same public dispatcher and parser
with the installed `tb_issuance.xlsx` snapshot substituted at the HTTPS
transport boundary. The snapshot was originally acquired as AOFM media
item 591; the packaged snapshot documentation records that historical
acquisition, its verified SHA-256, attribution, and licensing context.
That identifier is not a live route. Ordinary calls retrieve the current
direct HTTPS Data Hub workbook route from the local catalogue.

The public return contract is visible directly from the parsed object:

``` r

stopifnot(
  is.data.frame(tb_issuance),
  all(c("date_held", "tender_number", "maturity", "name", "value") %in%
        names(tb_issuance)),
  inherits(tb_issuance$date_held, "Date"),
  inherits(tb_issuance$maturity, "Date"),
  is.numeric(tb_issuance$value)
)

data.frame(
  object_class = paste(class(tb_issuance), collapse = ", "),
  rows = nrow(tb_issuance),
  columns = ncol(tb_issuance),
  date_class = paste(class(tb_issuance$date_held), collapse = ", "),
  stringsAsFactors = FALSE
)
#>              object_class  rows columns date_class
#> 1 tbl_df, tbl, data.frame 26268       7       Date
```

The transactional reader preserves workbook identifiers, represents
measures in the long-form `name`/`value` columns, and returns handled
dates as `Date` objects. The following base-R transformation selects two
source measures for the 21 April 2029 maturity and converts their dollar
values to A\$ billions.

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

![Line chart of bids received and amounts allotted at Australian
Treasury Bond tenders for the 21 April 2029 maturity, from 2012 to
2025.](getting-started_files/figure-html/retrieve-chart-1.png)

For a single table,
[`read_aofm()`](https://joelf01.github.io/readAOFM/reference/read_aofm.md)
returns the parsed data frame directly. When selectors match several
supported tables, it returns a named list keyed by table ID. Omitting
both selectors requests all 23 parser-supported tables and can involve
many downloads. `csv = TRUE` preserves the parsed return value and also
writes the reader’s CSV output under `output/` in the current working
directory; the network and outputs article provides an isolated example.

The runtime catalogue tracks 30 IDs in total: 23 parser-supported tables
and seven raw-only/unsupported rows. Use
`aofm_catalog(include_unsupported = TRUE)` to inspect all direct HTTPS
source routes and filename extensions before a raw download.
`portfolio_overview` remains a raw-only historical direct workbook
because it is not currently listed on the Data Hub; no parser support is
implied.

## Turnover source transition

The two turnover readers stitch the historical and redesigned current
AOFM workbooks. Historical turnover covers July 2016 through December
2025; the redesigned current workbooks begin in January 2026, with no
gap at the boundary. Current workbooks contain monthly observation
periods, while the Data Hub is updated quarterly with an approximately
two-month lag. Historical turnover has mixed source granularity: **By
Tenor** is monthly and **By Category** is quarterly. Current sheets
provide `security`, `region`, and `counterparty`; the combined result
uses `tenor`, `investor_type`, `security`, `region`, and `counterparty`
groups.

Rows are identified by the natural key `period`, `group`, and `name`.
Current rows take precedence if the two sources overlap, and duplicate
keys within a source are rejected. The result carries a two-record
`aofm_sources` attribute with historical/current roles and raw URL,
filename, byte-count, and SHA-256 metadata. The durable route and
boundary record is in `inst/extdata/README-aofm-route-continuity.md`.

## Retrieve the latest AOFM workbook

Set `READAOFM_RUN_LIVE_EXAMPLES=true` in an interactive or development
session to run the live call below after checking that the AOFM site is
reachable. The ordinary article build uses the deterministic snapshot
path above.

``` r

if (interactive() && identical(Sys.getenv("READAOFM_RUN_LIVE_EXAMPLES"), "true")) {
  live_tb_issuance <- readAOFM::read_aofm("tb", "issuance")
  stopifnot(is.data.frame(live_tb_issuance))
  utils::head(live_tb_issuance, 3)
} else {
  cat("Live read skipped; set READAOFM_RUN_LIVE_EXAMPLES=true to opt in.\n")
}
#> Live read skipped; set READAOFM_RUN_LIVE_EXAMPLES=true to opt in.
```

Live readers fetch public workbooks over HTTPS without AOFM credentials.
They stage each workbook in a temporary file and retrieve the current
source on every call. AOFM controls upstream availability and workbook
layout; use the network, outputs, and troubleshooting article for
bounded transport details and recovery steps. The public transport
controls are `timeout` (30 seconds per attempt by default), `retries`
(one retry by default), and `max_bytes` (100 MiB by default).

For an explicit caller-managed copy,
[`download_aofm_file()`](https://joelf01.github.io/readAOFM/reference/download_aofm_file.md)
stores verified SHA-256-named workbooks and metadata below
`.readAOFM/data/<table-id>/` beneath the chosen root (by default
[`tempdir()`](https://rdrr.io/r/base/tempfile.html)), with bounded
pruning and writer locking. It is separate from temporary reader staging
and the legacy `data/`/`output/` writes. Use
[`aofm_file_metadata()`](https://joelf01.github.io/readAOFM/reference/aofm_file_metadata.md)
to inspect a local digest and
[`read_aofm_file()`](https://joelf01.github.io/readAOFM/reference/read_aofm_file.md)
to parse a local workbook without another network request.
