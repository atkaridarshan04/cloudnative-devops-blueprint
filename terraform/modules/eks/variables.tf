variable "cluster_name" {
  type = string
}

variable "kubernetes_version" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "vpc_cidr" {
  type = string
}

variable "private_subnets" {
  type = list(string)
}

variable "cluster_enabled_log_types" {
  type    = list(string)
  default = []
}

variable "tags" {
  type    = map(string)
  default = {}
}
