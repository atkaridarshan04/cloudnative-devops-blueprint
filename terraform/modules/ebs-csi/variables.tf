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

variable "tags" {
  description = "Tags applied to the IAM resources"
  type        = map(string)
  default     = {}
}
