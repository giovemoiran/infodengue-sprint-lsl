# ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
# Description:
#     Produce the Posterior Predictive Distribution for the 3 way interaction model
#     for year Test1 (Epiweek 41 2022 - Epiweek40 2023)

# Script authors:
#     Dr Giovenale Moirano  (giovenale.moirano@bsc.es)
#     Chloe Fletcher        (chloe.fletcher@bsc.es)
#     Prof. Rachel Lowe     (rachel.lowe@bsc.es)

# ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
## 1) Source packages, functions and data 
# ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''

#Load packages and functions
packages <- c("INLA", "dplyr","sf","stringr","ggplot2")
lapply(packages, library, character.only = TRUE)
source("functions/functions.R")

#Create neighbourhood matrix
shp <- read_sf("data/shp/BR_Regionais.shp")  
shp <- shp %>% arrange (reg_id)

#nb.map <- spdep::poly2nb(shp, queen=T)
#if (!file.exists("data/shp/map.graph")) spdep::nb2INLA("data/shp/map.graph", nb.map)

#Set inla graph
g <- inla.read.graph("data/shp/map.graph")

#Read in harmonised data and subset train 1 and test1
data <- read.csv("data/data.csv")  

# ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
## 2) Subset data for Train and test 1 and prepare them for INLA 
# ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''

# Filter data 
data <- data %>%
  filter(train_2 =="True" | target_2 == "True")

#Set casos to NA if target_1 == "True"
data <- data %>% 
  mutate(real_cases = casos,
         casos = ifelse(target_2 == "True", NA, casos))

#Format variables for inla 
data$macro<- substr(data$regional_geocode,0,1)

data <- data %>%
  mutate(week_id = as.numeric(substr(epiweek,5,6)), 
         year_id = as.numeric(factor(epi_year)), 
         regional_id = as.numeric(factor(regional_geocode)),
         macro_id = as.numeric(factor(macro)),
         uf_id = as.numeric(factor(uf)), 
         uf_id2 =  as.numeric(factor(uf)),
         uf_id3 = as.numeric(factor(uf))) %>%
  mutate(week_id = ifelse(week_id == 53, 52, week_id))


# ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
## 3) Specify and Fit the Best Model
# ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
# # IDENTIFIED MODEL
# - intercept
# - monthly cyclic random effect (RE) using random walk (RW2)
# - interannual RE using random walk (RW2)
# - health region level spatial RE using modified Besag-York-Mollie (BYM2)
# - SPI12.lag5
# - SPI1.lag1
# - Tmean_lag3

#Prior Specification and Random Effects 
precision.prior <- list(prec = list(prior = "pc.prec", param = c(0.5, 0.01)))

#Best Formula
best.form <- "casos ~ 1 + f(week_id, replicate = uf_id, model = 'rw2', cyclic = TRUE, constr = TRUE,
              scale.model=TRUE, hyper=precision.prior) + f(year_id, model='rw1', replicate =macro_id, 
              hyper=precision.prior) + f(regional_id, model = 'bym2', graph = g, scale.model = TRUE, 
              hyper = precision.prior) + temp3_med_m_lag_3 * spi12_m_lag_5 * spi1_m_lag_1"

# Run model
best.mod <- runinlamod(formula(best.form), data, config = TRUE)

# ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
## 4) Generate Predictions and plot them
# ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''

#Sample from the Posterior Predictive Distribution
post_pred_dist<-posterior_pred(best.mod, data)

# Summarize the Posterior Predictive Samples to Median and p5, p95
post_pred <- as.data.frame(post_pred_dist)
post_pred <- post_pred %>%
  rowwise() %>%
  mutate(
    median = median(c_across(-c(uf_id,epiweek)), na.rm = TRUE),
    p5 = quantile(c_across(-c(uf_id,epiweek)), probs = 0.05, na.rm = TRUE),
    p95 = quantile(c_across(-c(uf_id,epiweek)), probs = 0.95, na.rm = TRUE)
  ) %>% select(median,p5,p95,uf_id,epiweek)


# Subset data for plotting
data_plot <- data %>% group_by(date, epiweek, uf_id, uf) %>%
  summarise(real_cases= sum (real_cases)) %>%
  left_join(post_pred, by = c("epiweek","uf_id")) %>% 
  filter(uf %in% c("AM","CE","GO","MG","PR"))

plot <- data_plot %>%
  mutate(date=as.Date(date)) %>% 
  filter(date >= as.Date("2023-10-01")) %>%
  ggplot(aes(x=date)) +
  geom_ribbon(aes(ymin=p5, ymax=p95), fill="deeppink2", alpha=0.4)+
  geom_line(aes(y=median, colour="Median")) +
  geom_line(aes(y=real_cases, colour="Observed")) +
  scale_x_date(date_breaks="1 month", date_labels="%m") +
  facet_wrap(~ uf, scales="free") +
  labs(x="", y="", colour="") +
  scale_color_manual(values = c("Observed"="black", "Median"="deeppink2")) +
  theme_bw() +
  theme(axis.text.x=element_text(angle=45, hjust=1), legend.position="top",
        plot.title=element_text(hjust=0.5), panel.border = element_blank())

#Save posterior as a graph 
ggsave(plot,dpi = "retina", file = "test2_post_pred.tiff")

# ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
## END
# ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
