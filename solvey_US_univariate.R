# The preceding script in the "pipeline" is write_US_problems.R, which writes
# both the main problem and cross-validation problems to the results folder
# (stulletal_mcp/results). This script, "solvey_US_univariate.R", does maximum
# likelihood on a univariate distribution for each response variable, which is 
# equivalent to a multivariate fit assuming conditional independence ('cindep') 
# of the  variables. These fits are the basis for the cross-validation 
# accomplished by the script "make_univariate_crossval_results.R", which is the 
# ensuing step in the analysis pipeline. For the main problem and each cross 
# validation fold, six parametric models are fit for the ordinal variables 
# and two parametric models are fit for the continuous variables. For the 
# ordinal variables, three distinct models are used for the mean and two for 
# the noise, whereas for the continuous variables one model is used for the mean 
# and two for the noise. In particular, the models are:
#
# Ordinal
# -------------------------
# Mean model    Noise model
# ----------    -----------
# powLawOrd	const
# powLawOrd	lin_pos_int
# log		const
# log		lin_pos_int
# lin		const
# lin		lin_pos_int
#
# Continuous
# -------------------------
# Mean model    Noise model
# ----------    -----------
# powLaw	const
# powLaw	lin_pos_int
#
# For details on these models, see the yada documentation and the technical
# supplement for the peer-reviewed article that introduces the mixed cumulative
# probit:
#
# TODO: Once the article is accepted, add the citation and html link.
#
# While the preceding script in the pipeline may need to be modified (for
# example, because different preprocessing steps are needed), this function
# may not need modification, aside from using a folder other than "stulletal_mcp"
# and an analysis name other than "US".

# Load libraries
library(yada)
library(doParallel)

# Clear the workspace
rm(list=ls())

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

# Load the main problem from file
problem0 <- readRDS(build_file_path(data_dir, analysis_name, "main_problem"))

# Build ordinal problems (main problem and cross-validation folds)
ord_prob_list <- build_univariate_ord_problems(data_dir,
                                               analysis_name,
                                               add_folds=TRUE)

# From random.org between 1 and 1,000,000
base_seed <- 264528
set.seed(base_seed)
seed_vect <- sample.int(1000000, length(ord_prob_list), replace=F)

# Solve the ordinal problems in parallel and save to user-defined directory
ord_success <-
  foreach::foreach(i=1:length(ord_prob_list), .combine=cbind) %dopar% {
    yada::solve_ord_problem(data_dir,
                            analysis_name,
                            ord_prob_list[[i]],
                            anneal_seed=seed_vect[i])
  }

# Build continuous problems (main problem and cross-validation folds)
cont_prob_list <- build_univariate_cont_problems(data_dir,
                                                 analysis_name,
                                                 add_folds=TRUE)

# Solve the continuous problems in parallel and save to user-defined directory
cont_success <-
  foreach::foreach(i=1:length(cont_prob_list), .combine=cbind) %dopar% {
    yada::solve_cont_problem(data_dir, analysis_name, cont_prob_list[[i]])
  }

# Stop clusters from parallel processing
stopImplicitCluster()
