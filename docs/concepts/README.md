# 📘 Core Concepts

The guides in [`../`](../) are **how-to runbooks** — commands to run, in order, to get a tool working. They intentionally don't stop to explain *why* the tool exists or what problem it solves.

This folder is the **why** layer. Each note explains the underlying model or comparison behind a set of tools used in this blueprint, then links back to the hands-on guide.

| Concept | Covers | Hands-on guide |
|---|---|---|
| [GitOps.md](./GitOps.md) | Push vs pull deployment, reconciliation, drift | [ArgoCD.md](../ArgoCD.md) |
| [ServiceMesh.md](./ServiceMesh.md) | Sidecar pattern, mTLS, zero-trust, traffic control | [Istio.md](../Istio.md) |
| [ProgressiveDelivery.md](./ProgressiveDelivery.md) | Canary vs blue-green, automated analysis | [ArgoRollouts.md](../ArgoRollouts.md) |
| [PolicyAsCode.md](./PolicyAsCode.md) | Admission control, validate/mutate/generate | [Kyverno.md](../Kyverno.md) |
| [SecretsManagement.md](./SecretsManagement.md) | Why not native Secrets, Vault + ESO sync model | [ExternalSecrets.md](../ExternalSecrets.md) |
| [HelmVsKustomize.md](./HelmVsKustomize.md) | Templating+packaging vs template-free overlays | [Helm.md](../Helm.md), [Kustomize.md](../Kustomize.md) |
| [IngressVsGatewayAPI.md](./IngressVsGatewayAPI.md) | Why Gateway API is replacing Ingress | [Kubernetes.md](../Kubernetes.md) (Section 5) |
| [SupplyChainSecurity.md](./SupplyChainSecurity.md) | SBOM, Sigstore keyless signing, Kyverno `verifyImages` | [Kyverno.md](../Kyverno.md), [GitHubActions.md](../GitHubActions.md) |
| [PodSecurityHardening.md](./PodSecurityHardening.md) | `securityContext` vs. user namespaces — app-layer vs. kernel-layer pod hardening | [Kubernetes.md](../Kubernetes.md) (Section 4) |
| [NetworkPolicies.md](./NetworkPolicies.md) | Zero-trust pod-to-pod traffic, default-deny + explicit allow | Self-contained (steps in the doc) |

No entry here for Docker, Jenkins, Terraform, or Locust/HPA — those tools work the way their name suggests and the how-to guide already carries enough context. This folder only covers the spots where "how do I run this" and "why does this exist / why two tools for one job" are genuinely different questions.

> 🔐 **TLS, cert-manager, and GitHub OAuth SSO** aren't covered here — that whole slice lives in its own standalone branch, [`domain-and-tls`](https://github.com/atkaridarshan04/CloudNative-DevOps-Blueprint/tree/domain-and-tls), which has its own `docs/concepts/` (`tls-concepts.md`, `sso-concepts.md`, `monitoring-concepts.md`).
