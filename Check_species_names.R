#Check species names

#Download data from World Flora
#WFO.download()
#send2sqlite(condb, "WFO.data", tables = T)
gc()

#Update TBE/TB species names
WFO_data <- dbReadTable(condb,'tbl_WFO.data')

tbe_tb <- dbGetQuery(condb, "SELECT DISTINCT TBE_TB_species
                          FROM tbl_Biodiv_inhab_TBE_TB")

TBE_TB_updated <- WFO.prepare(tbe_tb, spec.full = "TBE_TB_species") %>%
  WFO.match(spec.data = ., WFO.data = WFO_data)

rm(WFO_data)
gc()

send2sqlite(condb, "TBE_TB_updated")
gc()

#Update species inhabiting TBE/TB
inhab_sp <- dbGetQuery(condb, "SELECT DISTINCT taxa_reported
                       FROM tbl_Biodiv_inhab_TBE_TB") %>%
  mutate(taxa_reported = gsub(x = taxa_reported,
                               pattern = " II| sp| sp.",
                               replacement = ""))

View(gnr_datasources())

inhab_updated <- lapply(inhab_sp$taxa_reported, function(x){
  res <- gnr_resolve(x, data_source_ids = 3)
  Sys.sleep(1)
  return(res)
}) %>% data.table::rbindlist(fill = T)
