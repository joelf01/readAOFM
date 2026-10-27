# Read every worksheet in a local Excel workbook

This internal helper reads each worksheet with
[`readxl::read_excel()`](https://readxl.tidyverse.org/reference/read_excel.html)
and names the resulting list with the workbook's sheet names. It does
not make a network request. The package's public readers additionally
normalise the returned worksheets into long-form observations.

## Usage

``` r
read_excel_allsheets(filename, tibble = FALSE)
```

## Arguments

- filename:

  Path to a local `.xls` or `.xlsx` workbook.

- tibble:

  If `FALSE` (the default), coerce each worksheet to a base data frame.
  If `TRUE`, retain the tibble returned by
  [`readxl::read_excel()`](https://readxl.tidyverse.org/reference/read_excel.html).

## Value

A named list with one data-frame or tibble element per worksheet.
