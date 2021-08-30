# stulletal_mcp
This repository contains the source code for our paper:

> K.E. Stull, E.Y. Chu, L. Corron,  and M.H. Price, (2021). *Mixed Cumulative Probit: A novel algorithm inspired by methodological and practical shortcomings of age estimation in biological and forensic anthropology*. In review.

<!-- Our pre-print is online here: -->

<!-- > Authors, (YYYY). _`r Title`_. Name of journal/book, Accessed `r format(Sys.Date(), "%d %b %Y")`. Online at <https://doi.org/xxx/xxx> -->


### How to cite

Please cite this compendium as:

>  K.E. Stull, E.Y. Chu, L. Corron,  and M.H. Price, (2021). Compendium of R code and data for *Mixed Cumulative Probit: A novel algorithm inspired by methodological and practical shortcomings of age estimation in biological and forensic anthropology*. Accessed *Current Date*.

# Setup
This research compendium has been developed using the statistical programming language R. To work with the compendium, you will need the [R software](https://cloud.r-project.org/) itself and optionally [RStudio Desktop](https://rstudio.com/products/rstudio/download/). If you only have R and do not have RStudio, you will additionally have to install [Pandoc](https://pandoc.org/installing.html).

At the bottom of this README, we provide directions for running the analyses using a Docker image. One advantage of using Docker is that R's parallel processing libraries do not use forking on Windows, so running inside a Linux Docker container on Windows usually yields a much faster runtime for the multivariate optimization.

## Install R package yada
Once you have **R** and/or **RStudio** opened, install `yada`, which will install additional dependencies:

``` r
# If necessary, install devtools
install.packages("devtools")

# Install yada
devtools::install_github("MichaelHoltonPrice/yada")

# If necessary, install dplyr and ggplot2
install.packages("dplyr")
install.packages("ggplot2")
```

## Getting the code and input data
Cloning this repository means that you copy all files and scripts to your local system (*e.g.* laptop, desktop, server). There are two ways to achieve this goal:  
1. If you are using a Mac operating system or have another shell terminal system (such as [Git for Windows](https://gitforwindows.org/)), open your terminal and enter the following commands:

```console
cd "file/path/to/desired/repository/location"
git clone https://github.com/ElaineYChu/stulletal_mcp
cd stulletal_mcp
ls
```
These four lines of code will a) set the location where you want to save the repository, b) clone the repository, c) enter the newly-created directory, and d) list its contents.  

2. If you do not have or are unfamiliar with terminal command systems, you may also locate and click on the green button in this repository labeled "Code" with a downward arrow and select "Download ZIP." This will download a zipped file to your local system (probably found in your *Downloads* folder). Extract the embedded folder ("stulletal_mcp-main") and relocate it to your desired folder location. **Next, rename the folder to "stulletal_mcp" before proceeding further.**

Another noteworthy file included in this repository is the **"MCP_Quick_Ref.pdf"** file, which contains the information for available usages for the mixed cumulative probit ("MCP") and how to alter the scripts for one's own analyses and new data.

## Explore the input data
Input files for this demonstration are located in the folder *data*. You will find two files: 
* SVAD_US.csv - This data file holds individual observations as rows, and demographic and trait information as columns.  
* US_var_info.csv - This file holds all variable information and must be standardized as such, to match the format expected by `yada`: 

Column Name | Description
----------- | -----------
Variable    | The variable name
Type        | The type of variable. There should be exactly one variable, labeled as "x" (**Options:** x, ordinal, continuous, other)
Categories  | A category specification for ordinal variables, it is left blank for non-ordinal variables. Categories are placed in order and separated by a single space. The user may also define categories that should be collapsed together using curly brackets (**Ex:** 1 2 3 4 5 6 7 8 9 10 11 {12 13} will collapse values 12 and 13)
Missing_Value | Value(s) that represent missing data for each variable, other than NA. Multiple values are separated by commas (**Ex:** -1,99)
Left_Right_Side | The side on which the label is appended to the variable name to distinguish left/right variables (**Options:** start, end)
Left_Label | The label that marks left variables (**Ex:** \_L)
Right_Label | The label that marks right variables (**Ex:** \_R)
Left_Right_Approach | The approach to use for merging left/right variables (**Options:** left, right, mean, highest, lowest) 

*The first four columns are required*, whereas the final four columns are optional and are only used if left/right variables exist in the data file that should be merged (*SVAD_US.csv* here). Each variable must match a column name in the corresponding data file
**NOTE:** Only variables named in the var_info file (*US_var_info.csv* here) will be kept for analyses.


# Running the analyses
The analyses consist in calling a set of R scripts. These scripts use the *results* folder in the cloned repository for storing all files generated by the analyses. The R scripts are set up so that the user may make minimal changes to adapt the code to their own data files and/or names. We recommend exploring each script file to get detailed information about the processes involved with each step. To do so, open each *.R* file in RStudio (or Notepad) or refer to them here in the GitHub repository.

The following pipeline is recommended:

## 1. Generate the problems (main problem and cross-validation folds)
**Set the R working directory to the root of the cloned directory** (e.g., using `setwd()`):

``` r
setwd("file/path/to/folder/stulletal_mcp")
```
Make sure the file/path/to/folder is the unique location for the folder *stulletal_mcp* or else this example pipeline will not work and you will get an error message.

Then run the following command in R:

``` r
source("write_US_problems.R")
```

This will generate the following files:

* results/problem_US.rds  
* results/train_US_fold1.rds  
* results/train_US_fold2.rds  
* results/train_US_fold3.rds  
* results/train_US_fold4.rds  
* results/test_US_fold1.rds  
* results/test_US_fold2.rds  
* results/test_US_fold3.rds  
* results/test_US_fold4.rds  

*problem_US.rds* stores the input data in the format expected by `yada` (*i.e.*, lists). In addition, four cross-validation folds are written, where *train_US_fold1.rds* stores the training data for the first fold and *test_US_fold1.rds* is the corresponding test data.

To preview the files generated by this script, run the following command in R, changing the *problem_US.rds* portion of the code to any file you want to view:

``` r
view_problem <- readRDS("results/problem_US.rds"")
head(view_problem)
```

As mentioned above, the problem is a list object with the following items:
* x - A vector, with length equal to the sample size, containing the "predictor" variable (for our example, known age)  
* Y - A matrix, with rows equal to the number of "response variables" and columns equal to the sample size, containing the variable values  
* var_names - A vector, with length equal to the number of "response variables", containing variable names
* mod_spec - A list containing the number of continuous variables (J), the number of ordinal variables (K), and the number of ordinal breaks (M)

## 2. Generate univariate cumulative probit fits for each variable
The responses are in the matrix Y for each problem (`problem_US$Y`). This script uses maximum likelihood estimation with each response variable (*e.g.*, FDL, TC_Oss) to produce a univariate continuous model fit (distribution) for the predictor variable (here, x). This is done for multiple combinations of the mean and noise models, as well as each cross-validation fold.

``` r
source("solvey_US_univariate.R")
```

This will generate a large number of files such as the following two:

1. results/solutiony_US_fold3_ord_j_2_TC_Oss_pow_law_ord_const.rds
2. results/solutiony_US_fold2_cont_k_1_FDL_pow_law_lin_pos_int.rds

File (1) is the univariate fit for the 3rd cross-validation fold, the 2nd ordinal variable (j=2) named TC_Oss, with a mean specification of pow_law_ord, and a noise specification of constant (see the `yada` documentation for details on the specifications and information on specifications at the end of this section). File (2) is the univariate fit for the 2nd cross-validation fold, the 1st continuous variable (k=1) named FDL, with a mean specification of pow_law, and a noise specification of lin_pos_int (again, see the `yada` documentation). *In total, 140 new files are created in this example.*

**NOTE:** This process may take a while -- feel free to take a break, eat some snacks, or go for coffee! To estimate this script's progress, check your *results* folder and see how many files starting with "solutiony_" are in there. A general rule for calculating how many files to expect is as such:

> expected_file_number = (num_folds + 1) * [6(num_ordinal_variables) + 2(num_continuous_variables)]

The mean and noise specifications for each model are as follows:

**Mean models:**
* pow_law_ord - power law (ordinal variables)
* log - logarithmic (ordinal variables)
* lin - linear (ordinal variables)
* pow_law - power law (continuous variables)

**Noise models:**
* const - constant noise (homoskedastic)
* lin_pos_int - linear positive intercept (heteroskedastic)

## 3. Conduct univarite cross-validation
The next script uses the univariate fits for the cross-validation folds to calculate the out of sample likelihoods for each model specification to select a final model for each response variable. Each model specification consists of a choice for the mean model (three choices for ordinal variables, and only one choice for continuous variables) and for the noise model (two choices for all variables). The script then ranks the models and writes a report for each response variable (full details on the cross-validation and model selection are available in `yada` documentation).

``` r
source("make_univariate_crossval_results.R")
```

The main data file with cross-validation results is:

* cv_data_univariate_US.rds  

In addition, a report is made for each variable, which consists of an .Rmd file for each variable along with the associated .html from rendering the .Rmd file (it is the html files that should be opened). Therefore, two files are generated for each response variable. For example, the files for the 2nd ordinal and 1st continuous variable are:

* US_ord_j_2_TC_Oss.Rmd 
* US_ord_j_2_TC_Oss.html 
* US_cont_k_1_FDL.Rmd  
* US_cont_k_1_FDL.html 

Opening a .html report will give the following sections:
* Summary information: This section tells you the number of individuals in the sample with missing data for that variable and other optimization specifications set previously in "solvey_US_univariate.R" (*e.g.*, cand_tol, scale_exp_min, beta2_max). For ordinal variables, this section will also include the number of ordinal categories in the data for that response variable.
* Negative log-likelihood by model and fold: This table will show all mean-noise combinations attempted for the single response variable as rows and the negative log-likelihood value for each problem (*i.e.*, main or fold) as columns. As a general rule for negative log-likelihood, the smaller the number, the better the model performance.
* Automated model selection: This table provides information for model selection, again showing each mean-noise combination. Most notable is the "modelRank" column, which provides each mean-noise combination's ranking from best (1) to worst (2 or 6). Use this table to inform which mean-noise combination output to refer to in the next section. 
* Univariate fits for each model: Each section and table provides the model parameters as rows and parameter values as columns. These values can be used to write the model equation.  

Please refer to the file *MCP_Quick_Ref.doc* in this repository for the description and structure of each mean and noise equation. 

## 4. Fit the multivariate cumulative probit
Variables are statistically independent if the value (or realization) of one variable does not influence the probability of the other. Two variables are conditionally dependent if they are not conditionally independent of each other. Our multivariate cumulative probit optimization allows for the possibility that, for the correlation terms of the covariance matrix, groups of variables behave identically.

Multivariate cumulative probit requires a lot more computing power compared to univariate models. To provide a reproducible (and time sensitive) example, this demonstration script uses a subset of variables to generate a multivariate cumulative probit fit.

The following variables were selected for this demonstration:

* FDL - femur diaphyseal length
* RDL - radius diaphyseal length
* HME_EF - humerus medial epicondyle epiphyseal fusion score
* TC_Oss - Tarsal count
* max_M1 - maxillary first molar developmental stage
* man_I2 - mandibular second incisor developmental stage

``` r
source("solvey_US_multivariate.R")
```

## 5. Conduct multivariate cross-validation
The next script conducts a maximum likelihood calculation for both the conditionally independent and conditionally dependent multivariate models generated by *solvey_US_multivariate.R* and prints the calculation results. Keep in mind that the conditionally independent multivariate model parameters are the same as those selected by *make_univariate_crossval_results.R*. The maximum likelihood results will assist in model selection between the conditionally independent and conditionally dependent multivariate models, with the lower maximum likelihood result generally indicating a better-performing model. To perform multivariate model cross-validation, type the following into your R console:

``` r
source("make_multivariate_crossval_results.R")
```


# Making Publication Results

## 1. Fit an offset Weibull mixture distribution to the known ages
The ages are in the variable x for each problem. This script fits a two-component Weibull mixture distribution to these ages (using a small offset of 0.002) and provides the appropriate prior on age for estimating the posterior age density. 

``` r
source("solvex_US.R")
```

This will generate the following files:

* results/solutionx_US.rds  
* results/solutionx_US_fold1.rds  
* results/solutionx_US_fold2.rds  
* results/solutionx_US_fold3.rds  
* results/solutionx_US_fold4.rds  

## 2. Produce plots and tables from the publication
The following script provides all code for generating the plots and values included in Stull et al. (2021) and the supplimentary information. All print statements from the console will also be saved as a .txt file (*make_publication_results_output.txt*). 

``` r
source("make_publication_results.R")
``` 

MCP model performance is evaluated using two methods:  
1. The Kullback-Leibler divergence calculates the amount of information gained by both the conditionally independent ('cindep') and conditionally dependent ('cdep') multivariate models. Information gain is calculated by comparing the posterior density of the independent variable x (here, age), and the prior density set on the independent variable, represented by th_x, which was calculated in the previous step using *solvex_US.R*. This metric is complimentary to the results of the multivariate cross-validation script (*make_multivariate_crossval_results.R*), as it provides a measure for how much information is gained (overfit) or lost (underfit) for the selected model compared to the not-selected model.
2. The expected squared error is calculated using the known age of an individual and the posterior density of x provided by both the cindep and cdep models. This metric, along with the +/-2.5% posterior range and point estimates for x are calculated using the y `yada` function *analyze_x_posterior()*. 


# Additional content
## Using the Pipeline for New Data
Please refer to the "MCP_Quick_Ref.pdf" file for detailed information on script changes for new data and/or analyses, and for ways the MCP is made accessible to all users.

## Other functions
The following functions can help generate supplemental results and/or files, but were not used to produce results for Stull et al. (2021). Full documentation of these functions are found in `yada`:  
1. `vis_cont_fit()` and `vis_ord_fit()` Produce a visualizations of univariate, continuous or ordinal fits. Here, x is a vector of observed ages and w is a vector of observed responses (*such as FDL or max_M1*). In addition, this function requires the model parameter vector (th_w) and model specifications (mod_spec), obtained using the script `solvey_US_univariate.R`.
2. `plot_x_posterior()` Plots the posterior density of a univariate or multivariate MCP model. Prior to using this function, the user must first run `calc_x_posterior()` and `analyze_x_posterior()` to obtain the posterior density for plotting. If age is known, the user may input the optional argument, xknown, during the `analyze_x_posterior()` step, which will then plot the known age on the density plot.

# Running the analyses using Docker 
Docker provides an appealing framework for running reproducible scientific analyses that we hope will see greater use in the future. We have provided a Dockerfile that defines a Docker image which can be used to run all our publication analyses.

First, [install Docker](https://docs.docker.com/engine/install/) and ensure that it is available on the terminal/command line path.

Second, clone this repository using git (these directions assume use of the terminal/command line, but see above for how to download the directory directly using git) and change directory (cd) into the base of the repository.

```console
git clone https://github.com/ElaineYChu/stulletal_mcp
cd stulletal_mcp
```

Third, run the following command at the terminal to build the Docker image. To force all docker material to be (re)downloaded prior to creating the Docker image -- a step you should be certain you want to take -- use: "docker system prune -a".

```console
docker build -t michaelholtonprice/stulletal_mcp .
```

This will create a Linux image (Ubuntu 20.04), install R, install necessary dependencies, copy data and script files into the Docker image, and install R using the script install_yada.R that is part of this repository (specifically, commit b16034db9d81e59642ffda029ade8f91df669846 of yada is installed).

Fourth, start a Docker container with the following command:

```console
docker run --name stulletal_mcp -itv //c/stulletal_mcp_mirrored_dir:/mirrored_dir michaelholtonprice/stulletal_mcp
```

The preceding command places the user at a command line "inside" the Docker container. The -v tag in the command mirrors a directory on the host machine (C:\\stulletal_mcp_mirrored_dir) to a directory inside the Docker container (/mirrored_dir) that can be used to pass files between the host machine and the Docker container. The directory to the left of the semicolon is for the host machine and the directory to the right of the semicolon is for the Docker container. The path for the host machine may need to be modified for your situation.

Fifth, change directory (cd) into stulletal_mcp (where files were copied during creation of the Docker image; see the Dockerfile) and run all the analysis scripts:

```console
cd stulletal_mcp
Rscript run_all_analyses.R
```

Alternatively, start R and run the analyses one-by-one as described above.

Sixth and finally, copy the results to the mirrored directory:

```console
cp -fr ./results /mirrored_dir
```
