#' Show index of tables from the AOFM website
#'
#' @param x object you want data on, options include:
#' tb, tib, tn, slf, summary, aggregate, ownership, retail, termpremium
#' @returns dataframe with index of files and arguments to download them
#' @examples
#' \dontrun{download_aofm_xlsx()}
#' # return dataframe with list of files/arguments

browse_tables <- function(x = aofm_index_nav){
  print(x)
}




#' Read multiple excel sheet to a list object, cc Ralf Stubner on StackOverflow
#'
#' @param filename The file path to the .xlsx from which you want to pull all sheets
#' @param tibble we always leave as false
#' @returns list object with dataframe for each sheet

read_excel_allsheets <- function(filename, tibble = FALSE) {
  sheets <- readxl::excel_sheets(filename)
  x <- lapply(sheets, function(X) readxl::read_excel(filename, sheet = X))
  if(!tibble) x <- lapply(x, as.data.frame)
  names(x) <- sheets
  x
}





#' Select columns which dont have all NA values, cc zack on StackOverflow
#'
#' @param x dataframe object
#' @returns columns which are not ONLY NA values


not_all_na <- function(x) any(!is.na(x))







#' Find name of file to download from AOFM
#'
#' @param security object you want data on, options include: tb, tib, tn, slf, summary, aggregate, ownership, retail, termpremium
#' @param type the specific type of data you want, occasionally optional: dealt, settlement, issuance, syndication, buyback, turnover,
#' @returns a vector with the file/s which match the input params
#' @examples
#' \dontrun{find_file("tb", "issuance")}
#' # returns "tb_issuance"
#' \dontrun{find_file("tb")}
#' \dontrun{returns c("tb_issuance", "tb_syndication", "tb_turnover" .....)}
#' \dontrun{find_file()}
#' # returns vector of all filenames


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

