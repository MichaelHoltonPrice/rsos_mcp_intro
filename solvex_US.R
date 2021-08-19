# This script must be run prior to making final results. That is, while it is
# not needed to solve any of the y-variable (response variable) maximum
# likelihood problems, it must be run prior to making any age predictions
# since it provides the appropriate prior on age for estimating the posterior
# age density.

# TODO: make and name the final results files
# Load libraries
library(yada)

# Clear the workspace
rm(list=ls())

# Check that a results folder exists in the working directory
if(! ("results" %in% dir()) ) {
  stop("There is no 'results' folder in the working directory")
}

# Fit the age-values with a very slightly offset Weibull mixture
# Seed from random.org between 1 and 1,000,000
set.seed(895131)

weib_offset <- 0.002
data_dir <- 'results'
analysis_name <- 'US'

# Do (and save) offset Weibull mixture fit for main problem
# Load the main problem from file
problem0 <- readRDS(build_file_path(data_dir, analysis_name, "main_problem"))

# define Weibull fit with predictor offset
weib_fit <- mixtools::weibullRMM_SEM(problem0$x + weib_offset,
                                     k=3,
                                     maxit=2000)

# Generate and save the x-solution for the main problem
theta_x <- list(fit_type='offset_weib_mix',
                fit=weib_fit,
                weib_offset=weib_offset)
saveRDS(theta_x,build_file_path(data_dir, analysis_name, "solutionx"))

# Do (and save) offset Weibull mixture fit for cross-validation problems
for(ff in 1:4) {
  # Load training problem
  problem_ff <- readRDS(build_file_path(data_dir,
                                        analysis_name,
                                        "training_problem",
                                        fold=ff))
  # Do offset Weibull fit
  weib_fit_ff <- mixtools::weibullRMM_SEM(problem_ff$x + weib_offset,
                                          k=3,
                                          maxit=2000,
                                          lambda=weib_fit$lambda,
                                          shape=weib_fit$shape,
                                          scale=weib_fit$scale)
  # Save offset Weibull fit
  theta_x_ff <- list(fit_type='offset_weib_mix',
                     fit=weib_fit_ff,
                     weib_offset=weib_offset)
  saveRDS(theta_x_ff,build_file_path(data_dir,
                                     analysis_name,
                                     "solutionx",fold=ff))
}
