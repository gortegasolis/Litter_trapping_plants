pacman::p_load(dplyr, stm)

best_k <- rep(list(to_stm), 5) %>%
  lapply(., function(x) {
    searchK(x[["documents"]], x[["vocab"]], cores = 20, K = seq(10, 100, 5))
  })
saveRDS(best_k, "best_k.rds")
