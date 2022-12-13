# Join TDWG regions
dbListFields(condb, "tbl_TBE_TB_updated")

updated_sp <- dbGetQuery(
  condb,
  "SELECT DISTINCT `spec.name`,scientificName FROM tbl_TBE_TB_updated"
) %>%
  pivot_longer(cols = everything()) %>%
  pull(value) %>%
  unique()

powo_taxon <- read_delim("POWO/wcvp_taxon.csv",
                         delim = "|",
                         escape_double = FALSE,
                         trim_ws = TRUE
) %>%
  filter(scientfiicname %in% updated_sp)

powo_taxon <- dbGetQuery(
  condb,
  "SELECT DISTINCT `spec.name`,scientificName FROM tbl_TBE_TB_updated
  UNION SELECT DISTINCT scientificName,scientificName FROM tbl_TBE_TB_updated"
) %>%
  unique() %>%
  left_join(powo_taxon, ., by = c("scientfiicname" = "spec.name")) %>%
  relocate(scientificName, .after = scientfiicname)

tdwg_l3 <- rgdal::readOGR("wgsrpd-master/level3/") %>%
  st_as_sf()

names(tdwg_l3)

powo_dist <- read_delim("POWO/wcvp_distribution.csv",
                        delim = "|",
                        escape_double = FALSE,
                        trim_ws = TRUE
) %>%
  filter(coreid %in% unique(powo_taxon$taxonid)) %>%
  mutate(locationid = gsub(x = locationid, "TDWG:", "")) %>%
  select(coreid, locationid) %>%
  left_join(powo_taxon, ., by = c("taxonid" = "coreid")) %>%
  left_join(tdwg_l3, ., by = c("LEVEL3_COD" = "locationid"))
