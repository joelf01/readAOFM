#' Download xlsx.xls files from AOFM DataHub
#'
#' @param security object you want data on, options include:
#' tb, tib, tn, slf, summary, aggregate, ownership, retail, termpremium
#' @param type the specific type of data you want, occasionally optional:
#' dealt, settlement, issuance, syndication, buyback, turnover,
#' @param data.index internal data required to look up file to download
#' @returns a list of downloaded files
#' @examples
#' \dontrun{download_aofm_xlsx("tb", "issuance")}
#' # downloads AOFM Treasury Bond Issuance data to data/tb_issuance.xlsx
#' \dontrun{download_aofm_xlsx("tb")}
#' # downloads all Treasury Bond data from the AOFM Datahub incl
#' # issunace, syndication details, position data etc to data/
#' \dontrun{download_aofm_xlsx()}
#' # downloads all data from the AOFM Datahub to data/
#'
#' @importFrom readxl excel_sheets read_excel
#' @importFrom dplyr filter "%>%" pull
#' @importFrom utils download.file
#' @importFrom here here
#'
#' @export


download_aofm_xlsx <- function(security = NULL ## options include; tb, tib, tn, slf, summary, aggregate, ownership, retail, term.premium
                               , type =  NULL ## options include;
                               , data.index = aofm_index
) {

  # run find_file function to determine which file to download
  aofm_table <- find_file(security, type, basis, data.index)

  # check if /data sub folder exists and create if not
  if (dir.exists("data") == F) {
    dir.create("data")
  }

  if (is.null(aofm_table)==T){
    print(aofm_table)

  } else {
    for (i in 1:length(aofm_table)){
      file.url <- data.index %>%
        filter(id == data.index$id[i]) %>%
        pull(file.path)

      file.name <- data.index$file.save[i]
      download.file(file.url, destfile = here("data", file.name))
    }
    print(paste("The following files have been downloaded to:", here("data")))
    print(aofm_table)
  }
}
