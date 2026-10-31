# =============================================================================
# MONITORING STACK, ALERT DELIVERY AND DEAD MAN'S SWITCH
# =============================================================================
# All resources are gated by var.enable_monitoring.

locals {
  monitoring_count = var.enable_monitoring ? 1 : 0

  oidc_issuer = replace(module.book_app_eks.cluster_oidc_issuer_url, "https://", "")

  # pinned: the chart derives the rule selector and service-account name from it
  monitoring_release_name   = "monitoring"
  alertmanager_service_acct = "${local.monitoring_release_name}-kube-prometheus-alertmanager"
}

# =============================================================================
# SNS TOPICS
# =============================================================================

resource "aws_sns_topic" "alerts" {
  count = local.monitoring_count

  name = "${local.cluster_name}-alertmanager-alerts"
  tags = local.common_tags
}

# Receives the Watchdog heartbeat; only its publish metric is used
resource "aws_sns_topic" "heartbeat" {
  count = local.monitoring_count

  name = "${local.cluster_name}-alertmanager-heartbeat"
  tags = local.common_tags
}

# Notified by the heartbeat alarm; separate from alerts so a broken
# Alertmanager route cannot also silence the alarm
resource "aws_sns_topic" "ops" {
  count = local.monitoring_count

  name = "${local.cluster_name}-monitoring-ops"
  tags = local.common_tags
}

resource "aws_sns_topic_policy" "ops" {
  count = local.monitoring_count

  arn = aws_sns_topic.ops[0].arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "AllowCloudWatchAlarms"
      Effect    = "Allow"
      Principal = { Service = "cloudwatch.amazonaws.com" }
      Action    = "SNS:Publish"
      Resource  = aws_sns_topic.ops[0].arn
      Condition = {
        StringEquals = { "aws:SourceAccount" = data.aws_caller_identity.current.account_id }
      }
    }]
  })
}

# each address must confirm the AWS email before it receives anything
resource "aws_sns_topic_subscription" "alerts_email" {
  for_each = var.enable_monitoring ? toset(var.alert_email_addresses) : toset([])

  topic_arn = aws_sns_topic.alerts[0].arn
  protocol  = "email"
  endpoint  = each.value
}

resource "aws_sns_topic_subscription" "ops_email" {
  for_each = var.enable_monitoring ? toset(var.alert_email_addresses) : toset([])

  topic_arn = aws_sns_topic.ops[0].arn
  protocol  = "email"
  endpoint  = each.value
}

# =============================================================================
# IRSA ROLE FOR ALERTMANAGER
# =============================================================================

resource "aws_iam_role" "alertmanager" {
  count = local.monitoring_count

  name = "${local.cluster_name}-alertmanager-sns-publish"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = module.book_app_eks.oidc_provider_arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${local.oidc_issuer}:aud" = "sts.amazonaws.com"
          "${local.oidc_issuer}:sub" = "system:serviceaccount:monitoring:${local.alertmanager_service_acct}"
        }
      }
    }]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy" "alertmanager_sns_publish" {
  count = local.monitoring_count

  name = "sns-publish-alerts"
  role = aws_iam_role.alertmanager[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "sns:Publish"
      Resource = [aws_sns_topic.alerts[0].arn, aws_sns_topic.heartbeat[0].arn]
    }]
  })
}

# =============================================================================
# DEAD MAN'S SWITCH
# =============================================================================

# Fires when Alertmanager's 5m Watchdog heartbeat stops: the one signal that
# catches a dead alerting pipeline, where silence otherwise reads as healthy.
# treat_missing_data must stay "breaching": absence of data IS the alert.
resource "aws_cloudwatch_metric_alarm" "alertmanager_heartbeat_missing" {
  count = local.monitoring_count

  alarm_name        = "${local.cluster_name}-alertmanager-heartbeat-missing"
  alarm_description = "No Alertmanager heartbeat for 15 minutes. Alerts are NOT reaching SNS; treat as a monitoring outage, not a false positive. Runbook: docs/AlertRunbooks.md#heartbeat-missing"

  namespace   = "AWS/SNS"
  metric_name = "NumberOfMessagesPublished"
  dimensions  = { TopicName = aws_sns_topic.heartbeat[0].name }
  statistic   = "Sum"

  period              = 900
  evaluation_periods  = 1
  threshold           = 1
  comparison_operator = "LessThanThreshold"
  treat_missing_data  = "breaching"

  alarm_actions = [aws_sns_topic.ops[0].arn]
  ok_actions    = [aws_sns_topic.ops[0].arn]

  tags = merge(local.common_tags, { alarm_type = "alertmanager-heartbeat" })
}

# =============================================================================
# KUBE-PROMETHEUS-STACK
# =============================================================================

resource "helm_release" "monitoring" {
  count = local.monitoring_count

  name             = local.monitoring_release_name
  namespace        = "monitoring"
  create_namespace = true

  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = var.monitoring_chart_version
  timeout    = 900

  # later files win
  values = [
    file("${path.module}/../observability/monitoring/monitoring-values.yml"),
    file("${path.module}/../observability/monitoring/values-alerting.yml"),
    templatefile("${path.module}/templates/values-alerting-eks.yml.tftpl", {
      alertmanager_role_arn = aws_iam_role.alertmanager[0].arn
      alerts_topic_arn      = aws_sns_topic.alerts[0].arn
      heartbeat_topic_arn   = aws_sns_topic.heartbeat[0].arn
      region                = var.aws_region
      cluster_name          = local.cluster_name
    }),
    # drop kind's `standard` StorageClass so the cluster default is used
    yamlencode({
      prometheus = {
        prometheusSpec = {
          storageSpec = { volumeClaimTemplate = { spec = { storageClassName = null } } }
        }
      }
      grafana = { persistence = { storageClassName = null } }
    }),
  ]

  depends_on = [time_sleep.wait_for_cluster]
}

# PrometheusRule CRDs exist only after the chart installs, so kubectl, as in argocd.tf
resource "null_resource" "monitoring_alerts" {
  count = local.monitoring_count

  depends_on = [helm_release.monitoring]

  triggers = {
    alerts_hash = sha256(join("", [for f in sort(fileset("${path.module}/../observability/monitoring/alerts", "*.yml")) : filesha256("${path.module}/../observability/monitoring/alerts/${f}")]))
  }

  provisioner "local-exec" {
    command = "kubectl apply -f ${path.module}/../observability/monitoring/alerts/"
  }
}
