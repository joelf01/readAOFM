#' Print the internal AOFM table index
#'
#' This is an internal helper used while developing and testing the package.
#' It prints `x` and returns it invisibly; it does not download data or query
#' the AOFM website. The public, user-facing catalogue search is
#' [search_aofm()].
#'
#' @param x An object to print. The default is the package's internal table
#'   index used to map `security` and `type` arguments to source workbooks.
#' @returns `x`, invisibly.
#' @keywords internal

browse_tables <- function(x = aofm_index_nav){
  print(x)
}




#' Read every worksheet in a local Excel workbook
#'
#' This internal helper reads each worksheet with [readxl::read_excel()] and
#' names the resulting list with the workbook's sheet names. It does not make
#' a network request. The package's public readers additionally normalise the
#' returned worksheets into long-form observations.
#'
#' @param filename Path to a local `.xls` or `.xlsx` workbook.
#' @param tibble If `FALSE` (the default), coerce each worksheet to a base
#'   data frame. If `TRUE`, retain the tibble returned by
#'   [readxl::read_excel()].
#' @returns A named list with one data-frame or tibble element per worksheet.
#' @keywords internal

read_excel_allsheets <- function(filename, tibble = FALSE) {
  sheets <- readxl::excel_sheets(filename)
  x <- lapply(sheets, function(X) suppressWarnings(readxl::read_excel(filename, sheet = X)))
  if(!tibble) x <- lapply(x, as.data.frame)
  names(x) <- sheets
  x
}





#' Test whether an object contains at least one non-missing value
#'
#' This internal predicate is used to drop columns that are entirely `NA`
#' while parsing transactional workbooks.
#'
#' @param x An atomic vector, matrix, or data-frame column to inspect.
#' @returns A length-one logical value: `TRUE` when at least one element of
#'   `x` is not `NA`, otherwise `FALSE`.
#' @keywords internal


not_all_na <- function(x) any(!is.na(x))







#' Resolve internal AOFM table IDs from security and type arguments
#'
#' This internal helper performs a local lookup in the package catalogue. It
#' does not download data or query the AOFM website. It is used by
#' [download_aofm_xlsx()]; users should generally start with [search_aofm()]
#' or [read_aofm()] instead.
#'
#' @param security Optional exact security family. Supported values include
#'   `summary`, `aggregate`, `tb`, `tib`, `tn`, `slf`, `ownership`, `retail`,
#'   and `termpremium`.
#' @param type Optional exact table type. Supported values include `dealt`,
#'   `settlement`, `issuance`, `syndication`, `buyback`, `turnover`, `public`,
#'   and `nonresident`.
#' @returns A character vector of matching catalogue IDs. `NULL` is returned
#'   when there is no match. Multiple matches are printed and returned; the
#'   catalogue includes seven rows that have no parser and can therefore be
#'   downloaded only as raw workbooks.
#' @keywords internal


find_file <- function(security = NULL ## options include; tb, tib, tn, slf, summary, aggregate, ownership, retail, term.premium
                      , type =  NULL ## options include; dealt, settlement, issuance, syndication, buyback, turnover
){

  if (is.null(security) != T){
    tmp <- aofm_index %>%
      filter(p.security == security)
  } else {
    tmp <- aofm_index
  }

  if (is.null(type) != T){
    tmp <- tmp %>%
      filter(p.type == type)
  }


  if (nrow(tmp) == 0) {
    print("The input parameters do not map to a valid table. If unsure, please check valid tables using 'index'")
    return(NULL)
  } else if (nrow(tmp) == 1){
    return(tmp$id)
  } else if (nrow(tmp) > 1) {
    print("The input parameters do not map to a unique table, please add additional parameters. The below print-out shows all tables selected and their parameters.")
    print(tmp %>%
            select(c("p.security", "p.type", "id")))
    return(tmp$id)
  }

}
