resource "helm_release" "argocd" {
  name             = "argocd"
  namespace        = var.argocd_namespace
  create_namespace = true
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = var.argocd_chart_version
  wait             = true
  wait_for_jobs    = true
  timeout          = 300

  values = [yamlencode({
    server = {
      service   = { type = "ClusterIP" }
      ingress   = { enabled = false }
      # insecure mode required when TLS is terminated at the gateway/NLB level
      extraArgs = ["--insecure", "--rootpath=/argocd"]
    }
    controller = {
      resources = {
        requests = { cpu = "100m", memory = "128Mi" }
        limits   = { cpu = "500m", memory = "512Mi" }
      }
    }
    repoServer = {
      resources = {
        requests = { cpu = "50m", memory = "64Mi" }
        limits   = { cpu = "200m", memory = "256Mi" }
      }
    }
    redis = {
      resources = {
        requests = { cpu = "50m", memory = "64Mi" }
        limits   = { cpu = "200m", memory = "128Mi" }
      }
    }
  })]
}

resource "kubectl_manifest" "argocd_project" {
  yaml_body  = file("${path.root}/../argocd/project.yml")
  depends_on = [helm_release.argocd]
}

resource "kubectl_manifest" "argocd_application" {
  yaml_body  = file("${path.root}/../argocd/application.yml")
  depends_on = [kubectl_manifest.argocd_project]
}

# ── ArgoCD HTTPRoute — expose via existing Envoy Gateway NLB ─────────────────
# Access ArgoCD at http://<NLB-hostname>/argocd
# For production: add a hostname field and point a Route53 record to the NLB.
# ReferenceGrant — allows the HTTPRoute in 'default' to forward to argocd-server in 'argocd'
resource "kubectl_manifest" "argocd_referencegrant" {
  yaml_body = yamlencode({
    apiVersion = "gateway.networking.k8s.io/v1beta1"
    kind       = "ReferenceGrant"
    metadata = {
      name      = "allow-default-to-argocd"
      namespace = var.argocd_namespace
    }
    spec = {
      from = [{
        group     = "gateway.networking.k8s.io"
        kind      = "HTTPRoute"
        namespace = "default"
      }]
      to = [{
        group = ""
        kind  = "Service"
        name  = "argocd-server"
      }]
    }
  })
  depends_on = [helm_release.argocd]
}

resource "kubectl_manifest" "argocd_httproute" {
  yaml_body = yamlencode({
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "HTTPRoute"
    metadata = {
      name      = "argocd"
      namespace = "default"        # must be same namespace as the Gateway
    }
    spec = {
      parentRefs = [{
        name      = "bookstore-gateway"
        namespace = "default"
      }]
      rules = [{
        matches = [{
          path = { type = "PathPrefix", value = "/argocd" }
        }]
        filters = [{
          type = "URLRewrite"
          urlRewrite = {
            path = {
              type               = "ReplacePrefixMatch"
              replacePrefixMatch = "/argocd"
            }
          }
        }]
        backendRefs = [{
          name      = "argocd-server"
          namespace = var.argocd_namespace   # backend is still in argocd namespace
          port      = 80
        }]
      }]
    }
  })
  depends_on = [helm_release.argocd]
}
