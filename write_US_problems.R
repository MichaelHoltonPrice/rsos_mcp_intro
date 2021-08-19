# Overview of script
# Goal: Our goal with the comments in this script (and others in the 
# stulletal_mcp repository) is not just to describe the immediate analysis, 
# but also to describe how the script(s) can be modified to fit mixed 
# cumulative probit models using other datasets.
#
# This script does the preprocessing needed to generate "problem" files in the
# format required by the yada package for subsequent steps such as maximum
# likelihood fitting and model selection using cross-validation. yada provides
# a "convenience" function called load_mcp_data to do so, and we have made
# load_mcp_data sufficiently flexible to, we think, handle most types of
# preprocessing that a user will need to do; for example, it is possible for
# one input variable to use "-1" to mark missing values and another to use
# "NA". Of course, it is incumbent on the user to understand when load_mcp_data
# can and cannot be used. Given that, it is perhaps best to start by describing
# the format of the data required by subsequent yada functions. Three variables
# are needed in the problem file:
#
# x        The value of the independent variable (likely age) for each
#          observation. x is a vector of length N, where N is the number of
#          observations.
#
# Y        The value(s) of the response variables (e.g., ordinal dental traits
#          and continuous longbone lengths)). Y is a matrix with dimensions J+K
#          by N, where J is the number of ordinal response variables and K is
#          the number of continuous response variables; that is, rows are
#          response variables and columns are observations. The ordinal
#          variables comprise the first J rows of Y and the continuous variables
#          comprise the last K rows. It is acceptable for either J or K to equal
#          zero (no variables of that type). Ordinal variable values in the
#          matrix Y must be "standardized" to be adjacent integers that run
#          from 0 to M_j, where ordinal variable j has M_j+1 categories (for
#          more on M_j see the subsequent description of mod_spec).
#          in Y 
#
# mod_spec  mod_spec stands for model specification. At a minimum, the model
#          specification has three fields: J, K, and M. J, K, and M are all as
#          before; mod_spec is needed since their values cannot be uniquely
#          determined from x and Y alone (for example, only the sum J+K can be
#          determined from the dimensions of Y). M is a vector of length J that
#          indicates how many ordinal categories exist for each ordinal
#          variable (the number of categories is M_j+1). M does not need to
#          be specified if there are no ordinal variables (J+0). [We write "At
#          a  minimum" earlier because to actually fit a model one must also
#          specify parametric models for both the mean response and noise, but
#          that will typically be done after loading the data, and usually it is
#          best to use cross-validation to choose the best parametric models.]
# 
# Consider a simplified example dataset with three observations (N=3), two
# ordinal variables (J=2) and two continuous variables (K+2).
#
# x <- c(9.5,0.5,8.0)
# Y <- matrix(c(0,NA,4.2,NA,2,1,2.2,100.4,1,0,3.8,80.9),nrow=4)
# print(Y)
#      [,1]  [,2] [,3]
# [1,]  0.0   2.0  1.0
# [2,]   NA   1.0  0.0
# [3,]  4.2   2.2  3.8
# [4,]   NA 100.4 80.9
#
# mod_spec <- list(J=2,K=2,M=c(2,1))
#
# If a user already has data in the preceding format, it can of course simply be
# used without any preprocessing. However, often (probably typically) different
# coding conventions are used during data collection, which yada::load_mcp_data
# can accommodate. To do so, load_mcp_data requires both an input .csv data file
# and a variable information file, which is loaded via the function
# yada::load_var_info. It is worth studying the documentation for these two
# functions and examining the input files used below to determine how best to
# load your own data with load_mcp_data. The input files can be examined and
# downloaded by going to the following links:
#
# TODO: Once we have them in their final locations, add the links.

# Load libraries
library(yada)

# Clear the workspace
rm(list=ls())

# Check that stulletal_mcp is the working directory
if(grepl('stulletal_mcp',getwd())==FALSE) {
  stop(paste0("Please check that your working directory is the ",
              "cloned directory 'stulletal_mcp'"))
}

# Load the variable information file. var_info is a data frame where rows are
# variables and columns are variable specifications.
var_info <-  yada::load_var_info('data/US_var_info.csv')
data_file <- 'data/SVAD_US.csv'
cp_data <- load_cp_data(data_file, var_info)

# Extract the main problem (that is, not a cross-validation fold) from cp_data,
# then save it to stulletal_mcp/results. This creates the following file in that
# directory:
# problem_US.rds
#
# Subsequent steps rely on the analysis_name, "US", which should be a unique
# analysis "ID" for files in the results folder (data_dir).
data_dir <- file.path(".","results")
analysis_name <- "US"
main_problem <- cp_data$problem
save_problem(data_dir, analysis_name, main_problem)

# Generate four cross-validation problems. Use a random number seed (from
# random.org) for reproducibility.

# 4 training and 4 test folds in a list format
cv_problems <- generate_cv_problems(main_problem, K=4, seed=234227327)

# Save the cross-validation problems to file. This creates the following eight
# files in stulletal_mcp/results
#
# train_US_fold1.rds
#  test_US_fold1.rds
# train_US_fold2.rds
#  test_US_fold2.rds
# train_US_fold3.rds
#  test_US_fold3.rds
# train_US_fold4.rds
#  test_US_fold4.rds

# NOTE: is_folds=T here
save_problem(data_dir, analysis_name, cv_problems, is_folds=T)
