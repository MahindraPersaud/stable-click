#!/bin/bash

#
# Incoming Arguments definition
# * $1 = github/repo path
#

REPO=$1
REPO_NAME_UPPER=$(basename $1)
REPO_NAME=${REPO_NAME_UPPER,,}

#
# Project Deletion
# * Delete the deployment using kubectl
# * Delete the exposed service. In this case the LoadBalancer
#

kubectl delete deployment $REPO_NAME
kubectl delete svc $REPO_NAME 