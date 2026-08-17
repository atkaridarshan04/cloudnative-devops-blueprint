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
  description = "AWS region, passed to the controller chart"
  type        = string
}

variable "vpc_id" {
  description = "VPC the cluster runs in, passed to the controller chart"
  type        = string
}

variable "chart_version" {
  description = "aws-load-balancer-controller helm chart version"
  type        = string
  default     = "3.5.0"
}

variable "tags" {
  description = "Tags applied to the IAM resources"
  type        = map(string)
  default     = {}
}
