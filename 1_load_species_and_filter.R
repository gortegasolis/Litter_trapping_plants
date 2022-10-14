# Filter epilist by families with TBE species
dbListTables(condb)
dbListFields(condb, "tbl_Initial_species_list")

lista_sp <- function() {
<<<<<<< HEAD
  dbGetQuery(
    condb,
    "SELECT * FROM tbl_Initial_species_list"
  )
=======
  dbSendQuery(
    condb,
    "SELECT * FROM tbl_Initial_species_list"
  ) %>%
    dbFetch()
>>>>>>> 445e7adbb0199fa17b2e33daea61c06df6d18502
}

lista_sp() %>%
  select(Genus, Epithet) %>%
  glimpse()
