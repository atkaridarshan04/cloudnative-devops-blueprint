# EBS CSI driver: IRSA (same reason as the ALB controller - this account's
# PassRole allow-list doesn't include pods.eks.amazonaws.com, so IRSA is
# used instead of EKS Pod Identity) + the EKS-managed addon itself.

module "irsa" {
  source = "../irsa-role"

  role_name         = "${var.cluster_name}-ebs-csi"
  oidc_provider_arn = var.oidc_provider_arn
  oidc_provider     = var.oidc_provider
  namespace         = "kube-system"
  service_account   = "ebs-csi-controller-sa"
  policy_arns       = ["arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"]

  tags = var.tags
}

resource "aws_eks_addon" "ebs_csi" {
  cluster_name             = var.cluster_name
  addon_name               = "aws-ebs-csi-driver"
  service_account_role_arn = module.irsa.role_arn
  tags                     = var.tags
}
