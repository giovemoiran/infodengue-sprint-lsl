# ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
# Description:
#     Combine posterior predictive distributions for all ensemble members and
#     evaluate dengue risk at the state level (incl. median, 5/95th percentiles)
#     for period Epiweek 41 2024 - Epiweek40 2025

# Script authors:
#     Chloe Fletcher        (chloe.fletcher@bsc.es)
#     Dr Giovenale Moirano  (giovenale.moirano@bsc.es)
#     Prof. Rachel Lowe     (rachel.lowe@bsc.es)

# ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
## 1) Source packages and functions
# ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
# Load packages and functions
packages <- c("INLA", "dplyr","sf","stringr","glue")
lapply(packages, library, character.only = TRUE)
source("functions/functions.R")

# Define number of samples and number of ensembles
s <- 1000
n_ens <- 51

# ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
## 2) Merge posterior predictive distributions across all ensemble members
# ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
# Initialise object
pred <- NULL

# Read in y_pred and assemble in pred
for (e in 1:n_ens){
  e_txt <- ifelse(nchar(e) == 1, paste0("0", e), e)
  y_pred <- read.csv(glue("outputs/preds/preds_{e_txt}.csv"))
  
  if (e == 1){
    pred <- y_pred
  } else {
    pred <- cbind(pred, y_pred[ , -c(1:2)])
  }
}

# Avoid repeated column names from the concatenation
colnames(pred)[3:length(pred)] <- paste0("V", 1:(n_ens * s))

# Save full posterior predictive distribution
write.csv(pred, "outputs/preds/preds_all.csv", row.names=FALSE)

# ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
## 3) Evaluate predicted cases (median, 5/95th percentiles)
# ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
# Read in full posterior predictive distribution
# pred <- read.csv("outputs/preds/preds_all.csv")

pred_eval <- pred %>%
  # Ensure that operations are done row by row
  rowwise() %>%
  # For each row, calculate median, 5th percentile, and 95th percentile
  mutate(
    median = median(c_across(-c(uf_id, epiweek)), na.rm = TRUE),
    p5 = quantile(c_across(-c(uf_id, epiweek)), probs = 0.05, na.rm = TRUE),
    p95 = quantile(c_across(-c(uf_id, epiweek)), probs = 0.95, na.rm = TRUE)
  ) %>% select(median, p5, p95, uf_id, epiweek)

# Save median and 5/95th percentiles for predicted dengue cases
write.csv(pred_eval, "outputs/preds/pred_eval_orig.csv", row.names=FALSE)

# ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
## 4) Format evaluations of predicted cases for submission
# ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
# Read in any forecast ensemble dataset to extract state index and epi weeks
data <- read.csv("data/forecast_data/forecast_ensemble_01.csv")
ufs <- unique(data[ , c("uf", "uf_id")])

# Merge state index into evaluations
pred_eval <- merge(pred_eval, ufs, by="uf_id", all.x=TRUE)
pred_eval <- pred_eval[ , -1]

# Merge epidemiological week into evaluations
dates <- unique(data[ , c("epiweek", "date")])
pred_eval <- merge(pred_eval, dates, by = "epiweek", all.x = TRUE)
pred_eval <- pred_eval[ , -1]

# Update column names for submission
colnames(pred_eval) <- c("preds", "lower", "upper", "adm_1", "dates")
pred_eval <- pred_eval %>% select(dates, preds, lower, upper, adm_1)
write.csv(pred_eval, "outputs/preds/pred_eval.csv", row.names=FALSE)

# Create separate dataframe for each state for submission
for (state in unique(ufs$uf)){
  pred_eval_s <- pred_eval[pred_eval$uf == state, ]
  write.csv(pred_eval, glue("outputs/preds/pred_{state}.csv"), row.names=FALSE)
}

# ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
## END
# ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''