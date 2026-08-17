module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 6.5.0"

  name = var.name
  cidr = var.vpc_cidr

  azs = var.azs

  # /20 each - worker nodes & pods (e.g. 10.0.0.0/16 -> 10.0.0.0/20, 10.0.16.0/20)
  private_subnets = [for k, v in var.azs : cidrsubnet(var.vpc_cidr, 4, k)]
  # /24 each - internet-facing side, NAT gateway + public-facing LBs (-> 10.0.48.0/24, 10.0.49.0/24)
  public_subnets = [for k, v in var.azs : cidrsubnet(var.vpc_cidr, 8, k + 48)]
  # /24 each - no NAT/IGW route at all; EKS control plane's cross-account ENIs only (-> 10.0.52.0/24, 10.0.53.0/24)
  intra_subnets = [for k, v in var.azs : cidrsubnet(var.vpc_cidr, 8, k + 52)]

  enable_nat_gateway = true
  single_nat_gateway = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
    # "shared" tells the AWS Load Balancer Controller / in-tree LB provisioning
    # these subnets belong to this cluster and are safe to place LBs into
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
    # same discovery tag, for internal-facing load balancers
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }

  tags = var.tags
}
