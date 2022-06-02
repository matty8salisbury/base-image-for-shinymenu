#ShinyMenu Base Image Dockerfile

FROM ubuntu:20.04

# LABEL about the custom image
LABEL maintainer="matt@shinymenu.online"
LABEL description="This is the base image for shiny menu. Includes DOCKER, R BASE, SHINY, REQUIRED R PACKAGES, MYSQL, LIBMARIADB, NGINX AND CERTBOT" 

ENV TZ=Europe/London
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
RUN apt-get update && apt-get install -y tzdata

#ARG DEBIAN_FRONTEND=noninteractive

#1. INSTALL DOCKER
RUN apt-get update && apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
RUN echo \
  "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

RUN apt-get update && apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin -y

#2. INSTALL MARIADB ON VM

RUN apt-get update && apt-get install mariadb-server -y

#3. INSTALL R

#LINK UBUNTU TO CRAN TO ENSURE LATEST VERSION
# update indices
RUN apt update -qq -y
# install two helper packages we need
RUN apt install --no-install-recommends software-properties-common dirmngr -y
# add the signing key (by Michael Rutter) for these repos
# To verify key, run gpg --show-keys /etc/apt/trusted.gpg.d/cran_ubuntu_key.asc 
# Fingerprint: E298A3A825C0D65DFD57CBB651716619E084DAB9
RUN apt-get install wget -y
RUN wget -qO- https://cloud.r-project.org/bin/linux/ubuntu/marutter_pubkey.asc | tee -a /etc/apt/trusted.gpg.d/cran_ubuntu_key.asc
# add the R 4.0 repo from CRAN -- adjust 'focal' to 'groovy' or 'bionic' as needed
RUN add-apt-repository "deb https://cloud.r-project.org/bin/linux/ubuntu $(lsb_release -cs)-cran40/"
RUN apt install --no-install-recommends r-base -y

RUN add-apt-repository ppa:c2d4u.team/c2d4u4.0+ -y
RUN apt install --no-install-recommends r-cran-rstan -y
RUN apt install --no-install-recommends r-cran-tidyverse -y

#4. INSTALL R AND SHINY

RUN apt-get update && apt-get install r-base-dev -y
RUN su - \
-c "R -e \"install.packages('shiny', repos='https://cran.rstudio.com/')\""
RUN apt-get install gdebi-core -y
RUN wget https://download3.rstudio.org/ubuntu-18.04/x86_64/shiny-server-1.5.18.987-amd64.deb
RUN gdebi shiny-server-1.5.18.987-amd64.deb

#5. INSTALL REQUIRED PACKAGES
RUN apt-get update && apt-get install libmariadb-dev -y
RUN R -e "install.packages(c('shiny', 'shinyWidgets' ,'DT', 'RMariaDB', 'DBI', 'shinyalert', 'qrcode', 'xtable'))"

#6. INSTALL NGINX ON VM
RUN apt install nginx -y
