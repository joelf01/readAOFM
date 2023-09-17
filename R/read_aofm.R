#' Reads in and cleans any	data from the AOFM, returns cleaned in a long format
#'
#' @param security object you want data on, options include:
#' tb, tib, tn, slf, summary, aggregate, ownership, retail, termpremium
#' @param type the specific type of data you want, occasionally optional:
#' dealt, settlement, issuance, syndication, buyback, turnover,
#' @param csv do you want to export the cleaned data as a csv to /data
#' @param data.index internal data required to look up file to download
#' @returns AOFM selected AOFM data as a dataframe or list
#' @examples
#' \dontrun{read("tb", "issuance")}
#' # downloads Treasury Bond Issunace data from the AOFM
#' # returns cleaned in a long format
#'
#' @importFrom dplyr filter "%>%" pull
#'
#' @export


read_aofm <- function(security = NULL
                      , type = NULL
                      , csv = F
                      , data.index = aofm_index
) {

  # Use the find_file function to get the appropriate table(s) to download
  table_id <- find_file(security, type, data.index)

  # if no table returned then exit function
  if (is.null(table_id)) {
    # No valid table found, return NULL
    return(NULL)
  } else {

    if(length(table_id) == 1){

      child_fn <- data.index %>%
        filter(id == table_id) %>%
        pull(fn)

      if (child_fn == "read_eofy") {
        return(read_eofy(aofm_table = table_id))

      } else if (child_fn == "read_eom") {
        return(read_eom(aofm_table = table_id))

      } else if (child_fn == "read_transactional") {
        return(read_transactional(aofm_table = table_id))

      } else if (child_fn == "read_syndication") {
        return(read_syndication(aofm_table = table_id))

      } else if (child_fn == "read_ownership") {
        return(read_ownership(aofm_table = table_id))

      } else if (child_fn == "read_secondary") {
        return(read_secondary(aofm_table = table_id))

      } else if (child_fn == "read_premium") {
        return(read_premium(aofm_table = table_id))

      } else {
        print("Error: No function exists")
        return(NULL)

      }
    }
  }
}




