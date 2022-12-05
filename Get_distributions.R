#Get TBE-TB occurrences from GBIF
system("mkdir GBIF")

usagekeys <- dbGetQuery(condb,
                         "SELECT DISTINCT `spec.name`,scientificName FROM tbl_TBE_TB_updated") %>%
  pivot_longer(cols = everything()) %>%
  select(value) %>%
  mutate(value = str_squish((value))) %>%
  filter(., grepl("\\s",x = value)) %>%
  unique() %>%
  name_backbone_checklist() %>%
  filter(rank == "SPECIES")

tmp_gbif <- occ_download(
  pred_in("taxonKey", unique(usagekeys$usageKey)),
  pred("hasGeospatialIssue", FALSE),
  pred("hasCoordinate", TRUE),
  pred("occurrenceStatus","PRESENT"),
  pred_not(pred_in("basisOfRecord",c("FOSSIL_SPECIMEN","LIVING_SPECIMEN"))),
  format = "SIMPLE_CSV"
)

occ_download_wait(tmp_gbif)

occ_download_get(tmp_gbif, path = "GBIF/")

gbif_data <- occ_download_import(as.download("GBIF/0193282-220831081235567.zip"))
