# Check and join abstracts
pacman::p_load(microdemic, easyPubMed, tidyverse, parallel, fulltext)

# Join datasets
abs_df
test <-
  full_join(macademic_df(), scopus_df(), by = c("Title", "Year", "Journal")) %>%
  full_join(., pubmed_df(), by = c("Title", "Year", "Journal", "DOI"))

abs_df$MAID <- coalesce(abs_df$MAID.x, abs_df$MAID.y)
abs_df$Abstracts <- coalesce(abs_df$Abstract.x, abs_df$Abstract.y, abs_df$Abstract)

abs_df <- abs_df %>% select(-c("MAID.x", "MAID.y", "Abstract.x", "Abstract.y", "Abstract"))

abs_df <- abs_df %>% drop_na(Abstracts)

# Backup
saveRDS(abs_df, "abs_df.rds")

# Dataset exported as xlsx for manual checking
openxlsx::write.xlsx(abs_df, "abs_df.xlsx")
