data "aws_availability_zones" "available" {
  state = "available"
}

# NOTE: providers.tf uses data "aws_eks_cluster" which requires the cluster
# to exist. On first apply, use phased deployment (see docs/Terraform.md):
#   terraform apply -target=module.vpc -target=module.eks
#   terraform apply
locals {
  # Stable cluster name — no random suffix to avoid drift on re-apply
  cluster_name = "${var.cluster_name}-${var.environment}"

  azs = slice(data.aws_availability_zones.available.names, 0, 3)

  common_tags = {
    Environment = var.environment
    Project     = "book-store"
    ManagedBy   = "terraform"
  }
}
