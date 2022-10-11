# Run topic model
pacman::p_load(
  stm,
  tidyverse,
  tidytext,
  stopwords,
  parallel,
  doRNG,
  rstudioapi,
  textcat,
  translateR,
  lingtypology,
  lookup,
  googleLanguageR,
  WorldFlora,
  stringi,
  spelling
)

gl_auth("~/google_json/google_apis.json")

#Re-import dataset after manual check and cleaning
clean_data  <- readxl::read_excel("doc_per_topic.xlsx",
                                  sheet = "Articles")

#Correct spelling
med_dict <- read_csv("en_med_glut.csv")
chem_dict <- read_csv("T201807CHEM SUBS.CSV",
                      col_types = cols_only(NAME = col_guess())) %>% str_split(., " ", simplify = T) %>% t() %>% as.list() %>%
  lapply(., function(x)
    gsub("c\\(", "", x = x)) %>%
  lapply(., function(x)
    gsub("([-])|[[:punct:]]", "", x = x))

dictionary <- qdapDictionaries::GradyAugmented %>%
  c(., unlist(rm_species)) %>%
  c(., med_dict) %>%
  c(., unlist(chem_dict)) %>% as.character() %>% unique() %>%
  tolower() %>% stri_enc_toutf8()

pos_misspelled <-
  mclapply(clean_data$Abstracts, function(x)
    qdap::which_misspelled(x, dictionary = dictionary), mc.cores = 30)

pos_mispelled <-
  pos_misspelled %>% unlist() %>% unique() %>% as.data.frame()
write_csv(pos_mispelled, "mispelled.csv")

## Mispelled words were reviewed outside R
#Re-import mispelled words
pos_mispelled <- readxl::read_excel("doc_per_topic.xlsx",
                                    sheet = "pos_mispelled") %>%
  filter(isFALSE(is_equal) == T)

#Replace mispelled words
clean_data$clean_text <- mclapply(clean_data$clean_text,
                                  function(x)
                                    qdap::mgsub(
                                      pattern = tolower(pos_mispelled$original),
                                      replacement = tolower(pos_mispelled$replacement),
                                      text.var = x
                                    ), mc.cores = 30)

#Create lists of families, genus, and species to remove from texts
WFO.download()
names(WFO.data)
View(head(WFO.data))

rm_species <-
  WFO.data %>%
  select(family, genus, specificEpithet) %>%
  pivot_longer(cols = 1:3) %>% unique() %>% na.omit() %>% pull("value") %>% as.list()

rm_species2 <-
  read_delim(
    "EpiList Final revised.csv",
    delim = ";",
    escape_double = FALSE,
    col_types = cols_only(
      Family = col_character(),
      Genus = col_character(),
      Epithet = col_character()
    ),
    locale = locale(asciify = TRUE),
    trim_ws = TRUE
  ) %>%
  pivot_longer(cols = 1:3) %>% unique() %>% na.omit() %>% pull("value") %>% as.list()

rm_species <-
  c(rm_species, rm_species2) %>% unique() %>%
  stringi::stri_trans_general(., id = "Latin-ASCII") %>%
  iconv(., from = "UTF-8", to = "ASCII//TRANSLIT") %>%
  as.list() %>% split(letters[1:10])

rm(rm_species2)
rm(WFO.data)

#Function to remove species from texts
clean_text_fn <- function(list) {
  mclapply(clean_data$clean_text, function(x) {
    temp <- qdap::mgsub(c("\\(", "\\)", "[[:punct:]]"),
                        c(" ", " ", " "), x)
    res <- qdap::mgsub(tolower(list) %>% paste0(" ", ., " "),
                       rep(" ", length(list)),
                       temp)
    return(res)
  }, mc.cores = 30)
}

#Removing species from texts
clean_data$clean_text <- clean_text_fn(rm_species$a)
clean_data$clean_text <- clean_text_fn(rm_species$b)
clean_data$clean_text <- clean_text_fn(rm_species$c)
clean_data$clean_text <- clean_text_fn(rm_species$d)
clean_data$clean_text <- clean_text_fn(rm_species$e)
clean_data$clean_text <- clean_text_fn(rm_species$f)
clean_data$clean_text <- clean_text_fn(rm_species$g)
clean_data$clean_text <- clean_text_fn(rm_species$h)
clean_data$clean_text <- clean_text_fn(rm_species$i)
clean_data$clean_text <- clean_text_fn(rm_species$j)

#Translate non-english texts
# clean_data$clean_text <-
#   mclapply(clean_data$clean_text, function(x) {
#     x <- as.character(x)
#     lang <- textcat(x)
#     if(is.na(lang) == T){lang <- "en"}else{lang}
#     if(lang == "english"){x}else{gl_translate(x) %>%
#         select(translatedText) %>% as.character()}
#   }, mc.cores = 30)

#Process articles data frame before modeling with STM
clean_data$index <-
  row.names(clean_data)
index <-
  clean_data %>% select(index) %>% as.data.frame()#To pass error in textProcessor

texts <-
  textProcessor(
    clean_data$clean_text,
    metadata = index,
    stem = F,
    ucp = T,
    striphtml = T,
    customstopwords = c("abstract", "summary", "title", "methods")
  )

to_stm <-
  prepDocuments(
    documents = texts$documents,
    vocab = texts$vocab,
    meta = texts$meta,
    lower.thresh = 10,
    upper.thresh = 0.9 * length(texts$documents)
  )

to_stm$meta <-
  to_stm$meta %>% left_join(., clean_data, by = "index")

#Search the best K (number of topics)
jobRunScript("background_best_k.R",
             importEnv = T,
             exportEnv = T)

foreach(x = best_k, .combine = "rbind") %do% {
  x[["results"]]
} %>%
  mutate(across(.cols = 2:7, function(x)
    scales::rescale(as.numeric(x), to = c(0, 1)))) %>%
  select(!em.its) %>% pivot_longer(., 2:7) %>%
  ggplot(aes(
    x = as.numeric(K),
    y = value,
    colour = name,
    linetype = name
  )) +
  geom_point() +
  stat_summary(geom = "line", fun = "median")

#Run the model with the chosen K
stm_model <- stm(
  to_stm$documents,
  to_stm$vocab,
  prevalence = ~ LTE_term + soil_term + interact_term + abundance_term + medic_term + lab_term + genetic_term + mycorrh_term +
    physiol_term + agric_term + pollinat_term,
  data = to_stm$meta,
  K = 50
)

#Evaluate results
doc_per_topic <-
  tidy(stm_model, "gamma") %>% group_by(document) %>% slice_max(gamma, n = 1) %>%
  mutate(document = as.character(document)) %>%
  left_join(., select(clean_data, 3:20, 22, 23, 26),
            by = c("document" = "index"))

doc_per_topic <- tidy(stm_model) %>% group_by(topic) %>%
  slice_max(beta, n = 10) %>% aggregate(term ~ topic, data = ., paste, collapse =
                                          " ") %>%
  ungroup() %>% rename(`Important words per topic` = term) %>% left_join(doc_per_topic, ., by = "topic")

openxlsx::write.xlsx(doc_per_topic, "to_manual_selection.xlsx")
