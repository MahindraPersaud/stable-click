#!/bin/bash

terraform output kubeconfig > ~/.kube/config
terraform output config_map_aws_auth > config-map-aws-auth.yaml
kubectl apply -f config-map-aws-auth.yaml
