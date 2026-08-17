# Mirrors the old manual "Bootstrap" sequence in the repo's root README: helm install argocd
# -> gateway API CRDs -> argocd's own HTTPRoute -> the two AppProjects -> the root
# app-of-apps. Everything under argocd/applications/ is GitOps-managed from there.

resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = var.chart_version
  namespace        = "argocd"
  create_namespace = true

  # Default 300s can be tight for ~7 argocd components to schedule on t3a.small nodes
  # alongside the ALB controller/EBS CSI/system pods already there — a slow schedule reads
  # as a timeout failure here, not more retries.
  timeout = 600

  values = [file(var.values_file)]
}

# --server-side because the bundle's embedded OpenAPI schemas are too large for
# client-side apply's annotation limit (same reason the old manual step used it).
data "kubectl_file_documents" "gateway_api_crds" {
  content = file(var.gateway_api_crds_file)
}

resource "kubectl_manifest" "gateway_api_crds" {
  for_each = data.kubectl_file_documents.gateway_api_crds.manifests

  yaml_body         = each.value
  server_side_apply = true
}

# The API server needs a moment to register a just-created CRD's REST endpoint before it'll
# accept an instance of it (the HTTPRoute below) — without this, a fresh apply can 404 on
# "no matches for kind HTTPRoute" even though depends_on already orders it after the CRDs.
resource "time_sleep" "wait_for_gateway_api_crds" {
  depends_on      = [kubectl_manifest.gateway_api_crds]
  create_duration = "15s"
}

resource "kubectl_manifest" "argocd_httproute" {
  yaml_body = file(var.httproute_file)

  depends_on = [helm_release.argocd, time_sleep.wait_for_gateway_api_crds]
}

resource "kubectl_manifest" "book_store_project" {
  yaml_body = file(var.book_store_project_file)

  depends_on = [helm_release.argocd]
}

resource "kubectl_manifest" "platform_project" {
  yaml_body = file(var.platform_project_file)

  depends_on = [helm_release.argocd]
}

resource "kubectl_manifest" "root_application" {
  yaml_body = file(var.root_application_file)

  depends_on = [
    kubectl_manifest.book_store_project,
    kubectl_manifest.platform_project,
  ]
}
