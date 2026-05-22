# ── Cert-Manager ──────────────────────────────────────────────────────────────
resource "helm_release" "cert_manager" {
  name             = "cert-manager"
  namespace        = "cert-manager"
  create_namespace = true
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  version          = "v1.17.2"
  wait             = true
  timeout          = 180

  set {
    name  = "crds.enabled"
    value = "true"
  }
}

# ── Envoy Gateway (replaces EOL ingress-nginx) ────────────────────────────────
resource "helm_release" "envoy_gateway" {
  name             = "eg"
  namespace        = "envoy-gateway-system"
  create_namespace = true
  repository       = "oci://docker.io/envoyproxy"
  chart            = "gateway-helm"
  version          = "v1.7.0"
  wait             = true
  timeout          = 300

  values = [yamlencode({
    deployment = {
      replicas = 2
      pod = {
        tolerations = [{ key = "CriticalAddonsOnly", operator = "Exists" }]
      }
    }
  })]
}

# ── GatewayClass ──────────────────────────────────────────────────────────────
resource "kubectl_manifest" "gateway_class" {
  yaml_body = yamlencode({
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "GatewayClass"
    metadata   = { name = "eg" }
    spec       = { controllerName = "gateway.envoyproxy.io/gatewayclass-controller" }
  })
  depends_on = [helm_release.envoy_gateway]
}

# ── EnvoyProxy — NLB annotations ─────────────────────────────────────────────
resource "kubectl_manifest" "envoy_proxy_config" {
  yaml_body = yamlencode({
    apiVersion = "gateway.envoyproxy.io/v1alpha1"
    kind       = "EnvoyProxy"
    metadata   = { name = "bookstore-proxy-config", namespace = "default" }
    spec = {
      provider = {
        type = "Kubernetes"
        kubernetes = {
          envoyDeployment = { replicas = 2 }
          envoyService = {
            annotations = {
              "service.beta.kubernetes.io/aws-load-balancer-scheme"          = "internet-facing"
              "service.beta.kubernetes.io/aws-load-balancer-nlb-target-type" = "ip"
              "service.beta.kubernetes.io/aws-load-balancer-name"            = "bookstore-nlb"
            }
          }
        }
      }
    }
  })
  depends_on = [helm_release.envoy_gateway]
}

# ── Gateway ───────────────────────────────────────────────────────────────────
resource "kubectl_manifest" "gateway" {
  yaml_body = yamlencode({
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "Gateway"
    metadata   = { name = "bookstore-gateway", namespace = "default" }
    spec = {
      infrastructure = {
        parametersRef = {
          group = "gateway.envoyproxy.io"
          kind  = "EnvoyProxy"
          name  = "bookstore-proxy-config"
        }
      }
      gatewayClassName = "eg"
      listeners = [{
        name     = "http"
        protocol = "HTTP"
        port     = 80
      }]
    }
  })
  depends_on = [kubectl_manifest.gateway_class, kubectl_manifest.envoy_proxy_config]
}
