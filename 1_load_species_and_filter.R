#Setup the environment
#Load packages
pacman::p_load(tidyverse,
               foreach,
               taxize,
               rscopus,
               microdemic,
               easyPubMed,
               rentrez)

#TBE and Tank-bromeliad genera
genus <- readRDS("genus.rds")

#Filter epilist by families with TBE species
lista_sp <- read_delim(
  "EpiList Final revised.csv",
  delim = ";",
  escape_double = FALSE,
  trim_ws = TRUE
) %>%
  filter(coalesce(Hemi != "H", TRUE)) %>%
  filter(Genus %in% genus) %>%
  pull(., "Species") %>% as.list()

saveRDS(lista_sp, "lista_sp.rds")
