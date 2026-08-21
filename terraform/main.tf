module "vpc" {
  source       = "./modules/vpc"
  name         = "${local.name}-vpc"
  cluster_name = local.name
  vpc_cidr     = local.vpc_cidr
  azs          = local.azs
  tags         = local.tags
}

module "eks" {
  source             = "./modules/eks"
  cluster_name       = local.name
  kubernetes_version = local.kubernetes_version

  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.intra_subnets

  node_instance_types = local.node_instance_types
  node_min_size       = local.node_min_size
  node_max_size       = local.node_max_size
  node_desired_size   = local.node_desired_size

  tags = local.tags
}

module "ingress_controller" {
  source            = "./modules/ingress-controller"
  cluster_name      = local.name
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_provider     = module.eks.oidc_provider
  region            = local.region
  vpc_id            = module.vpc.vpc_id
  tags              = local.tags

  # controller pods need the node group up to actually schedule
  depends_on = [module.eks]
}

module "ebs_csi" {
  source            = "./modules/ebs-csi"
  cluster_name      = local.name
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_provider     = module.eks.oidc_provider
  tags              = local.tags

  depends_on = [module.eks]
}

module "velero" {
  source            = "./modules/velero"
  cluster_name      = local.name
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_provider     = module.eks.oidc_provider
  region            = local.region
  values_file       = "${path.module}/../velero/values.yaml"
  tags              = local.tags

  depends_on = [module.eks]
}

module "argocd" {
  source        = "./modules/argocd"
  chart_version = local.argocd_chart_version

  values_file             = "${path.module}/../argocd/values.yaml"
  gateway_api_crds_file   = "${path.module}/../gateway/gateway-api-crds.yaml"
  httproute_file          = "${path.module}/../argocd/httproute.yml"
  book_store_project_file = "${path.module}/../argocd/project.yml"
  platform_project_file   = "${path.module}/../argocd/platform-project.yml"
  root_application_file   = "${path.module}/../argocd/root-application.yml"

  depends_on = [module.eks]
}
