# I KEPT THIS SCRIPT AS A REFERENCE
# MICROSOFT ACADEMIC CLOSED IN 2021, NOW YOU CAN GET THE SAME DATA FROM SEMANTICSCHOLAR

# Download data from Microsoft Academic
pacman::p_load(microdemic, foreach, doFuture, tidyverse, fuzzySim, doRNG)

# Set future for background processes
registerDoFuture()
workers <- parallel::detectCores() - 1
plan(multisession, workers = workers)

temp <- lista_sp()
macademic_df <- foreach(
  sp = 1:length(temp),
  .errorhandling = "remove"
) %do% {
  sp <- tolower(temp[[sp]])
  query <- paste0(
    "OR(AND(Ti=='",
    word(sp),
    "', Ti=='",
    word(sp, 2),
    "'),AND(AW=='",
    word(sp),
    "', AW=='",
    word(sp, 2),
    "'),AND(Ti=='",
    word(sp),
    "', AW=='",
    word(sp, 2),
    "'))"
  )
  res <- ma_search(query,
    count = 5000,
    key = sample(key_macademic)
  )
  Sys.sleep(1)
  return(res)
}
rm(temp)

macademic_df <- data.table::rbindlist(macademic_df, fill = T)

macademic_df <-
  macademic_df %>%
  select(Id, Ti, Y, J.JN) %>%
  unique()

colnames(macademic_df) <- c("MAID", "Title", "Year", "Journal")

# Get abstracts
ma_abstract <-
  paste0("Id=", macademic_df$MAID) %>% lapply(., function(x) {
    ma_abstract(x)
  })

# Merge article search and abstracts
macademic_df <-
  data.table::rbindlist(ma_abstract) %>%
  mutate(Id = as.character(Id)) %>%
  left_join(macademic_df, ., by = c("MAID" = "Id"))

macademic_df <- macademic_df %>% mutate(across(.fns = tolower))

colnames(macademic_df) <- c("MAID", "Title", "Year", "Journal", "Abstract")

# Backup
saveRDS(ma_abstract, "ma_abstract.rds")
saveRDS(macademic_df, "macademic_df.rds")

# Convert to international encoding
macademic_df$Title <-
  iconv(macademic_df$Title, from = "UTF-8", to = "ASCII//TRANSLIT")

# Send results to database
send2sqlite(condb, "macademic_df", tables = T)

# Replace with an SQL query
macademic_df <- function() {
  dbSendQuery(
    condb,
    "SELECT * FROM tbl_macademic_df"
  ) %>%
    dbFetch()
}

macademic_df() %>% glimpse()
