####### parent function #####

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
    #if we return a table then run through using the appropriate function, use a for loop so user can download multiple files into R at once
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




