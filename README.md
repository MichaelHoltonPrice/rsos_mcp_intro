# Reproducible publication results with Docker
This repository contains the source code for our paper:

> Stull, K.E., Chu, E.Y., Corron, L.K., & Price, M.H. (2023). *The Mixed
 Cumulative Probit: A multivariate generalization of transition analysis that
 accommodates variation in the shape, spread, and structure of data.* Royal
 Society Open Science.  

This repository provides the exact source code used to create publication
results. Since we created the results, we have improved the yada package to
have a better pipeline for optimizing and using Mixed Cumulative Probit (MCP)
models. This updated, bleeding edge approach is described here:

[https://rpubs.com/elainechu/mcp_vignette](https://rpubs.com/elainechu/mcp_vignette)

Since we originaly ran the code to create publication results, devtools was
updated to require some new dependencies. Hence, we have updated the
Dockerfile. Aside from that, this repository contains our exact code used to
create publication results. That being said, there is some chance that the
results will differ slightly from those we published since we are using some
different package versions (though we have no specific evidence that this is
so).

There are two ways to run the code, both of which use Docker: (1) build a new
Docker image using the Dockerfile that is provided with this repository; or (2)
use the image we placed on Docker Hub in February, 2023. These approaches only
diverge in the ininitial stage. Approach (2) is the best approach for
reproducibility (and likely just easier). At the end of the section for
Approach (1), we describe the steps we used to create the image used in
approach (2). With approach (1), it is likely that additional depependencies
will be will need to be resolved the longer it is from February, 2023. This is
why we have provided approach (2), so that the exact Docker image we created in
February, 2023, can be used.

These instructions assume use of the command line (e.g., Windows Powershell
Mac terminal or Linux terminal) with Docker installed. The commands listed
below should be copied and run in order at the command line.

# Some notes on commits
The actual commit of this repository used to create publication results was:

5acab63201671a1abac89102b8f1b46285141860

Since then we have changed the name of the repository, improved the
documentation, and updated the Dockerfile to account for the new devtools 
dependencies. These are ``cosmetic'' changes and the analysis code remains
unchanged. The commit of yada use for the analysis results was:

b16034db9d81e59642ffda029ade8f91df669846 (this is on yada's dev branch)

# Approach (1): Build a new Docker image "from scratch"

Clone the github repository and enter the new directory:

```console
git clone https://github.com/MichaelHoltonPrice/rsos_mcp_intro
cd rsos_mcp_intro
```

Build the Docker image using the Dockerfile. To force all docker material to
be (re)downloaded prior to creating the Docker image -- a step you should be
certain you want to take -- use: "docker system prune -a".

```console
docker build -t michaelholtonprice/rsos_mcp_intro .
```

This will create a Linux image (Ubuntu 20.04), install R, install necessary
dependencies, copy data and script files into the Docker image, and install R
using the script install_yada.R that is part of this repository (specifically,
commit b16034db9d81e59642ffda029ade8f91df669846 of yada is installed).

The remainder of this section describes the steps we took to commit the image
on Docker Hub in February, 2023. To continue with the analysis pipeline, SKIP 
TO the section "Common steps." (There is no need to run the remaining commands
in this section, though you could certainly replicate the Docker image
push if desired with the next two commands, replacing michaelholtonprice
everywhere with your Docker username; you would first need to create a new
repository named rsos_mcp_intro to receive the push using the Docker Hub
website.)

We added a descriptive tag for the image, which had the ID 13dfdc296300 (this
can be found with "docker image ls"), and pushed it to Michael Holton Price's
Docker Hub repository (a new repository named rsos_mcp_intro was first created
using the Docker Hub website):

```console
docker tag 13dfdc296300 michaelholtonprice/rsos_mcp_intro:post_build
docker push michaelholtonprice/rsos_mcp_intro:post_build
```

# Approach (2): Use the Docker image on Docker Hub

Pull (download) the Docker image:

```console
docker pull michaelholtonprice/rsos_mcp_intro:post_build
```

In fact, the preceding command can probably be skipped since the
"docker run..." command in the following section will pull the image if it has
not already been pulled . However, it is useful to pull it separately to
understand what is happening.

# Common steps
Start a Docker container of the image michaelholtonprice/rsos_mcp_intro:post_build
using the following command:

```console
docker run --name rsos_mcp_intro -itv //c/rsos_mcp_intro_mirrored_dir:/mirrored_dir michaelholtonprice/rsos_mcp_intro:post_build
```

The preceding command places the user at a command line "inside" the Docker
container. The -v tag in the command mirrors a directory on the host machine

(C:\rsos_mcp_intro_mirrored_dir) to a directory inside the Docker container
(/mirrored_dir) that can be used to pass files between the host machine and the
Docker container. The directory to the left of the semicolon is for the host
machine and the directory to the right of the semicolon is for the Docker
container. The path for the host machine may need to be modified for your
situation.

Change directory (cd) into rsos_mcp_intro (where files were copied during
creation of the Docker image; see the Dockerfile) and run all the analyses
and result generation scripts (this will take a very long time -- likely over
a week):

```console
cd rsos_mcp_intro
Rscript run_all_analyses.R
```

Finally, copy the results to the mirrored directory:

```console
cp -fr ./results /mirrored_dir
```