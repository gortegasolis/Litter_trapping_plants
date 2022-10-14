dbListTables(condb)

#Create a view for earthengine
# dbExecute(condb, "CREATE VIEW [vw_eengine_biodiv] AS
# SELECT Reference, LAT, LONG FROM tbl_Biodiv_inhab_LTE_TB
# WHERE LAT != 'Unknown'")

ee_df <- function(){dbGetQuery(condb, "SELECT * FROM vw_eengine_biodiv")}

ee_df() %>% glimpse()

#Setup earthengine client
