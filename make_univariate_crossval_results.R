# The preceding script in the "pipeline" is "solvey_US_univariate.R", which 
# conducts a maximum likelihood fits for each response variable with six 
# parameteric  model choices for the ordinal variables and two for the 
# continuous variables.
# This script uses those fits to write cross-validation reports for each
# response variable, which results in a single parameteric model being chosen
# for each response variable. Those choices are used in the ensuing script in
# the pipeline, "solvey_US_multivariate.R", which generates the best
# conditionally independent ('cindep') and conditionally dependent ('cdep') 
# multivariate models.

# Load libraries
library(yada)

# Clear the workspace
rm(list=ls())

# Check that a results folder exists in the working directory
if(! ("results" %in% dir()) ) {
  stop("There is no 'results' folder in the working directory")
}

# Use all available cores for parallel processing
# registerDoParallel(detectCores(logical=FALSE))

# The data directory is /results
data_dir <- "results"

# The "ID" that uniquely identifies this analysis:
analysis_name <- 'US'

# Call crossval_univariate_models to do the cross validation. Results are
# stored in stulletal_mcp/results/cv_data_univariate_US.rds.
# Please refer to the function documentation for yada::crossval_univariate_models
# for an explanation of the input variables and output format.
cv_data <- crossval_univariate_models(data_dir, analysis_name, 
                                      cand_tol=.05,
                                      scale_exp_min=.01,
                                      beta2_max=5)

# Write a cross validation report for each ordinal variable, which is stored
# in stulletal_mcp/results
for(j in 1:length(cv_data$mod_select_ord)) {
  write_ordinal_report(data_dir, analysis_name, j, line_width=200)
}

# Write a cross validation report for each continuous variable, which is stored
# in stulletal_mcp/results
for(k in 1:length(cv_data$mod_select_cont)) {
  write_continuous_report(data_dir, analysis_name, k, line_width=200)
}

# Extract best univariate parameters for each response variable into a dataframe.
# Dataframe is stored as stulletal_mcp/results/US_univariate_model_parameters.rds
get_best_univariate_params(data_dir, analysis_name, save_file=TRUE)
