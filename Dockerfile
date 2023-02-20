# The following two commands can be used to build the Docker image and start a
# container. The -v tag mirrors a folder on the host machine with the
# /mirrored_dir folder in the Docker container.
#
# docker build -t michaelholtonprice/rsos_mcp_intro .
# docker run --name rsos_mcp_intro -itv //c/rsos_mcp_intro_mirrored_dir:/mirrored_dir michaelholtonprice/rsos_mcp_intro
#
# If desired, the following command starts a container without mirroring a
# directory on the host machine:
#
# docker run --name rsos_mcp_intro -it michaelholtonprice/rsos_mcp_intro
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
    # It's not clear which of the following installs are needed, and this may
    # be operating system specific, so include all of them in case somebody
    # copies these installs for another setting
    apt-get install -y libfontconfig1-dev && \
    apt-get install -y libharfbuzz-dev && \
    apt-get install -y libfribidi-dev && \
    apt-get install -y libfreetype6-dev && \
    #apt-get install -y libpng-dev && \
    apt-get install -y libtiff5-dev && \
    #apt-get install -y libjpeg-dev && \
    apt-get clean

# Make directories
RUN mkdir rsos_mcp_intro
RUN mkdir rsos_mcp_intro/results
RUN mkdir rsos_mcp_intro/data

# Copy input files
COPY /data/SVAD_US.csv /rsos_mcp_intro/data/SVAD_US.csv
COPY /data/US_var_info.csv /rsos_mcp_intro/data/US_var_info.csv

# Copy .R files
COPY install_yada.R /rsos_mcp_intro/install_yada.R
COPY make_multivariate_crossval_results.R /rsos_mcp_intro/make_multivariate_crossval_results.R
COPY make_publication_results.R /rsos_mcp_intro/make_publication_results.R
COPY make_univariate_crossval_results.R /rsos_mcp_intro/make_univariate_crossval_results.R
COPY run_all_analyses.R /rsos_mcp_intro/run_all_analyses.R
COPY solvex_US.R /rsos_mcp_intro/solvex_US.R
COPY solvey_US_multivariate.R /rsos_mcp_intro/solvey_US_multivariate.R
COPY solvey_US_univariate.R /rsos_mcp_intro/solvey_US_univariate.R
COPY write_US_problems.R /rsos_mcp_intro/write_US_problems.R

# Install the specific yada commit that was used for publication with the
# following file. This also install dplyr and ggplot2.
RUN Rscript rsos_mcp_intro/install_yada.R

#WORKDIR /yada

# Install yada by running the install_yada.R script