# LSL model for the infodengue sprint
This repository contains the final model used to forecast dengue cases for the InfoDengue sprint. The InfoDengue sprint was a model challenge organized by the Mosqlimate project [Sprint Repository](https://github.com/Mosqlimate-project/sprint-template/tree/main). During 2024, dengue spread to southern regions of Brazil and to higher altitudes where epidemics had not previously been recorded. The incidence rate far exceeded that of previous years. The objective of this sprint was to promote, in a standardized way, the training of predictive models with the aim of developing an ensemble forecast for dengue in Brazil. The challenge required modelers to predict weekly dengue cases at the state level (27 units) for an entire epidemiological year, defined as the period spanning from epidemiological week 41 (the first week of October) to epidemiological week 40 (the last week of September) of the following year.

Participants were asked to train models using data from 2010 to 2021 and submit predictions for model evaluation targeting two epidemiological years:

- Validation Year 1: 2022–2023
- Validation Year 2: 2023–2024

Finally participants were asked to submit their prediction for:

- Target Year: 2024-2025.

# Methods 
We adopted a a Bayesian spatio-temporal modelling framework using R-INLA (see model_fit_and_prediction.R). We fit a spatio-temporal model that includes three sets of random effects:

-  A conditional autoregressive (“bym2”) spatial random effects for the brazilian health regions  (i = 1,…,450).
-  A random walk 2 weekly random effects for the week of the year (t), replicated by the 27 Brazilian states.  
-  A random walk 1 yearly random effect for the year (j) replicated by the 5 Brazilian Macroregion.

The submitted model includes the following covariates:

- A 3-month moving average of monthly mean temperatures at the health region level (ERA5-Land), measured three months before the outcome.
- The Standardized Precipitation Index (SPI1), measured one month before the outcome.
- The Standardized Precipitation Index (SPI12), measured five months before the outcome.
- Two-ways and three-ways interaction terms among the three covariates.

For validation years 2022-23 and 2023-2024 we produced dengue forecasts using observed climatic data. Scripts to reproduce the results submitted for the two validation years can be found in *R/01_generate_dengue_forecasts_202223.R* and in *R/02_generate_dengue_forecasts_202324.R* using the data stored in *data/data.csv*

Dengue forecasts for target year 2024-2025 were based on a combination of observed and forecasted values of climatic variables. Scripts used to produce the forecasts for target year 2024-25 can be found in *R/03_extract_posterior_samples_202425.R*, *R/04_generate_dengue_forecasts_202425.R*, and *R/05_evaluate_dengue_forecasts_202425.R*.
However, for a matter of data storage climate forecasts are not included in the current repository. Data are available upon request to any of the authors.


From the identified model, we generated 1,000 samples from the posterior predictive distribution at the Brazilian health region level. These posterior samples were then aggregated at the state level and summarized using the 5th, 50th, and 95th percentiles.

# Results from the challenge 
Model performance compared to other models submitted for the challenge is available at the following  [link](https://github.com/Mosqlimate-project/sprint-template/blob/main/scores/scores.md)


# Authors
- Giovenale Moirano: [link](https://www.bsc.es/moirano-giovenale)
- Chloe Fletcher: [link](https://www.bsc.es/fletcher-chloe)
- Raúl Capellán: [link](https://www.bsc.es/ca/capellan-fernandez-raul)
- Daniela Lührsen: [link](https://www.bsc.es/es/luhrsen-daniela-sofie)
- Rachel Lowe: [link](https://www.bsc.es/lowe-rachel)

