variable "role_name" {
  description = "IAM role name"
  type        = string
}

variable "oidc_provider_arn" {
  description = "ARN of the cluster's IAM OIDC provider"
  type        = string
}

variable "oidc_provider" {
  description = "Issuer host of the cluster's IAM OIDC provider"
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace of the service account this role is for"
  type        = string
}

variable "service_account" {
  description = "Kubernetes service account name this role is for"
  type        = string
}

variable "policy_arns" {
  description = "IAM policy ARNs to attach to the role"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags applied to the role"
  type        = map(string)
  default     = {}
}
