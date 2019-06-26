#!/bin/bash

# Incoming Arguments definition
# $1 = github/repo path
# $2 = repo/path name
# $3 = deployment_directory
# $4 =  base_directory

# Local Variable Definitions
username=$(docker info | sed '/Username:/!d;s/.* //'); 
echo $username

#
# WORKS
#
[ -d ¨$3/$2/app/¨ ] && echo "" || mkdir -p $3/$2/app/
[ "$(ls -A $3/$2/app/)" ] && echo "" || git clone $1 $3/$2/app/
cp $4/resources/app/Dockerfile $3/$2/
mv $3/$2/app/run.py $3/$2/app/main.py
docker build $3/$2 -t $username/$2:latest
sleep 5
docker push $username/$2:latest

#
#Test
#
#docker save hostel > $2/hostel.tar

#
#WORKS
#
kubectl create deployment $2 --image=$username/$2:latest
kubectl expose deployment $2 --type=LoadBalancer --name=$2 --port=80
##kubectl describe svc hostel5lb
sleep 5
kubectl get svc $2 \
    -o custom-columns="NAME:.metadata.name,IP ADDRESS:.status.loadBalancer.ingress[0].hostname"