# The preceding script in the "pipeline" is "solvey_US_multivariate.R", which
# conducts a maximum likelihood calculation for both the conditionally
# dependent and conditionally independent six-variable models. The maximum
# likelihood calculations are then used for model selection and as
# complimentary evidence for interpretations made using the Kullback-Leibler
# metrics (see README or Supplemental Information for more details).

# Load libraries
library(yada)
library(doParallel)
#library(nestfs)

# Clear the workspace
rm(list=ls())

# Re-direct print statements to a text file for a permanent record of
# processing
sink("results/make_multivariate_crossval_results_output.txt")

# Check that a results folder exists in the working directory
if(! ("results" %in% dir()) ) {
  stop("There is no 'results' folder in the working directory")
}

# Use all available cores for parallel processing
registerDoParallel(detectCores())

# The data directory is /results
data_dir <- "results"
# The "ID" that uniquely identifies this analysis:
analysis_name <- 'US'


# Perform multivariate model cross-validation using fold data
fold_data_list <- list()
num_folds <- get_num_training_problems(data_dir,analysis_name)
for (fold in 1:num_folds) {
  fold_data_list[[fold]] <- crossval_multivariate_models(data_dir,
                                                         analysis_name,
                                                         fold)
}

eta_cindep <-
  sum(unlist(lapply(fold_data_list,
                    function(fold_data){sum(fold_data$eta_vect_cindep)})))
eta_cdep <-
  sum(unlist(lapply(fold_data_list,
                    function(fold_data){sum(fold_data$eta_vect_cdep)})))

# Return maximum likelihood estimations
print(paste0("Out-of-sample negative log-likelihood for conditionally ",
             "independent model: ",eta_cindep))
print(paste0("Out-of-sample negative log-likelihood for conditionally ",
             "dependent model: ",eta_cdep))

# Stop clusters from parallel processing
stopImplicitCluster()

# End the re-directing of print statements to file
sink()