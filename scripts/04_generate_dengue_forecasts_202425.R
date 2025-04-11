# ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
# Description:
#     Produce the dengue forecasts per health region per epidemiological week
#     and convert to per state per epidemiological week across Brazil for period
#     Epiweek 41 2024 - Epiweek40 2025

#     This script should be run in a bash loop

# Script authors:
#     Chloe Fletcher        (chloe.fletcher@bsc.es)
#     Dr Giovenale Moirano  (giovenale.moirano@bsc.es)
#     Prof. Rachel Lowe     (rachel.lowe@bsc.es)

# ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
## 1) Bash configuration
# ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
# Get command-line arguments
args <- commandArgs(trailingOnly = TRUE)

# Check if an argument was provided
if (length(args) == 0) {
  stop("At least one argument must be supplied (input number).", call. = FALSE)
}

# Convert the first argument to a numeric variable and a character variable
e <- as.numeric(args[1])
e_txt <- ifelse(nchar(e) == 1, paste0("0", e), e)

# Print progress update
print(paste("The input number is:", e))

# ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
## 2) Source packages, functions and data
# ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
# Load packages and functions
packages <- c("INLA", "dplyr","sf","stringr","glue")
lapply(packages, library, character.only = TRUE)
source("functions/functions.R")

# Read in posterior samples
posterior <- readRDS(glue("data/forecast_data/fit_{e_txt}.RDS"))

# Read in ensemble data (only using for epi week and state index)
data <- read.csv(glue("data/forecast_data/forecast_ensemble_{e_txt}.csv"))
data <- data[data$epiweek > 202440, ]

# Print progress update
print("Packages, functions and data loaded correctly")

# ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
## 3) Generate posterior predictive distribution
# ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
# Define number of predictions, samples, latent and overdispersion parameter
n_pred <- nrow(data)
s <- 1000
theta <- posterior[1, ]
latent <- posterior[2:nrow(posterior), ]

# Generate posterior predictive distribution from negative binomial distribution
y_pred <- matrix(NA, n_pred, s)
for (v in 1:s) {
  posterior_xx <- latent[, v]
  y_pred[, v] <- rnbinom(n_pred, mu = exp(posterior_xx), size = theta[1, v])
}

# Print progress update
print(glue("Posterior predictive distribution generated for ensemble member {e}"))

# ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
## 4) Summarise results by state
# ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
# Convert to dataframe
y_pred <- as.data.frame(y_pred)

# Append columns for state index and epidemiological week
y_pred$uf_id <- data$uf_id
y_pred$epiweek <- data$epiweek

# Summarise predictions from health region to state level
y_pred <- y_pred %>% group_by(uf_id, epiweek) %>%
  summarise(across(everything(), \(x) sum(x, na.rm = TRUE)))

# Store posterior predictive distribution per ensemble member
write.csv(y_pred, glue("outputs/preds/preds_{e_txt}.csv"), row.names=FALSE)

# Print progress update
print(glue("Posterior predictive for ensemble member {e} stored as .csv file"))

# ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
## END
# ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''