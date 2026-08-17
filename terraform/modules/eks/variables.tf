variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version for the cluster"
  type        = string
}

variable "vpc_id" {
  description = "VPC to launch the cluster in"
  type        = string
}

variable "subnet_ids" {
  description = "Subnets for worker nodes / pod ENIs (private subnets)"
  type        = list(string)
}

variable "control_plane_subnet_ids" {
  description = "Subnets for the EKS control plane's cross-account ENIs (intra subnets)"
  type        = list(string)
}

variable "node_instance_types" {
  description = "Instance types for the managed node group"
  type        = list(string)
}

variable "node_min_size" {
  description = "Managed node group min size"
  type        = number
}

variable "node_max_size" {
  description = "Managed node group max size"
  type        = number
}

variable "node_desired_size" {
  description = "Managed node group desired size"
  type        = number
}

variable "tags" {
  description = "Tags applied to the cluster and its resources"
  type        = map(string)
  default     = {}
}
