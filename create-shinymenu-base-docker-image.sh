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
gcloud services enable artifactregistry.googleapis.com

# CREATE AN ARTIFACT REGISTRY TO STORE DOCKER IMAGE
gcloud artifacts repositories create shinymenu-docker-repo --repository-format=docker \
--location=europe-west2 --description="Docker repository"

#2. CREATE VM
#TAG WITH NAME TO ALLOW FIREWALL RULES TO BE APPLIED IF NEEDED
#MACHINE TYPE EC2-MED
#ZONE europe-west2-c

#2.1 Create service account

gcloud iam service-accounts create vm1-sa-002 --display-name "shiny-menu-vm1-sa-002-service-account"

#2.2 Assign appropriate roles to the service account

gcloud projects add-iam-policy-binding shinymenu-test-01 --member serviceAccount:vm1-sa-002@shinymenu-test-01.iam.gserviceaccount.com --role roles/compute.instanceAdmin.v1
gcloud projects add-iam-policy-binding shinymenu-test-01 --member serviceAccount:vm1-sa-002@shinymenu-test-01.iam.gserviceaccount.com --role roles/iam.serviceAccountUser 
gcloud projects add-iam-policy-binding shinymenu-test-01 --member serviceAccount:vm1-sa-002@shinymenu-test-01.iam.gserviceaccount.com --role roles/storage.objectViewer 
gcloud projects add-iam-policy-binding shinymenu-test-01 --member serviceAccount:vm1-sa-002@shinymenu-test-01.iam.gserviceaccount.com --role roles/storage.admin
gcloud artifacts repositories add-iam-policy-binding shinymenu-docker-repo --location europe-west2 --member=serviceAccount:vm1-sa-002@shinymenu-test-01.iam.gserviceaccount.com --role=roles/artifactregistry.writer

#2.3 CREATE VM WITH THE SERVICE ACCOUNT SPECIFIED

gcloud compute instances create shinymenu-build-base-docker-image-vm \
--project=shinymenu-test-01 \
--zone=europe-west2-c \
--machine-type=e2-standard-4 \
--service-account=vm1-sa-002@shinymenu-test-01.iam.gserviceaccount.com \
--scopes=https://www.googleapis.com/auth/cloud-platform \
--image=projects/ubuntu-os-cloud/global/images/ubuntu-2004-focal-v20220419 \
--metadata startup-script='!# bin/bash
    
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

    sudo apt-get update && sudo apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin -y
    sudo docker run hello-world

    sudo usermod -a -G docker $vm1-sa-002@shinymenu-test-01.iam.gserviceaccount.com
    
    #configure docker for use with google cloud artifacts repository
    gcloud auth configure-docker europe-west2-docker.pkg.dev -q
    
    #B. download dockerfile from github

    git clone https://github.com/matty8salisbury/base-image-for-shinymenu.git
    
    #C. create mydocker directory and cd into into
    
    sudo mkdir mydocker
    sudo cp /base-image-for-shinymenu/Dockerfile /mydocker
    cd /mydocker
    
    #D. build docker image

    sudo docker build -t shinymenu_base_image .
    
    #E. push docker image to gcp container repo

    sudo docker tag shinymenu_base_image europe-west2-docker.pkg.dev/shinymenu-test-01/shinymenu-docker-repo/shinymenu_base_image:tag1
    sudo docker push europe-west2-docker.pkg.dev/shinymenu-test-01/shinymenu-docker-repo/shinymenu_base_image:tag1
    
    #f. push docker image to dockerhub

    #sudo docker login
    #sudo docker tag shinymenu_base_image matty8salisbury/shinymenu_base_image
    #sudo docker push matty8salisbury/shinymenu_base_image
    '

#3. DELETE VM

gcloud compute instances delete shinymenu-build-base-docker-image-vm --zone=europe-west2-c -q
