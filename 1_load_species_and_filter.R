# Filter epilist by families with TBE species
dbListTables(condb)
dbListFields(condb, "tbl_Initial_species_list")

lista_sp <- function() {
  dbGetQuery(
    condb,
    "SELECT * FROM tbl_Initial_species_list"
  )
}

lista_sp() %>%
  select(Genus, Epithet) %>%
  glimpse()
