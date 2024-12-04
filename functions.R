## Model fitting functions -----------------------------------------------------

# run model in INLA
runinlamod <- function(formula, data = data, family = "nbinomial", config = FALSE){
  # formula     :  formula for INLA
  # data        :  data as dataframe object
  # family      :  likelihood distribution (default: negative binomial)
  # config      :  enable sampling (default: FALSE, set to TRUE in final runs)
  mod <- inla(formula = formula, data = data, family = family,
              offset = log(pop/10^5),
              control.inla = list(strategy = 'adaptive'), 
              control.compute = list(dic = TRUE, waic = TRUE, config = config,
                                     cpo = TRUE, return.marginals = FALSE),
              control.fixed = list(correlation.matrix = TRUE, 
                                   prec.intercept = 1, prec = 1),
              control.predictor = list(link = 1, compute = TRUE), 
              verbose = FALSE,
              inla.setOption(num.threads = 32))
  mod <- inla.rerun(mod)
  return(mod)
}

posterior_pred <- function(model, data) {

  #N samples 
  s <- 1000
  
  # Sample from the posterior
  post_samples <- INLA::inla.posterior.sample(s, model)
  
  n_pred <- nrow(data)
  # Extract values of interest from the posterior sample (not change anything or it crash)
  par_samples <- matrix(NA, (1 + n_pred), s)
  
  for(col in 1:s){
    par_samples[1,col] <- post_samples[[col]][["hyperpar"]][[1]]
    
    # Extract target month for each district
    par_samples[2:nrow(par_samples),col] <- post_samples[[col]][["latent"]][1:nrow(data)]
  }
  
  # Create posterior predictive sample
  y_pred <- matrix(NA, n_pred, s)
  for (s_idx in 1:s) {
    par_sample_xx <- par_samples[, s_idx]
    y_pred[, s_idx] <- rnbinom(n_pred,
                               mu = exp(par_sample_xx[-1]), # Predicted means
                               size = par_sample_xx[1]
    ) # Overdispersion parameter
  }
  
  y_pred <- as.data.frame(y_pred)
  y_pred$uf_id <- data$uf_id
  y_pred$epiweek <- data$epiweek

  y_pred <- y_pred %>% group_by(uf_id, epiweek) %>%
  summarise(across(everything(), \(x) sum(x, na.rm = TRUE)))
  return(y_pred)
}
