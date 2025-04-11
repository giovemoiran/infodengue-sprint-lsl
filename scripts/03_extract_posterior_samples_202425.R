# ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
# Description:
#     Extract 1000 posterior samples for each climate forecast ensemble member 
#     for dengue model at the health region level per epidemiological week
#     for period Epiweek 41 2024 - Epiweek40 2025

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
## 2) Source packages and functions
# ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
# Load packages and functions
packages <- c("INLA", "dplyr","sf","stringr","glue")
lapply(packages, library, character.only = TRUE)
source("functions/functions.R")

# Read in shapefile
shp <- read_sf("data/shp/BR_Regionais.shp")
shp <- shp %>% arrange(reg_id)

# Print progress update
print("Packages, functions and shapefiles loaded correctly")

# ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
## 3) Format observed and forecast climate data
# ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
# Read in ew 41 2024 to ew 40 2025 data per ensemble member
data_fc <- read.csv(glue("data/forecast_data/forecast_ensemble_{e_txt}.csv"))
colnames(data_fc)

# Read in updated observed data up to ew 40 2024
data_ob <- read.csv("data/data_updated.csv")
colnames(data_ob)

# Format observed data for inla in line with forecast data
data_ob <- data_ob %>%
  mutate(week_id = as.numeric(substr(epiweek, 5, 6)),
         week_id = ifelse(week_id == 53, 52, week_id),
         year_id = as.numeric(factor(epi_year)), 
         regional_id = as.numeric(factor(regional_geocode)), 
         macro_id = as.numeric(substr(regional_geocode, 1, 1)),
         uf_id = as.numeric(factor(uf)), 
         uf_id2 =  as.numeric(factor(uf))) %>%
  select(colnames(data_fc))

# Remove ew 202432 from the dataset
data_ob <- data_ob[data_ob$epiweek < 202432, ]
row.names(data_ob) <- NULL

# Merge datasets
data <- rbind(data_ob, data_fc)
data <- data[with(data, order(epiweek, regional_geocode)), ]

# Print progress update
print("Observed and forecast data formatted correctly")

# ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
## 4) Run INLA model
# ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
# Set up variables
g <- inla.read.graph("data/shp/map.graph")
precision.prior <- list(prec = list(prior = "pc.prec", param = c(0.5, 0.01)))
vars <- c("temp3_med_m_lag_3", "spi12_m_lag_5", "spi1_m_lag_1")

# Set up random effects
re1 <- paste("f(week_id, replicate = uf_id, model = 'rw2', cyclic = TRUE,",
             "constr = TRUE, scale.model = TRUE, hyper = precision.prior)")
re2 <- paste("f(year_id, replicate = macro_id, model = 'rw1', hyper = precision.prior)")
re3 <- paste("f(regional_id, model = 'bym2', graph = g, scale.model = TRUE,",
             "hyper = precision.prior)")

# Best formula
form <- paste(c("casos ~ 1", re1, re2, re3, paste(vars, collapse=' * ')),
              collapse=' + ')

# Run model
model <- runinlamod(formula(form), data, config=TRUE)

# Print progress update
print("INLA model complete")

# ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
## 5) Extract posterior samples
# ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
# Define number of samples
s <- 1000

# Extract all posterior samples
sam <- inla.posterior.sample(s, model)

# Print progress update
print("Posterior samples extracted")

# ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
## 6) Posterior samples for overdispersion parameter and distribution means
# ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
# Create empty dataframe for posterior samples
r <- max(data$regional_id) * 52 + 1
posterior <- data.frame(array(dim = c(r, s)))

# Extract overdispersion parameter and distribution means per sample
for (v in 1:s){
  posterior[1, v] <- sam[[v]]$hyperpar[[1]]
  posterior[2:nrow(posterior), v] <- sam[[v]]$latent[(nrow(data) - r):nrow(data)]
}

# Store posterior samples per ensemble member
saveRDS(posterior, glue("data/forecast_data/fit_{e_txt}.rds"))

# Print progress update
print(glue("Posterior samples for ensemble member {e} stored as .rds file"))

# ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
## END
# ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''