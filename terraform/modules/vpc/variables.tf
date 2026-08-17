variable "name" {
  description = "value"
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name, tagged onto subnets for load balancer controller discovery"
  type        = string
}

variable "vpc_cidr" {
  description = "value"
  type        = string
}

variable "azs" {
  description = "value"
  type        = list(string)
}

variable "tags" {
  description = "value"
  type        = map(string)
}
