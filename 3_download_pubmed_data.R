# Download data from Pubmed
pacman::p_load(easyPubMed, foreach, doFuture, tidyverse, fuzzySim, doRNG)

lista_sp() %>%
  pull(Species) %>%
  foreach(
    sp = .,
    .errorhandling = "pass"
  ) %do% {
    query <- tolower(sp) %>%
      gsub(" ", '"[TIAB] AND "', .) %>%
      paste0('"', ., '"[TIAB]')

    res <- batch_pubmed_download(
      query,
      dest_dir = "pubmed_files",
      api_key = key_pubmed,
      dest_file_prefix = sp
    )
    return(res)
  }

# #Import pubmed results
pubmed_files <-
  list.files(
    path = "pubmed_files",
    pattern = "*.txt",
    full.names = T
  )

pubmed_df <-
  foreach(file = pubmed_files, .combine = "rbind") %do% {
    df <- articles_to_list(file) %>% article_to_df()
    return(df)
  }

pubmed_df <- pubmed_df %>%
  select(pmid, doi, title, abstract, year, journal) %>%
  unique()

colnames(pubmed_df) <-
  c("PMID", "DOI", "Title", "Abstract", "Year", "Journal")

pubmed_df <- pubmed_df %>% mutate(across(.fns = tolower))

# Convert to international encoding
pubmed_df$Title <-
  iconv(pubmed_df$Title, from = "UTF-8", to = "ASCII//TRANSLIT")

# Send results to database
send2sqlite(condb, "pubmed_df", tables = T)

# Replace with an SQL query
pubmed_df <- function() {
<<<<<<< HEAD
  dbGetQuery(
    condb,
    "SELECT * FROM tbl_pubmed_df"
  )
=======
  dbSendQuery(
    condb,
    "SELECT * FROM tbl_pubmed_df"
  ) %>%
    dbFetch()
>>>>>>> 445e7adbb0199fa17b2e33daea61c06df6d18502
}

pubmed_df() %>% glimpse()
