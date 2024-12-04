# Authors
- Giovenale Moirano: [link](https://www.bsc.es/moirano-giovenale)
- Chloe Fletcher: [link](https://www.bsc.es/fletcher-chloe)
- Raúl Capellán: [link](https://www.bsc.es/ca/capellan-fernandez-raul)
- Daniela Lührsen: [link](https://www.bsc.es/es/luhrsen-daniela-sofie)
- Rachel Lowe: [link](https://www.bsc.es/lowe-rachel)


# LSL model for the infodengue sprint
This repository contains the final model used to forecast the dengue cases for the infodengue sprint. The infodengue sprint was a model-challenge organized by Mosqlimate project [Sprint Repository](https://github.com/Mosqlimate-project/sprint-template/tree/main). During 2024 in Brazil the disease has spread to areas in the south and at altitudes where epidemics were not previously recorded and the incidence rate has far exceeded that of previous years. The objective of this sprint is to promote, in a standardized way, the training of predictive models with the aim of developing an ensemble forecast for dengue in Brazil. The callenge ask the modellers to provide the prediction for weekly dengue cases at state level (27 units) for a two epidemiological year (Validation test 1 : 2022-2023, Validation Test 2:2023-2024). Epidemiological year was defined as the period spanning from epidemiological week 41 (first week of October) to epidemiological week 40 (last week of September) of the following year. ​

# Model 
We developed a Spatio-temporal model in R-INLA (see 'model_fit_and_prediction.R'). The model consist of a Bayesian spatio-temporal model including 3 set of random effects:

-  Conditional autoregressive (“bym2”) spatial random effects for the brazilian health regions  (i = 1,…,450)
-  Random walk 2 weekly random effects for the week of the year (t), replicated by the 27 Brazilian states  
-  Random walk 1 yearly random effect for the year (j) replicated by the 5 Brazilian Macroregion

The submitted model includes:

- 3-months mooving average of monthly mean temperatures at health region level​ (ERA5-Land) measured 3 months before the outcome
- Standardized Precipitation Index (SPI1) measured 1 month before the outcome
- Standardized Precipitation Index (SPI12) measured 5 months before the outcome

The three meterological parameter are included in the model allowing an interaction between the 3 terms.

# Results
From the fitted model we generated 1,000 samples from the posterior predictive distribution at brazilian health regions. Posterior samples were then aggregated at State level, and summarized as 5th, 50th, 95th quantiles.

The prediction for the Validation Dataset (October 2022 - September 2023) are shown below:
![Validation Set 1](test1_plot.png)
The prediction for the Validation Dataset (October 2023 - June 2024) are shown below:
![Validation Set 2](test2_plot.png)

# Results from the challenge 
Model Performance compared to other model submitted to the challenge are available at the following [link](https://github.com/Mosqlimate-project/sprint-template/blob/main/scores/scores.md)

