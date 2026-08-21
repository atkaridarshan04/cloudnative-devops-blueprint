# Velero's helm_release needs the Terraform-computed IRSA role ARN in its own values at
# install time (same reason as ../ingress-controller) - the "helm" provider connection is
# configured in the root providers.tf, a module can use a provider, but can't configure one.

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
