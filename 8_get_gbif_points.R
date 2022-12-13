# Get TBE-TB occurrences from GBIF
system("mkdir GBIF")

# Get usage keys for old and updated species names
usagekeys <- dbGetQuery(
  condb,
  "SELECT DISTINCT `spec.name`,scientificName FROM tbl_TBE_TB_updated"
) %>%
  pivot_longer(cols = everything()) %>%
  select(value) %>%
  mutate(value = str_squish((value))) %>%
  filter(., grepl("\\s", x = value)) %>%
  unique() %>%
  name_backbone_checklist() %>%
  filter(rank == "SPECIES")

#Download data
tmp_gbif <- occ_download(
  pred_in("taxonKey", unique(usagekeys$usageKey)),
  pred("hasGeospatialIssue", FALSE),#Remove points with geospatial issues
  pred("hasCoordinate", TRUE),#Ensure points with coordinates
  pred("occurrenceStatus", "PRESENT"),#Avoid absent records
  pred_not(pred_in("basisOfRecord", c("FOSSIL_SPECIMEN", "LIVING_SPECIMEN"))),#Avoid fossil and zoo records.
  format = "SIMPLE_CSV"
)

occ_download_wait(tmp_gbif)#Check operation status

occ_download_get(tmp_gbif, path = "GBIF/")#Download data if ready

#Import and clean data
source("func_GBIF_clean_pipeline.R")
gbif_points <- clean_gbif(import = "GBIF/0193282-220831081235567.zip",
                          polygons_lst = powo_dist)

#Double check flagged points in tmap
tmp_bad <- gbif_points %>% filter(.summary == F)

tmap_mode("view") #Easy interactive view
tmap_options(max.categories = length(unique(tmp_bad$scientificName)))

tm_shape(tmp_bad) +
  tm_symbols(col = "scientificName")

View(tmp_bad)

#Clean dataset
gbif_clean <- gbif_points %>%
  filter(!.summary == F) %>%
  select(!starts_with(".")) %>%
  group_by(scientificName) %>%
  summarise()

#Intersect with WWF ecoregions
sp_ecoregion <- readRDS("wwf_completo.rds") %>%
  st_as_sf() %>%
  st_intersection(gbif_clean)

st_drop_geometry(sp_ecoregion) %>% View()

#Check richness per Ecoregion
st_drop_geometry(sp_ecoregion) %>%
  select(ECO_NAME,scientificName) %>%
  unique() %>%
  group_by(ECO_NAME) %>%
  summarise(Richness = n()) %>% View()
