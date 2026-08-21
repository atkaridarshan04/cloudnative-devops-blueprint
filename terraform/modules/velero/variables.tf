variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "oidc_provider_arn" {
  description = "ARN of the cluster's IAM OIDC provider (for IRSA trust policy)"
  type        = string
}

variable "oidc_provider" {
  description = "Issuer host of the cluster's IAM OIDC provider (for IRSA trust policy)"
  type        = string
}

variable "region" {
  description = "AWS region, for the backup storage location config"
  type        = string
}

variable "values_file" {
  description = "Path to the velero helm chart's values file"
  type        = string
}

variable "chart_version" {
  description = "velero helm chart version"
  type        = string
  default     = "12.1.0" # check `helm search repo vmware-tanzu/velero --versions` for newer
}

variable "tags" {
  description = "Tags applied to the IAM/S3 resources"
  type        = map(string)
  default     = {}
}
