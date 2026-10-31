# =============================================================================
# TERRAFORM AND PROVIDER VERSIONS
# =============================================================================

terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 3.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0"
    }
    time = {
      source  = "hashicorp/time"
      version = ">= 0.9"
    }
    null = {
      source  = "hashicorp/null"
      version = ">= 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0"
    }
  }
}

# =============================================================================
# PROVIDER CONFIGURATIONS
# =============================================================================

provider "aws" {
  region = var.aws_region
}

provider "helm" {
  kubernetes = {
    host                   = module.book_app_eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.book_app_eks.cluster_certificate_authority_data)
    exec = {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", module.book_app_eks.cluster_name]
    }
  }
}

provider "kubernetes" {
  host                   = module.book_app_eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.book_app_eks.cluster_certificate_authority_data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.book_app_eks.cluster_name]
  }
}
