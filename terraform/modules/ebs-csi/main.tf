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

# CRDs (VolumeSnapshotClass/VolumeSnapshotContent/VolumeSnapshot) + the cluster-level
# controller that watches them - the driver addon above only ships its own csi-snapshotter
# sidecar, not this. Without it a VolumeSnapshot just sits with no VolumeSnapshotContent
# ever created. No IRSA: it only orchestrates in-cluster objects, the actual AWS API calls
# are made by the CSI driver above using its own role. Velero (../velero) is what actually
# creates VolumeSnapshots; this addon is what turns them into real EBS snapshots.
resource "aws_eks_addon" "snapshot_controller" {
  cluster_name = var.cluster_name
  addon_name   = "snapshot-controller"
  tags         = var.tags

  depends_on = [aws_eks_addon.ebs_csi]
}
