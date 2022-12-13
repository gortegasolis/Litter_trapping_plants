# GBIF data cleaning pipeline (One function to rule them all, One function to find them...”)

clean_gbif <- function(import = NA, polygons_lst) {
  gbif_data <- occ_download_import(as.download(import)) %>% #Import GBIF file
    select(
      species, decimalLongitude, decimalLatitude, countryCode,
      gbifID, family, taxonRank #Select variables to keep
    ) %>%
    mutate(countryCode = countrycode::countrycode(countryCode, origin = "iso2c", destination = "iso3c")) #Change country codes from ISO2 to ISO3

  gbif_data <- dbGetQuery(
    condb,
    "SELECT DISTINCT `spec.name`,scientificName FROM tbl_TBE_TB_updated
  UNION SELECT DISTINCT scientificName,scientificName FROM tbl_TBE_TB_updated"
  ) %>% #Import species names
    unique() %>%
    left_join(gbif_data, ., by = c("species" = "spec.name")) %>%
    relocate(scientificName, .after = species) %>%
    clean_coordinates(.,#Flag dubious points
                      lon = "decimalLongitude",
                      lat = "decimalLatitude",
                      countries = "countryCode",
                      species = "scientificName",
                      tests = c(
                        "capitals", "centroids", "equal", "gbif", "institutions",
                        "zeros", "countries"
                      )
    ) %>%
    st_as_sf(., coords = c("decimalLongitude", "decimalLatitude")) %>%
    select(scientificName, family, starts_with("."))

  #Set crs
  st_crs(gbif_data) <- 4326

  #Reproject to polygons crs
  gbif_data <- st_transform(gbif_data,st_crs(polygons_lst))

  #Remove points outside native ranges
  gbif_data <- mclapply(unique(gbif_data$scientificName), function(x) {
    gbif_filtered <- filter(gbif_data, scientificName == x) %>%
      st_make_valid()
    polygons_filtered <- filter(polygons_lst, scientificName == x)
    res <- st_filter(gbif_filtered, polygons_filtered)
    if (NROW(res) > 0) {
      return(res)
    }
  }, mc.cores = 20) %>% data.table::rbindlist(fill = T) %>%
    st_as_sf(., sf_column_name = "geometry") %>%
    select(scientificName, family, starts_with("."))

  #Re-set crs
  st_crs(gbif_data) <- st_crs(polygons_lst)

  return(gbif_data)
}
