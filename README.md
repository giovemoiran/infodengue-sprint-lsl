# Authors
- Giovenale Moirano: [link](https://www.bsc.es/moirano-giovenale)
- Chloe Fletcher: [link](https://www.bsc.es/fletcher-chloe)
- Raúl Capellán: [link](https://www.bsc.es/ca/capellan-fernandez-raul)
- Daniela Lührsen: [link](https://www.bsc.es/es/luhrsen-daniela-sofie)
- Rachel Lowe: [link](https://www.bsc.es/lowe-rachel)


# LSL model for the infodengue sprint
This repository contains the final model used to forecast dengue cases for the InfoDengue sprint. The InfoDengue sprint was a model challenge organized by the Mosqlimate project [Sprint Repository](https://github.com/Mosqlimate-project/sprint-template/tree/main). During 2024, dengue spread to southern regions of Brazil and to higher altitudes where epidemics had not previously been recorded. The incidence rate far exceeded that of previous years. The objective of this sprint was to promote, in a standardized way, the training of predictive models with the aim of developing an ensemble forecast for dengue in Brazil. The challenge required modelers to predict weekly dengue cases at the state level (27 units) for two epidemiological years:

- Validation Test 1: 2022–2023
- Validation Test 2: 2023–2024

An epidemiological year was defined as the period spanning from epidemiological week 41 (the first week of October) to epidemiological week 40 (the last week of September) of the following year.

# Model 
We adopted a a Bayesian spatio-temporal modelling framework using R-INLA (see model_fit_and_prediction.R). We fit a spatio-temporal model that includes three sets of random effects:

-  A conditional autoregressive (“bym2”) spatial random effects for the brazilian health regions  (i = 1,…,450).
-  A random walk 2 weekly random effects for the week of the year (t), replicated by the 27 Brazilian states.  
-  A random walk 1 yearly random effect for the year (j) replicated by the 5 Brazilian Macroregion.

The submitted model includes the following covariates:

- A 3-month moving average of monthly mean temperatures at the health region level (ERA5-Land), measured three months before the outcome.
- The Standardized Precipitation Index (SPI1), measured one month before the outcome.
- The Standardized Precipitation Index (SPI12), measured five months before the outcome.

The three meteorological parameters are included in the model with an interaction term among them.

# Results
From the fitted model, we generated 1,000 samples from the posterior predictive distribution at the Brazilian health region level. These posterior samples were then aggregated at the state level and summarized using the 5th, 50th, and 95th percentiles.

Predicted Cases for Test Year 1: ![alt text](https://github.com/giovemoiran/infodengue-sprint-lsl/blob/main/test1_post_pred.tiff)

# Results from the challenge 
Model performance compared to other models submitted for the challenge is available at the following  [link](https://github.com/Mosqlimate-project/sprint-template/blob/main/scores/scores.md)

