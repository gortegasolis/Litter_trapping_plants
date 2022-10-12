#Setup the environment
#Load packages
pacman::p_load(tidyverse,
               foreach,
               taxize,
               rscopus,
               microdemic,
               easyPubMed,
               rentrez,
               RSQLite)

#Function to keep a lightweight workspace
send2sqlite <- function(con, dataframe){
  RSQLite::dbWriteTable(conn = con,
                        name = paste0("tbl_", dataframe),
                        value = get(dataframe),
                        overwrite = T)
  rm(list = dataframe,
    envir = .GlobalEnv)
}

#Connect database
condb <- dbConnect(RSQLite::SQLite(), "LTEp.sqlite")
dbGetInfo(condb)
#dbDisconnect(condb)

#excel_sheets("LTE_records_database.xlsx")

for (x in excel_sheets("LTE_records_database.xlsx")){
  temp <- readxl::read_xlsx("LTE_records_database.xlsx",
                            sheet = x)
  assign(x, temp)
  send2sqlite(condb, x)
  rm(temp)
}

