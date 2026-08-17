# IRSA trust policy shape, shared by every addon role in this project (ALB
# controller, EBS CSI driver, ...) - see modules/ingress-controller for why
# IRSA rather than EKS Pod Identity is used here.

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${var.oidc_provider}:sub"
      values   = ["system:serviceaccount:${var.namespace}:${var.service_account}"]
    }

    condition {
      test     = "StringEquals"
      variable = "${var.oidc_provider}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "this" {
  name               = var.role_name
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "this" {
  # Keyed by index, not the ARN itself — ingress-controller passes an ARN from a policy
  # this same apply creates (aws_iam_policy.alb_controller.arn), unknown until it's created.
  # The list's length is still static, so an index key keeps for_each valid.
  for_each = { for idx, arn in var.policy_arns : tostring(idx) => arn }

  role       = aws_iam_role.this.name
  policy_arn = each.value
}
