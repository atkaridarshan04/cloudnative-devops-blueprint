data "aws_availability_zones" "available" {
  # Exclude local zones
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}


locals {
  region = "ap-south-1"
  name   = "cndb-eks"

  vpc_cidr = "10.0.0.0/16"
  azs      = slice(data.aws_availability_zones.available.names, 0, 2)

  kubernetes_version = "1.35"

  node_instance_types = ["t3a.medium"]
  node_min_size       = 1
  node_max_size       = 5
  # t3a.medium caps at 17 pods/node (ENI/IP-based via the VPC CNI, not a resource limit) —
  # 3 nodes (51 slots) is already fully saturated by system pods + this platform's ~15
  # Applications. 5 uses the max_size headroom already allowed instead of raising it again.
  node_desired_size = 5

  # Check `helm search repo argo/argo-cd --versions` for the current one before applying —
  # not pinned to a known-good version here the way the other charts in this repo are.
  argocd_chart_version = "7.7.10"

  tags = {
    Owner       = "Darshan Atkari"
    ManagedBy   = "Terraform"
    Project     = "cloudnative-devops-blueprint"
    Environment = "prod"
  }
}
