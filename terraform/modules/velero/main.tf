# S3 bucket for backups + the IRSA role Velero authenticates as. The EC2 snapshot actions
# below look redundant with the EBS CSI driver's own IRSA role (../ebs-csi,
# AmazonEBSCSIDriverPolicy) - the CSI driver is what actually creates/deletes the EBS
# snapshot, not Velero - but velero-plugin-for-aws's own documented policy (and AWS's own
# EKS+Velero backup guide) grants these to Velero's role uniformly regardless of CSI vs.
# native snapshots, for its own bookkeeping (tagging, describing, backup-sync/expiry
# reconciliation). Kept as documented rather than trimmed on an unverified assumption.

resource "aws_s3_bucket" "backups" {
  bucket = "${var.cluster_name}-velero-backups"
  tags   = var.tags

  # Deliberately not force_destroy: a `terraform destroy` that silently deletes every
  # backup along with the cluster defeats the point of having them. See README's
  # "Tear down" section - empty this bucket yourself first if that's really the intent.
}

resource "aws_s3_bucket_versioning" "backups" {
  bucket = aws_s3_bucket.backups.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "backups" {
  bucket = aws_s3_bucket.backups.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "backups" {
  bucket                  = aws_s3_bucket.backups.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

data "aws_iam_policy_document" "velero" {
  statement {
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:PutObjectTagging",
      "s3:AbortMultipartUpload",
      "s3:ListMultipartUploadParts",
    ]
    resources = ["${aws_s3_bucket.backups.arn}/*"]
  }

  statement {
    actions = [
      "s3:ListBucket",
      "s3:GetBucketLocation",
      "s3:GetBucketVersioning",
    ]
    resources = [aws_s3_bucket.backups.arn]
  }

  # EBS snapshot bookkeeping - see the header comment on why this is granted even though
  # the CSI driver's own role performs the actual CreateSnapshot/DeleteSnapshot call.
  statement {
    actions = [
      "ec2:DescribeVolumes",
      "ec2:DescribeSnapshots",
      "ec2:DescribeVolumeAttribute",
      "ec2:DescribeVolumesModifications",
      "ec2:DescribeVolumeStatus",
      "ec2:DescribeTags",
      "ec2:CreateTags",
      "ec2:CreateSnapshot",
      "ec2:DeleteSnapshot",
    ]
    resources = ["*"] # EC2 describe/snapshot actions don't support resource-level scoping
  }
}

resource "aws_iam_policy" "velero" {
  name        = "${var.cluster_name}-velero"
  description = "S3 + EBS snapshot access for Velero"
  policy      = data.aws_iam_policy_document.velero.json
  tags        = var.tags
}

# IRSA, same reasoning as every other addon role in this project (../irsa-role's header
# comment) - this account's PassRole allow-list doesn't include pods.eks.amazonaws.com.
module "irsa" {
  source = "../irsa-role"

  role_name         = "${var.cluster_name}-velero"
  oidc_provider_arn = var.oidc_provider_arn
  oidc_provider     = var.oidc_provider
  namespace         = "velero"
  service_account   = "velero"
  policy_arns       = [aws_iam_policy.velero.arn]

  tags = var.tags
}

resource "helm_release" "velero" {
  name             = "velero"
  repository       = "https://vmware-tanzu.github.io/helm-charts"
  chart            = "velero"
  version          = var.chart_version
  namespace        = "velero"
  create_namespace = true

  values = [file(var.values_file)]

  # The three values values_file can't contain - each is only known after Terraform
  # creates the resource it comes from, merged on top of the static config above.
  set = [
    # IRSA - tells the pod which role to assume via the OIDC-federated STS call
    { name = "serviceAccount.server.annotations.eks\\.amazonaws\\.com/role-arn", value = module.irsa.role_arn },
    { name = "configuration.backupStorageLocation[0].bucket", value = aws_s3_bucket.backups.bucket },
    { name = "configuration.backupStorageLocation[0].config.region", value = var.region },
    { name = "configuration.volumeSnapshotLocation[0].config.region", value = var.region },
  ]
}
