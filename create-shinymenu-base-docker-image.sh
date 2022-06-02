#!/bin/bash

#ABOUT:
#Script to generate the base docker image for the simplets implementation of the shinymenu app suite
#This script does not put the apps in place or deal with any customisation.  It creates the necessary image from which to do those things.

#AUTHOR: Matt Salisbury
#DATE: 20220602
#VERSION: 1.0
#DEPENDENCIES: Needs Google SDK installed and is for matt@shinymenu.online

#1. LOGIN, SET PROJECT AND ENABLE APIS

gcloud auth login matt@shinymenu.online
gcloud config set project shinymenu-test-01

gcloud services enable compute.googleapis.com
gcloud services enable containerregistry.googleapis.com
gcloud services enable servicenetworking.googleapis.com
gcloud services enable sqladmin.googleapis.com
gcloud services enable cloudresourcemanager.googleapis.com

#2. CREATE VM
#TAG WITH NAME TO ALLOW FIREWALL RULES TO BE APPLIED IF NEEDED
#MACHINE TYPE EC2-MED
#ZONE europe-west2-c

#CREATE VM WITH THE SERVICE ACCOUNT SPECIFIED
gcloud compute instances create shinymenu-build-base-docker-image-vm \
--project=shinymenu-test-01 \
--zone=europe-west2-c \
--machine-type=e2-medium \
--service-account=vm1-sa-000@shinymenu-test-01.iam.gserviceaccount.com \
--scopes=https://www.googleapis.com/auth/cloud-platform \
--image=projects/ubuntu-os-cloud/global/images/ubuntu-2004-focal-v20220419 \
--metadata startup-script='
    !# bin/bash
    
    #A. install docker

    sudo apt-get remove docker docker-engine docker.io containerd runc
    sudo apt-get update && sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo \
      "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    sudo apt-get update && sudo apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin
    sudo docker run hello-world

    sudo usermod -a -G docker $vm1-sa-001@shinymenu-test-01.iam.gserviceaccount.com

    #B. create mydocker directory and cd into into
    
    mkdir mydocker
    cd mydocker

    #C. download dockerfile from github

    git clone https://github.com/matty8salisbury/base-image-for-shinymenu.git

    #D. build docker image

    sudo docker build -t shinymenu_base_image .
    
    #E. push docker image to gcp container repo

    sudo docker tag shinymenu_base_image gcr.io/shinymenu-test-01/shinymenu_base_image
    sudo docker push gcr.io/shinymenu-test-01/shinymenu_base_image
    
    #f. push docker image to dockerhub

    #sudo docker login
    #sudo docker tag shinymenu_base_image matty8salisbury/shinymenu_base_image
    #sudo docker push matty8salisbury/shinymenu_base_image
    '

#3. DELETE VM

#gcloud compute instances delete shinymenu-build-base-docker-image-vm --zone=europe-west2-c
