# AWS Load Balancer Controller: IAM (IRSA) + the helm release itself.
# The "helm" provider connection (host/token/ca cert) is configured in the
# root providers.tf - a module can use a provider, but can't configure one.

terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
    helm = {
      source = "hashicorp/helm"
    }
  }
}
