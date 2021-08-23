# In this script, we make plots for the section "Mixed Cumulative Probit"
# sub-section of the Material and Methods section of Stull et al. (2021) and
# the corresponding Supplemental Information.

# Load libraries
library(yada)
library(doParallel)
library(foreach)
registerDoParallel(detectCores())

# Clear the workspace
rm(list=ls())

# Re-direct print statements to a text file for a permanent record of
# processing
sink("results/make_publication_results_output.txt")

# Check that a results folder exists in the working directory
if(! ("results" %in% dir()) ) {
  stop("There is no 'results' folder in the working directory")
}

# The data directory is /results
data_dir <- "results"

# The "ID" that uniquely identifies this analysis:
analysis_name <- 'US'

# Load the main problem from file
problem <- readRDS(build_file_path(data_dir, analysis_name, "main_problem"))

## Figure 1: Univariate Plots
# Create the first publication figure, which is a stacked figure with three sub-
# plots: a continuous variable (FDL) on the top and an ordinal variable
# (max_M1) on the bottom (the bottom two plots). The first ordinal sub-plot
# shows a scatter plot of the observed data and the second ordinal sub-plot
# shows a binned probability plot. For both variables, the heteroskedastic fit
# is used. The three sub-plots share the same x-axis.

# (a) Extract data and do calculations for the continuous variable (FDL)
xplot <- seq(0,21.5,0.01)
cont_var <- "FDL"
i <- which(problem$var_names == cont_var)
k <- i - problem$mod_spec$J
x_FDL <- problem$x
w_FDL <- problem$Y[i,]
ind_to_keep <- !is.na(x_FDL) & !is.na(w_FDL)
x_FDL <- x_FDL[ind_to_keep]
w_FDL <- w_FDL[ind_to_keep]

# Load the fit for the heteroskedastic FDL model
mod_spec_FDL_hetero <- list(K=1, mean_spec="pow_law", noise_spec="lin_pos_int")
fit_FDL_hetero <- readRDS(build_file_path(data_dir,
                                          analysis_name,
                                          "univariate_cont_soln",
                                          k=k,
                                          var_name=cont_var,
                                          mean_spec="pow_law",
                                          noise_spec="lin_pos_int"))
th_w_FDL_hetero <- fit_FDL_hetero$th_y

# Calculate the response for the heteroskedastic FDL model
h_FDL_hetero <- calc_mean_univariate_cont(xplot,
                                          th_w_FDL_hetero,
                                          mod_spec_FDL_hetero)
w_range_FDL <- range(c(w_FDL, h_FDL_hetero))
sig_FDL_hetero <- calc_noise_univariate_cont(xplot,
                                             th_w_FDL_hetero,
                                             mod_spec_FDL_hetero)
w_range_FDL <- range(c(w_range_FDL,
                       h_FDL_hetero - sig_FDL_hetero,
                       h_FDL_hetero + sig_FDL_hetero))

# (b/c) Extract data and do calculations for the ordinal variable (max_M1)
ord_var <- "max_M1"
j <- which(problem$var_names == ord_var)
x_max_M1 <- problem$x
v_max_M1 <- problem$Y[j,]
ind_to_keep <- !is.na(x_max_M1) & !is.na(v_max_M1)
x_max_M1 <- x_max_M1[ind_to_keep]
v_max_M1 <- v_max_M1[ind_to_keep]

# Create the model specification
mod_spec_max_M1_hetero <- list(J=1,
                               M=problem$mod_spec$M[j],
                               mean_spec="pow_law_ord",
                               noise_spec="lin_pos_int")

# Load the fit for the heteroskedastic max_M1 model
fit_max_M1_hetero <- readRDS(build_file_path(data_dir,
                                             analysis_name,
                                             "univariate_ord_soln",
                                             j=j,
                                             var_name=ord_var,
                                             mean_spec="pow_law_ord",
                                             noise_spec="lin_pos_int"))
th_v_max_M1_hetero <- fit_max_M1_hetero$th_y
th_max_M1_hetero <- fit_max_M1_hetero$th_y

# Calculate the response for the heteroskedastic max_M1 model
g_max_M1_hetero <- calc_mean_univariate_ord(xplot,
                                            th_v_max_M1_hetero,
                                            mod_spec_max_M1_hetero)

# Do the binning to visualize the ordinal fit (max_M1). This is modified code
# from calc_q.
bin_bounds <- seq(min(x_max_M1),max(x_max_M1),len=20)
num_bins <- length(bin_bounds) - 1

num_cat <- length(unique(v_max_M1)) # number of categories
bin_counts <- matrix(NA,num_bins,num_cat)
bin_centers <- (bin_bounds[1:num_bins] + bin_bounds[2:(num_bins+1)])/2
for(b in 1:num_bins) {
  if(b < num_bins) {
    ind_b <- bin_bounds[b] <= x_max_M1 & x_max_M1 <  bin_bounds[b+1]
  } else {
    ind_b <- bin_bounds[b] <= x_max_M1 & x_max_M1 <= bin_bounds[b+1]
  }
  vb <- v_max_M1[ind_b]
  for(m in 0:(num_cat-1)) {
    bin_counts[b,m+1] <- sum(vb == m)
  }
}
bin_prop <- matrix(NA,num_bins,num_cat) # bin proportions
for(b in 1:num_bins) {
  bin_prop[b,] <- bin_counts[b,] / sum(bin_counts[b,])
}

# Use the 8-th category (the first category is m=0) to visualize the ordinal
# fit
m <- 7
qm <- calc_q(xplot, th_v_max_M1_hetero, m, mod_spec_max_M1_hetero)
band_range <- range(x_max_M1[v_max_M1 == m])

pdf(file.path("results","Fig1_univariate_plots.pdf"), width = 4, height = 6)
  par(
    mfrow = c(3, 1),
    oma = c(4, 2, 0, 0),
    mar = c(0, 4, 0, 0)
  )


  # (a) Plot FDL
  plot(NULL,
       xlim=range(xplot),
       ylim=w_range_FDL,
       ylab=paste0(cont_var," [mm]"),
       xaxt="n")

  # Do the scatter plot
  points(x_FDL, w_FDL, pch=16, cex=.5, col=adjustcolor("red", alpha.f=0.50))

  # Add the mean response
  lines(xplot, h_FDL_hetero, lwd=2, col="black")

  # Add the (heteroskedastic) shaded noise region
  polygon(c(xplot, rev(xplot)),
          c(h_FDL_hetero-sig_FDL_hetero, rev(h_FDL_hetero+sig_FDL_hetero)),
          border = NA,
          xlab = NULL,
          col = adjustcolor("blue", alpha.f = 0.50))

  # (b) Plot max_M1 scatter
  plot(NULL,
       xlim=range(xplot),
       ylim=range(v_max_M1),
       ylab=paste0(ord_var," Value"),
       type="l",
       xaxt="n")

  polygon(c(band_range, rev(band_range)),
          c(-.5, -.5, m, m),
          border = NA,
          xlab = NULL,
          col = adjustcolor("grey", alpha.f = 0.25))

  points(x_max_M1,
         v_max_M1,
         pch=16,
         cex=.5,
         col=adjustcolor("red", alpha.f=0.50))

  # (c) Make the max_M1 binned plot
  plot(NULL,
       xlim=range(xplot),
       ylim=c(0,1),
       ylab=paste0(ord_var," Probability"),
       type="l",
       yaxt="n")

  polygon(c(band_range, rev(band_range)),
          c(.8, .8, 1.25, 1.25),
          border = NA,
          xlab = NULL,
          col = adjustcolor("grey", alpha.f = 0.25))
  # Add the predicted probability
  lines(xplot, qm, lwd=2, col="black")

  # Do the scatter plot of binned points
  points(bin_centers,
         bin_prop[,m+1],
         pch=16,
         cex=1.0,
         col=adjustcolor("red", alpha.f=0.75))
  axis(side = 2, at = c(0.0, 0.2, 0.4, 0.6, 0.8))
  text(7.75, 0.84, "v = 7", cex=1.5)
  mtext("Age [years]", side = 1, line = 2.5)
dev.off()

## Figure 3: Density Plots
# Create the third publication figure, a stacked plot with three sub-plots that
# illustrates posterior inference using a variety of models.

# Load the six-variable conditionally depenedent model from file
six_var_model_cdep <- readRDS(build_file_path(data_dir,
                                              analysis_name,
                                              "cdep_model"))
mod_spec_cdep <- six_var_model_cdep$mod_spec
six_var_model_cindep <- readRDS(build_file_path(data_dir,
                                                analysis_name,
                                                "cindep_model"))
mod_spec_cindep <- six_var_model_cindep$mod_spec

th_y  <- six_var_model_cdep$th_y
th_y0 <- six_var_model_cindep$th_y

# Choose single individual for example
n <- 165
y <- problem$Y[, n]

print(paste0("Age [x] of obervation n = ", n, ":"))
print(problem$x[n])
y_as_df <- as.data.frame(t(problem$Y[,n]))
colnames(y_as_df) <- problem$var_names
print(paste0("Reponse [y] of obervation n = ", n, ":"))
print(y_as_df)

# (a) Extract data and do calculations for Figure 3 (density plots)
# prior
dx <- .01
xcalc <- seq(0,23,by=dx)
th_x <- readRDS(build_file_path(data_dir, analysis_name, "solutionx"))
fprior <- calc_x_density(xcalc,th_x)

# FDL
fit_FDL_homo <- readRDS(build_file_path(data_dir,
                                        analysis_name,
                                        "univariate_cont_soln",
                                        k=k,
                                        var_name=cont_var,
                                        mean_spec="pow_law",
                                        noise_spec="const"))
mod_spec_FDL_homo <- mod_spec_FDL_hetero
mod_spec_FDL_homo$noise_spec <- "const"
th_w_FDL_homo <- fit_FDL_homo$th_y
ind_FDL <- which(problem$var_names == "FDL")

x_post_obj_FDL_homo  <- calc_x_posterior(y[ind_FDL],
                                         th_x,
                                         th_w_FDL_homo,
                                         mod_spec_FDL_homo,
                                         xcalc)
kl_div_FDL_homo <- calc_kl_div(x_post_obj_FDL_homo, th_x)
fpost_FDL_homo <- x_post_obj_FDL_homo$density

x_post_obj_FDL_hetero  <- calc_x_posterior(y[ind_FDL],
                                           th_x,
                                           th_w_FDL_hetero,
                                           mod_spec_FDL_hetero,
                                           xcalc)
kl_div_FDL_hetero <- calc_kl_div(x_post_obj_FDL_hetero, th_x)
fpost_FDL_hetero <- x_post_obj_FDL_hetero$density

# max_M1
fit_max_M1_homo <- readRDS(build_file_path(data_dir,
                                           analysis_name,
                                           "univariate_ord_soln",
                                           j=j,
                                           var_name=ord_var,
                                           mean_spec="pow_law_ord",
                                           noise_spec="const"))
mod_spec_max_M1_homo <- mod_spec_max_M1_hetero
mod_spec_max_M1_homo$noise_spec <- "const"
th_v_max_M1_homo <- fit_max_M1_homo$th_y
ind_max_M1 <- which(problem$var_names == "max_M1")

x_post_obj_max_M1_homo  <- calc_x_posterior(y[ind_max_M1],
                                            th_x,
                                            th_v_max_M1_homo,
                                            mod_spec_max_M1_homo,
                                            xcalc)
kl_div_max_M1_homo <- calc_kl_div(x_post_obj_max_M1_homo, th_x)
fpost_max_M1_homo <- x_post_obj_max_M1_homo$density
x_post_obj_max_M1_hetero  <- calc_x_posterior(y[ind_max_M1],
                                              th_x,
                                              th_v_max_M1_hetero,
                                              mod_spec_max_M1_hetero,
                                              xcalc)
kl_div_max_M1_hetero <- calc_kl_div(x_post_obj_max_M1_hetero, th_x)
fpost_max_M1_hetero <- x_post_obj_max_M1_hetero$density

# Six-variable model
xpost_obj_cdep <- calc_x_posterior(y,
                                   th_x,
                                   th_y,
                                   mod_spec_cdep,
                                   xcalc)
kl_div_cdep <- calc_kl_div(xpost_obj_cdep, th_x)
fpost_cdep <- xpost_obj_cdep$density
xpost_obj_cindep  <- calc_x_posterior(y,
                           th_x,
                           th_y0,
                           mod_spec_cindep,
                           xcalc)
kl_div_cindep <- calc_kl_div(xpost_obj_cindep, th_x)
fpost_cindep <- xpost_obj_cindep$density

print("Information gain from FDL homo [overconfident]")
print(kl_div_FDL_homo)
print("Information gain from FDL hetero")
print(kl_div_FDL_hetero)
print("Information gain from max_M1 homo [overconfident]")
print(kl_div_max_M1_homo)
print("Information gain from max_M1 hetero")
print(kl_div_max_M1_hetero)
print("Information gain from six-variable cindep [overconfident]")
print(kl_div_cindep)
print("Information gain from six-variable cdep")
print(kl_div_cdep)

f_range <- range(fprior,
                 fpost_FDL_homo,
                 fpost_FDL_hetero,
                 fpost_max_M1_homo,
                 fpost_max_M1_hetero,
                 fpost_cdep,
                 fpost_cindep)
pdf(file.path("results","Fig3_density_plots.pdf"), width = 4, height = 6)
  par(
    mfrow = c(3, 1),
    oma = c(4, 2, 0, 0),
    mar = c(0, 4, 0, 0)
  )


  # (a) FDL density plot
  plot(NULL,
       xlim=range(xcalc),
       ylim=f_range,
       ylab="Density [FDL]",
       xaxt="n")
  # Add the known age
  lines(c(1, 1)*problem$x[n], c(0, f_range[2]), lwd=2, col="green")

  # Add the prior, homoskedastic posterior, and heteroskedastic posterior
  lines(xcalc, fprior, lwd=2, col="grey", lty=3)
  lines(xcalc, fpost_FDL_homo, lwd=2, col="grey")
  lines(xcalc, fpost_FDL_hetero, lwd=2, col="black")
  legend("topright",
              c("Prior",
                paste0("Homo [KL = ",
                       sprintf(kl_div_FDL_homo,   fmt = '%#.2f'),
                       "]"),
                paste0("Hetero [KL = ",
                       sprintf(kl_div_FDL_hetero, fmt = '%#.2f'),
                       "]"),
                "Known Age"),
         col =c( "grey",     "grey",      "black",     "green"),
         lty =c(       3,         1,            1,           1))

  # (b) max_M1 density plot
  plot(NULL,
       xlim=range(xcalc),
       ylim=f_range,
       ylab="Density [max_M1]",
       xaxt="n")
  # Add the known age
  lines(c(1, 1)*problem$x[n], c(0, f_range[2]), lwd=2, col="green")

  # Add the prior, homoskedastic posterior, and heteroskedastic posterior
  lines(xcalc, fprior, lwd=2, col="grey", lty=3)
  lines(xcalc, fpost_max_M1_homo, lwd=2, col="grey")
  lines(xcalc, fpost_max_M1_hetero, lwd=2, col="black")
  legend("topright",
              c("Prior",
                paste0("Homo [KL = ",
                       sprintf(kl_div_max_M1_homo,   fmt = '%#.2f'),
                       "]"),
                paste0("Hetero [KL = ",
                       sprintf(kl_div_max_M1_hetero, fmt = '%#.2f'),
                       "]"),
                "Known Age"),
         col =c( "grey",        "grey",      "black",        "green"),
         lty =c(       3,         1,               1,              1))

  # (c) Six variable density plot
  plot(NULL,
       xlim=range(xcalc),
       ylim=f_range,
       ylab="Density [Six Var.]")
  # Add the known age
  lines(c(1, 1)*problem$x[n], c(0, f_range[2]), lwd=2, col="green")
  # Add the prior, cindep posterior, and cdep posterior
  lines(xcalc, fprior, lwd=2, col="grey", lty=3)
  lines(xcalc, fpost_cindep, lwd=2, col="grey")
  lines(xcalc, fpost_cdep, lwd=2, col="black")
  legend("topright",
              c("Prior",
                paste0("Cindep [KL = ",
                       sprintf(kl_div_cindep, fmt = '%#.2f'),
                       "]"),
                paste0("Cdep [KL = ",
                       sprintf(kl_div_cdep,   fmt = '%#.2f'),
                       "]"),
                "Known Age"),
         col =c( "grey",       "grey",    "black",     "green"),
         lty =c(       3,         1,            1,           1))
  mtext("Age [years]", side = 1, line = 2.5)
dev.off()

## Figure S1
# Create the first figure for the supplement, which is a histogram of the
# x-values (ages) with the associated offset Weibull mixture fit.
th_x <- readRDS(build_file_path(data_dir, analysis_name, "solutionx"))
xcalc <- seq(0,23,by=.01)
fprior <- calc_x_density(xcalc, th_x)
xbreaks <- seq(0,23,by=0.5)
pdf(file.path("results","Fig_S1_age_histogram.pdf"))
hist(problem$x,
     xlab="Age [years]",
     ylab="Density",
     main=NULL,
     freq=F,
     breaks=xbreaks)
lines(xcalc, fprior, lwd=3)
dev.off()
print("Number of observations for age histogram (x-values):")
print(length(problem$x))

## Figure S2
# Create the second figure for the supplement, which is for the illustration of
# turning a continuous variable (FDL) into an ordinal variables
# Make w into an ordinal variable that runs from 0 to 3
breaks <- as.numeric(quantile(w_FDL))[2:4] # 25%, 50%, and 75% quantiles
v_FDL <- as.numeric(cut(w_FDL,c(-Inf,breaks,Inf))) - 1

# Reduce the x-range
h_FDL_hetero <- h_FDL_hetero[xplot <= 16]
sig_FDL_hetero <- sig_FDL_hetero[xplot <= 16]
xplot <- xplot[xplot <= 16]

# Do the binning to visualize the ordinal fit (FDL as ordinal). This is
# modified code from calc_q.
bin_bounds <- seq(min(x_FDL),max(x_FDL),len=20)
num_bins <- length(bin_bounds) - 1

num_cat <- length(unique(v_FDL)) # number of categories
bin_counts <- matrix(NA,num_bins,num_cat)
bin_centers <- (bin_bounds[1:num_bins] + bin_bounds[2:(num_bins+1)])/2
for(b in 1:num_bins) {
  if(b < num_bins) {
    ind_b <- bin_bounds[b] <= x_FDL & x_FDL <  bin_bounds[b+1]
  } else {
    ind_b <- bin_bounds[b] <= x_FDL & x_FDL <= bin_bounds[b+1]
  }
  vb <- v_FDL[ind_b]
  for(m in 0:(num_cat-1)) {
    bin_counts[b,m+1] <- sum(vb == m)
  }
}
bin_prop <- matrix(NA,num_bins,num_cat) # bin proportions
for(b in 1:num_bins) {
  bin_prop[b,] <- bin_counts[b,] / sum(bin_counts[b,])
}

# Use the 3-rd category (the first category is m=0) to visualize the ordinal
# fit
m <- 2
mod_spec_FDL_ordinal <- list(J=1,
                             M=3,
                             mean_spec="pow_law_ord",
                             noise_spec="lin_pos_int")
th_v_FDL_ordinal <- fit_univariate_ord(x_FDL, v_FDL, mod_spec_FDL_ordinal)
qm <- calc_q(xplot, th_v_FDL_ordinal, m, mod_spec_FDL_ordinal)
band_range <- range(x_FDL[v_FDL == m])

pdf(file.path("results","FigS2_FDL_to_ordinal.pdf"))
    par(
    mfrow = c(3, 1),
    oma = c(4, 2, 0, 0),
    mar = c(0, 4, 0, 0)
  )

  # (a) Plot FDL
  plot(NULL,
       xlim=range(xplot),
       ylim=w_range_FDL,
       ylab=paste0(cont_var," [mm]"),
       xaxt="n")

  # Do the scatter plot
  points(x_FDL, w_FDL, pch=16, cex=.5, col=adjustcolor("red", alpha.f=0.50))

  # Add the mean response
  lines(xplot, h_FDL_hetero, lwd=2, col="black")

  # Add the (heteroskedastic) shaded noise region
  polygon(c(xplot, rev(xplot)),
          c(h_FDL_hetero-sig_FDL_hetero, rev(h_FDL_hetero+sig_FDL_hetero)),
          border = NA,
          xlab = NULL,
          col = adjustcolor("blue", alpha.f = 0.50))
  for (n in 1:length(breaks)) {
    lines(range(xplot),c(1,1)*breaks[n],col="grey",lwd=2)
    text(15,breaks[n]+15,bquote(tau[.(n)]))
    if (n == 1) {
      yloc <- (min(w_FDL) + breaks[n])/2
    } else {
      yloc <- (breaks[n-1] + breaks[n])/2
    }
    text(13,yloc,bquote(v == .(n-1)))
  }
  text(13,breaks[n]+40,bquote(v == .(n)))

  # (b) Plot FDL as ordinal
  plot(NULL,
       xlim=range(xplot),
       ylim=range(v_FDL),
       ylab="FDL [as ordinal] Value",
       type="l",
       xaxt="n")

  polygon(c(band_range, rev(band_range)),
          c(-.5, -.5, m, m),
          border = NA,
          xlab = NULL,
          col = adjustcolor("grey", alpha.f = 0.25))

  points(x_FDL,
         v_FDL,
         pch=16,
         cex=.5,
         col=adjustcolor("red", alpha.f=0.50))

  # (c) Make the max_M1 binned plot
  plot(NULL,
       xlim=range(xplot),
       ylim=c(0,1),
       ylab="FDL [as ordinal] Probability",
       type="l",
       yaxt="n")

  polygon(c(band_range, rev(band_range)),
          c(.8, .8, 1.25, 1.25),
          border = NA,
          xlab = NULL,
          col = adjustcolor("grey", alpha.f = 0.25))
  # Add the predicted probability
  lines(xplot, qm, lwd=2, col="black")

  # Do the scatter plot of binned points
  points(bin_centers,
         bin_prop[,m+1],
         pch=16,
         cex=1.0,
         col=adjustcolor("red", alpha.f=0.75))
  axis(side = 2, at = c(0.0, 0.2, 0.4, 0.6, 0.8))
  text(7.75, 0.84, "v = 2", cex=1.5)
  mtext("Age [years]", side = 1, line = 2.5)
dev.off()

calc_univ_ord_mi <- function(th_v, mod_spec, th_x, x0, xcalc) {
  # Calculate the mutual information for a univariate ordinal model given the
  # baseline age, x0, and a vector at which to calculate the prior and
  # posterior densitites, xcalc.
  fprior <- calc_x_density(xcalc,th_x)

  M <- mod_spec$M
  pv     <- rep(NA, M+1)
  kl_div <- rep(NA, M+1)
  for (m in 0:M) {
    x_post_obj  <- calc_x_posterior(m,
                                    th_x,
                                    th_v,
                                    mod_spec,
                                    xcalc)
    kl_div[m+1] <- calc_kl_div(x_post_obj, th_x)
    pv[m+1] <- calc_q(x0, th_v, m, mod_spec)
  }
  return(sum(pv*kl_div))
}

calc_cont_kl_div_vect <- function(th_w, mod_spec, xcalc, wcalc) {
  # Calculat a vector of KL divergences for each entry in wcalc
  N1 <- length(wcalc)
  N2 <- length(xcalc)
  kl_div <- rep(NA, N1)

  # Calculate the prior
  fprior0 <- calc_x_density(xcalc,th_x)

  # Use a single for loop to calcualte the likelihood matrix (rather than
  # unwrapping matrices to make a single call to calc_neg_log_lik_cont).
  dx <- xcalc[2] - xcalc[1]
  for (n1 in 1:N1) {
    eta_vect <- calc_neg_log_lik_vect_cont(th_w, xcalc, rep(wcalc[n1], N2), mod_spec)
    lik_vect <- exp(-eta_vect)
    fprior <- fprior0
    fpost <- fprior * lik_vect
    fpost <- fpost / dx / sum(fpost)
    ind_bad <- is.na(fprior) | is.na(fpost)
    fprior <- fprior[!ind_bad]
    fpost <- fpost[!ind_bad]
    ind_bad <- !is.finite(fprior) | !is.finite(fpost)
    fprior <- fprior[!ind_bad]
    fpost <- fpost[!ind_bad]
    ind_bad <- (fprior == 0) | (fpost == 0)
    fprior <- fprior[!ind_bad]
    fpost <- fpost[!ind_bad]
    kl_div[n1] <- sum(fpost * log2(fpost/fprior)) * dx
  }

  return(kl_div)
}

calc_univ_cont_mi <- function(th_w, mod_spec, x0, wcalc, kl_div) {
  # Calculate the mutual information for a univariate cont. model given the
  # baseline age, x0, and a vector of KL divergences with length(wcalc) that
  # was output by calc_cont_kl_div_vect.

  N <- length(wcalc)
  dw <- wcalc[2] - wcalc[1]
  pw <- calc_neg_log_lik_vect_cont(th_w, rep(x0, N), wcalc, mod_spec)
  pw <- exp(-pw)
  pw <- pw / sum(pw) / dw
  return(dw*sum(pw*kl_div))
}

xmi <- seq(0,15,by=.1)

mi_ord <-
  foreach(n=1:length(xmi), .multicombine=T) %dopar% {
     calc_univ_ord_mi(th_v_FDL_ordinal,
                      mod_spec_FDL_ordinal,
                      th_x,
                      xmi[n],
                      xcalc)
  }
mi_ord <- unlist(mi_ord)

wcalc <- seq(20, 500, by=1)

kl_div_vect_FDL <- calc_cont_kl_div_vect(th_w_FDL_hetero,
                                         mod_spec_FDL_hetero,
                                         xcalc,
                                         wcalc)
mi_cont <-
  foreach(n=1:length(xmi), .multicombine=T) %dopar% {
     calc_univ_cont_mi(th_w_FDL_hetero,
                       mod_spec_FDL_hetero,
                       xmi[n],
                       wcalc,
                       kl_div_vect_FDL)
  }
mi_cont <- unlist(mi_cont)
pdf(file.path("results","FigS3_FDL_to_ordinal_mi.pdf"))
  plot(xmi, mi_ord, ylim=c(0,max(mi_ord, mi_cont)),
       xlab= "Age [years]", ylab="Mutual Information",
       type="l", lwd=2, col="grey")
  lines(xmi, mi_cont, lwd=2)
  legend("topright",
         c("FDL", "FDL [as ordinal]"),
         col=c("black", "grey"),
         lty=1)
dev.off()

print("Range of information loss (proportion of cont. model)")
print(range((mi_cont-mi_ord)/mi_cont))

## Table S3
# Generate univariate CI's for ordinal response variables
seed_val <- 224073
for (j in 1:problem$mod_spec$J) {
  var_name <- problem$var_names[j]
  print(paste0("Point Estimate and Confidence Intervals for ",var_name,": "))
  ord_ci_table <- generate_ord_ci(data_dir,
                                  analysis_name,
                                  j=j,
                                  "HME_EF",
                                  th_x,
                                  input_seed=seed_val,
                                  save_file=TRUE)
  print(ord_ci_table)
}

# Close all clusters used for parallel processing
stopImplicitCluster()

# End the re-directing of print statements to file
sink()