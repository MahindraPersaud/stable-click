#!/bin/bash

#
# Incoming Arguments definition
# * $1 = github/repo path
# * $2 = deployment_directory
# * $3 =  base_directory
#

REPO=$1
REPO_NAME_UPPER=$(basename $1)
REPO_NAME=${REPO_NAME_UPPER,,}
DEPLOYMENT_DIRECTORY=$2
BASE_DIRECTORY=$3

#
# Local Variable Definitions
# * username = docker username of the current user
#

USERNAME=$(docker info | sed '/Username:/!d;s/.* //'); 

#
# Creation
# * Checks if the Application Directory exists, if not create it
# * Checks if the application repo is empty or not, if empty clone into it.
# * Copy the docker file over from stable-click cloned repo
# * Changes the run.py to main.py if it exists for Previous projects made for Gus' One-Click
#

[ -d ¨$DEPLOYMENT_DIRECTORY/$REPO_NAME/app/¨ ] && echo "" || mkdir -p $DEPLOYMENT_DIRECTORY/$REPO_NAME/app/
[ "$(ls -A $DEPLOYMENT_DIRECTORY/$REPO_NAME/app/)" ] && echo "" || git clone $REPO $DEPLOYMENT_DIRECTORY/$REPO_NAME/app/
cp $BASE_DIRECTORY/resources/app/Dockerfile $DEPLOYMENT_DIRECTORY/$REPO_NAME/
mv $DEPLOYMENT_DIRECTORY/$REPO_NAME/app/run.py $DEPLOYMENT_DIRECTORY/$REPO_NAME/app/main.py

#
# Docker
# * Image creation using the local username and project name
# * Image push to the dockerhub repo of the same name
#

docker build $DEPLOYMENT_DIRECTORY/$REPO_NAME -t $USERNAME/$REPO_NAME:latest
sleep 5
docker push $USERNAME/$REPO_NAME:latest

#
# Project Deployment
# * Create deployment using the image that was just pushed
# * Expose deployment to the world
# * Get the external IP of the application
#

kubectl create deployment $REPO_NAME --image=$USERNAME/$REPO_NAME:latest
kubectl expose deployment $REPO_NAME --type=LoadBalancer --name=$REPO_NAME --port=80
sleep 30
kubectl get svc $REPO_NAME \
    -o custom-columns="NAME:.metadata.name,IP ADDRESS:.status.loadBalancer.ingress[0].hostname"