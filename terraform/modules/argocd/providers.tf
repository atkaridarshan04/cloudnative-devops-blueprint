# ArgoCD install + the bootstrap manifests that can't be GitOps-managed by ArgoCD itself
# (see argocd/root-application.yml and argocd/platform-project.yml's own comments on why).
# The "helm"/"kubectl" provider connections are configured in the root providers.tf - a
# module can use a provider, but can't configure one.

terraform {
  required_providers {
    helm = {
      source = "hashicorp/helm"
    }
    kubectl = {
      source = "alekc/kubectl"
    }
    time = {
      source = "hashicorp/time"
    }
  }
}
