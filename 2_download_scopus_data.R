# Download data from Scopus
pacman::p_load(rscopus,
               foreach,
               doFuture,
               tidyverse,
               fuzzySim,
               doRNG,
               microdemic)

scopus_df <- foreach(sp = lista_sp(),
                     .errorhandling = "pass") %do% {
                       query <-
                         tolower(sp) %>% gsub(" ", '} AND {', .) %>% paste0('TITLE-ABS-KEY({',
                                                                            .,
                                                                            '}) AND SUBJAREA(AGRI)')

                       Sys.sleep(0.2)

                       res <- scopus_search(
                         query,
                         api_key = key_scopus,
                         view = "STANDARD",
                         wait_time = 1,
                         count = 25
                       )
                       res <- gen_entries_to_df(res$entries)
                       return(res)
                     }

saveRDS(scopus_df, file = "scopus_df.rds")

scopus_df <- foreach(df = scopus_df) %do% {
  if (is.data.frame(df) == T) {
    return(df)
  }
} %>% data.table::rbindlist(., fill = T)

scopus_df <-
  scopus_df %>% select(
    `dc:identifier`,
    `prism:doi`,
    `dc:title`,
    `prism:coverDate`,
    `prism:publicationName`
  ) %>%
  unique()

colnames(scopus_df) <-
  c("SCOPID", "DOI", "Title", "Year", "Journal")

#CORRER DESDE AQUÍ
#Get abstracts for scopus
temp_doi_list <- unique(scopus_df$DOI)

#Get abstracts
scop_abstract <-
  paste0("DOI='", toupper(temp_doi_list), "'") %>% lapply(., function(x)
    ma_abstract(x))

saveRDS(scop_abstract,"scop_abstract.rds")

scop_abstract <-
  foreach(n = 1:length(temp_doi_list)) %do% {
    if (NCOL(scop_abstract[[n]]) > 1) {
      df <-
        scop_abstract[[n]]
      df$DOI <- temp_doi_list[[n]]
      return(df)
    }
  } %>% data.table::rbindlist()


scopus_df <- left_join(scopus_df, scop_abstract, by = "DOI")

rm(scop_abstract)

scopus_df <- scopus_df %>% mutate(across(.fns = tolower))

colnames(scopus_df) <-
  c("SCOPID", "DOI", "Title", "Year", "Journal", "MAID", "Abstract")

#Send results to database
send2sqlite(condb, "scopus_df", tables = T)

#Replace with an SQL query
scopus_df <- function(){dbSendQuery(condb,
                                   "SELECT *
                        FROM tbl_scopus_df") %>%
    dbFetch()}

scopus_df() %>% glimpse()
