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
  node_min_size       = 3
  node_max_size       = 10
  # t3a.medium caps at 17 pods/node (ENI/IP-based via the VPC CNI, not a resource limit) —
  # 3 nodes (51 slots) is already fully saturated by system pods + this platform's ~15
  # Applications. 5 uses the max_size headroom already allowed instead of raising it again.
  node_desired_size = 5

  # 10.4.0 bundles ArgoCD v3.5.1, which includes the Kubernetes 1.35 Go client upgrade —
  # earlier versions can't compute a sync diff on StatefulSets at all on this cluster
  # (structured-merge-diff doesn't recognize k8s 1.35's new .status.terminatingReplicas
  # field), showing every affected Application stuck at sync status Unknown.
  argocd_chart_version = "10.4.0"

  tags = {
    Owner       = "Darshan Atkari"
    ManagedBy   = "Terraform"
    Project     = "cloudnative-devops-blueprint"
    Environment = "prod"
  }
}
