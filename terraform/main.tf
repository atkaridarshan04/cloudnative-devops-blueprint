module "vpc" {
  source = "./modules/vpc"

  cluster_name       = local.cluster_name
  vpc_cidr           = var.vpc_cidr
  azs                = local.azs
  single_nat_gateway = var.enable_single_nat_gateway
  tags               = local.common_tags
}

module "eks" {
  source = "./modules/eks"

  cluster_name       = local.cluster_name
  kubernetes_version = var.kubernetes_version
  vpc_id             = module.vpc.vpc_id
  vpc_cidr           = module.vpc.vpc_cidr_block
  private_subnets    = module.vpc.private_subnets
  tags               = local.common_tags
}

module "addons" {
  source = "./modules/addons"

  cluster_name     = module.eks.cluster_name
  cluster_endpoint = module.eks.cluster_endpoint
  cluster_version  = module.eks.cluster_version

  depends_on = [module.eks]
}

module "gitops" {
  source = "./modules/gitops"

  argocd_namespace     = var.argocd_namespace
  argocd_chart_version = var.argocd_chart_version

  depends_on = [module.addons]
}
