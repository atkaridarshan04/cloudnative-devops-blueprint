variable "chart_version" {
  description = "argo-cd helm chart version"
  type        = string
}

variable "values_file" {
  description = "Path to argocd/values.yaml"
  type        = string
}

variable "gateway_api_crds_file" {
  description = "Path to gateway/gateway-api-crds.yaml — HTTPRoute must exist before argocd's own route below"
  type        = string
}

variable "httproute_file" {
  description = "Path to argocd/httproute.yml — ArgoCD's own route, not self-managed"
  type        = string
}

variable "book_store_project_file" {
  description = "Path to argocd/project.yml"
  type        = string
}

variable "platform_project_file" {
  description = "Path to argocd/platform-project.yml"
  type        = string
}

variable "root_application_file" {
  description = "Path to argocd/root-application.yml"
  type        = string
}
