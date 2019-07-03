# Provider Configuration


provider "aws" {
  region = "us-east-1"
}

data "aws_region" "current" {}

data "aws_availability_zones" "available" {}

# Used with icanhazip.com to determine local workstation external IP
# to open EC2 Security Group access to the Kubernetes cluster.
provider "http" {}