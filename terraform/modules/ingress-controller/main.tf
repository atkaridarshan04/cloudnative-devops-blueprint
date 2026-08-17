# Policy JSON is the upstream file from
# https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/main/docs/install/iam_policy.json

resource "aws_iam_policy" "alb_controller" {
  name        = "AWSLoadBalancerControllerIAMPolicy-${var.cluster_name}"
  description = "IAM policy for the AWS Load Balancer Controller"
  policy      = file("${path.module}/iam_policy.json")
  tags        = var.tags
}

# IRSA, not EKS Pod Identity: this account's SSO role's iam:PassRole is
# scoped to a fixed iam:PassedToService allow-list that doesn't include
# pods.eks.amazonaws.com, so CreatePodIdentityAssociation gets denied.
# IRSA has the pod assume the role directly via STS using the OIDC token -
# no PassRole call involved, so it isn't affected by that restriction.
module "irsa" {
  source = "../irsa-role"

  role_name         = "${var.cluster_name}-alb-controller"
  oidc_provider_arn = var.oidc_provider_arn
  oidc_provider     = var.oidc_provider
  namespace         = "kube-system"
  service_account   = "aws-load-balancer-controller"
  policy_arns       = [aws_iam_policy.alb_controller.arn]

  tags = var.tags
}

resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = var.chart_version
  namespace  = "kube-system"

  set = [
    { name = "clusterName", value = var.cluster_name },
    { name = "region", value = var.region },
    { name = "vpcId", value = var.vpc_id },
    { name = "serviceAccount.create", value = "true" },
    { name = "serviceAccount.name", value = "aws-load-balancer-controller" },
    # IRSA - tells the pod which role to assume via the OIDC-federated STS call
    { name = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn", value = module.irsa.role_arn },
  ]
}
