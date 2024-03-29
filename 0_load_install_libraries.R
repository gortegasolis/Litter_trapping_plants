# Setup the environment
# Load packages
pacman::p_load(
  foreach,
  taxize,
  rscopus,
  microdemic,
  easyPubMed,
  rentrez,
  RSQLite,
  stringi,
  WorldFlora,
  sf,
  rgbif,
  CoordinateCleaner,
  parallel
)

pacman::p_load(tidyverse)

# Function to keep a lightweight workspace
send2sqlite <- function(con, dataframe, tables = F) {
  RSQLite::dbWriteTable(
    conn = con,
    name = paste0("tbl_", dataframe),
    value = get(dataframe),
    overwrite = T
  )
  rm(
    list = dataframe,
    envir = .GlobalEnv
  )
  if (tables == T) {
    dbListTables(con)
  }
}

# Connect database
condb <- dbConnect(RSQLite::SQLite(), "LTEp.sqlite")
dbGetInfo(condb)
# dbDisconnect(condb)

readxl::excel_sheets("LTE_records_database.xlsx")

# for (x in readxl::excel_sheets("LTE_records_database.xlsx")){
#   temp <- readxl::read_xlsx("LTE_records_database.xlsx",
#                             sheet = x)
#   assign(x, temp)
#   send2sqlite(condb, x)
#   rm(temp)
# }

# Dirty fix for problems with new spherical geometry in sf
sf_use_s2(FALSE)
