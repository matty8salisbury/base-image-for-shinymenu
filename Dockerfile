#ShinyMenu Base Image Dockerfile

FROM ubuntu:20.04

# LABEL about the custom image
LABEL maintainer="matt@shinymenu.online"
LABEL version="0.1"
LABEL description="This is custom Docker Image for \
the base image for shiny menu. Includes DOCKER, R BASE, SHINY, REQUIRED R PACKAGES, MYSQL, LIBMARIADB, NGINX AND CERTBOT" 

#ARG DEBIAN_FRONTEND=noninteractive

#1. INSTALL DOCKER
RUN sudo apt-get update && sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
RUN echo \
  "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

RUN sudo apt-get update && sudo apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin
RUN sudo docker run hello-world

#2. INSTALL MARIADB ON VM

RUN sudo apt-get update && sudo apt-get install mariadb-server

# Make sure that NOBODY can access the server without a password
RUN sudo mysql -e "UPDATE mysql.user SET Password = PASSWORD('ciderBath271?') WHERE User = 'root'"
# Kill the anonymous users
RUN sudo mysql -e "DROP USER ''@'localhost'"
# Because our hostname varies we'll use some Bash magic here.
RUN sudo mysql -e "DROP USER ''@'$(hostname)'"
# Kill off the demo database
RUN sudo mysql -e "DROP DATABASE test"
# Make our changes take effect
RUN sudo mysql -e "FLUSH PRIVILEGES"
# Any subsequent tries to run queries this way will get access denied because lack of usr/pwd param

#3. INSTALL R

#LINK UBUNTU TO CRAN TO ENSURE LATEST VERSION
# update indices
RUN sudo apt update -qq
# install two helper packages we need
RUN sudo apt install --no-install-recommends software-properties-common dirmngr
# add the signing key (by Michael Rutter) for these repos
# To verify key, run gpg --show-keys /etc/apt/trusted.gpg.d/cran_ubuntu_key.asc 
# Fingerprint: E298A3A825C0D65DFD57CBB651716619E084DAB9
RUN sudo wget -qO- https://cloud.r-project.org/bin/linux/ubuntu/marutter_pubkey.asc | sudo tee -a /etc/apt/trusted.gpg.d/cran_ubuntu_key.asc
# add the R 4.0 repo from CRAN -- adjust 'focal' to 'groovy' or 'bionic' as needed
RUN sudo add-apt-repository "deb https://cloud.r-project.org/bin/linux/ubuntu $(lsb_release -cs)-cran40/"
RUN sudo apt install --no-install-recommends r-base

RUN sudo add-apt-repository ppa:c2d4u.team/c2d4u4.0+
RUN sudo apt install --no-install-recommends r-cran-rstan
RUN sudo apt install --no-install-recommends r-cran-tidyverse

#4. INSTALL R AND SHINY

RUN sudo apt-get update && sudo apt-get install r-base-dev
RUN sudo su - \
-c "R -e \"install.packages('shiny', repos='https://cran.rstudio.com/')\""
RUN sudo apt-get install gdebi-core
RUN wget https://download3.rstudio.org/ubuntu-18.04/x86_64/shiny-server-1.5.18.987-amd64.deb
RUN sudo gdebi shiny-server-1.5.18.987-amd64.deb

#5. INSTALL REQUIRED PACKAGES
RUN sudo apt-get update && sudo apt-get install libmariadb-dev
RUN sudo R -e "install.packages(c('shiny', 'shinyWidgets' ,'DT', 'RMariaDB', 'DBI', 'shinyalert', 'qrcode', 'xtable'))"

#6. INSTALL NGINX ON VM
RUN sudo apt install nginx -y

#7. INSTALL CERTBOT ON VM
RUN sudo snap install --classic certbot
RUN sudo ln -s /snap/bin/certbot /usr/bin/certbot
