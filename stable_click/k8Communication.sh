#!/bin/bash

#
# Connecting Kubernetes master to worker nodes
# * Outputs the config file for kubeconfig
# * Outputs the config_map for aws authentication
# * Applys the config_map to the cluster
#

terraform output kubeconfig > ~/.kube/config
terraform output config_map_aws_auth > config-map-aws-auth.yaml
kubectl apply -f config-map-aws-auth.yaml
