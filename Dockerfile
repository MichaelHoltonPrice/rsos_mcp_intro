# The following two commands can be used to build the Docker image and start a
# container. The -v tag mirrors a folder on the host machine with the
# /mirrored_dir folder in the Docker container.
#
# docker build -t michaelholtonprice/stulletal_mcp .
# docker run --name stulletal_mcp -itv //c/stulletal_mcp_mirrored_dir:/mirrored_dir michaelholtonprice/stulletal_mcp
#
# If desired, the following command starts a container without mirroring a
# directory on the host machine:
#
# docker run --name stulletal_mcp -it michaelholtonprice/stulletal_mcp
FROM ubuntu:20.04

# Set the following environmental variable to avoid interactively setting the
# timezone with tzdata when installing R
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y vim && \
    apt-get install -y git && \
    apt-get install -y apt-transport-https && \
    apt-get install -y software-properties-common && \
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E298A3A825C0D65DFD57CBB651716619E084DAB9 && \
    add-apt-repository 'deb https://cloud.r-project.org/bin/linux/ubuntu focal-cran40/' && \
    apt-get update && \
    apt-get install -y r-base && \
    apt-get install -y libcurl4-openssl-dev && \
    apt-get install -y libssl-dev && \
    apt-get install -y libxml2-dev && \
    apt-get install -y pandoc && \
    apt-get clean

# Make directories
RUN mkdir stulletal_mcp
RUN mkdir stulletal_mcp/results
RUN mkdir stulletal_mcp/data

# Copy input files
COPY /data/SVAD_US.csv /stulletal_mcp/data/SVAD_US.csv
COPY /data/US_var_info.csv /stulletal_mcp/data/US_var_info.csv

# Copy .R files
COPY install_yada.R /stulletal_mcp/install_yada.R
COPY make_multivariate_crossval_results.R /stulletal_mcp/make_multivariate_crossval_results.R
COPY make_publication_results.R /stulletal_mcp/make_publication_results.R
COPY make_univariate_crossval_results.R /stulletal_mcp/make_univariate_crossval_results.R
COPY run_all_analyses.R /stulletal_mcp/run_all_analyses.R
COPY solvex_US.R /stulletal_mcp/solvex_US.R
COPY solvey_US_multivariate.R /stulletal_mcp/solvey_US_multivariate.R
COPY solvey_US_univariate.R /stulletal_mcp/solvey_US_univariate.R
COPY write_US_problems.R /stulletal_mcp/write_US_problems.R

# Install the specific yada commit that was used for publication with the
# following file. This also install dplyr and ggplot2.
RUN Rscript stulletal_mcp/install_yada.R

#WORKDIR /yada

# Install yada by running the install_yada.R script