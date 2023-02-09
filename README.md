# Reproducible publication results with Docker
This repository contains the source code for our paper:

> Stull, K.E., Chu, E.Y., Corron, L.K., & Price, M.H. (2023). *The Mixed
 Cumulative Probit: A multivariate generalization of transition analysis that
 accommodates variation in the shape, spread, and structure of data.* Royal
 Society Open Science.  

This README is specifically for a branch of the github repository named pub. It
provides the exact source code used to create publication results. The main
branch of the repository, in contrast, contains code that has been updated to
work with a more recent version of yada (though we will no longer update even
the main branch after February, 2023).

Since we originaly ran the code to create publication results, devtools was
updated to require some new dependencies. Hence, we have updated the
Dockerfile. Aside from this, this pub branch of the repository contains our
exact code and pipeline used for the publication results. That being said,
there is some chance that the results will differ slightly from those we
published since we are using some different package versions, though we have
no specific evidence that this is so. We have maintained the old name for
the repository (stulletal_mcp) to most closely match the publication approach
(i.e., the old name stulletal_mcp was not updated to the new name,
mcp_pipeline).

There are two ways to run the code, both of which use Docker: (1) build a new
Docker image using the Dockerfile that is provided with this repository; or (2)
use the image we placed on Docker Hub in February, 2023. These approaches only
diverge in the ininitial stage. Approach (2) is the best approach for
reproducibility. At the end of the section for Approach (1), we describe the
steps we used to create the image used in approach (2). With approach (1), it
is likely that additional depependencies will be will need to be resolved the
longer it is from February, 2023. This is why we have provided approach (2), so
that the exact Docker image we created in February, 2023, can be used.

# Approach (1): Build a new Docker image "from scratch"

Clone the github repository, enter the new directory, and switch to the pub
branch:

```console
git clone https://github.com/ElaineYChu/stulletal_mcp
cd stulletal_mcp
git checkout pub
```

Build the Docker image using the Dockerfile. To force all docker material to
be (re)downloaded prior to creating the Docker image -- a step you should be
certain you want to take -- use: "docker system prune -a".

```console
docker build -t michaelholtonprice/stulletal_mcp .
```

This will create a Linux image (Ubuntu 20.04), install R, install necessary
dependencies, copy data and script files into the Docker image, and install R
using the script install_yada.R that is part of this repository (specifically,
commit b16034db9d81e59642ffda029ade8f91df669846 of yada is installed).

The remainder of this section describes the steps we took to commit the image
on Docker Hub in February, 2023. To continue with analysis pipeline, skip to
the section "Common steps." There is NO NEED to run the remaining commands in
this section. They are here only for documentation.

We added a descriptive tag for the image, which had the ID df9237b5b72f, and
pushed it to Michael Holton Price's Docker Hub repository (a new repository
named stulletal_mcp was first created using the Docker Hub website):

```console
docker tag df9237b5b72f michaelholtonprice/stulletal_mcp:post_build
docker push michaelholtonprice/stulletal_mcp:post_build
```

# Approach (2): Use the Docker image on Docker Hub

# Common steps