# 🚀 CloudNative DevOps Blueprint

<div align="center">

[![Docker](https://img.shields.io/badge/Docker-2496ED?logo=docker&logoColor=white)](https://www.docker.com/)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-326CE5?logo=kubernetes&logoColor=white)](https://kubernetes.io/)
[![Jenkins](https://img.shields.io/badge/Jenkins-D24939?logo=jenkins&logoColor=white)](https://www.jenkins.io/)
[![ArgoCD](https://img.shields.io/badge/ArgoCD-EF7B4D?logo=argo&logoColor=white)](https://argoproj.github.io/cd/)
[![Kargo](https://img.shields.io/badge/Kargo-EF7B4D)](https://docs.kargo.io/)
[![Helm](https://img.shields.io/badge/Helm-0F1689?logo=helm&logoColor=white)](https://helm.sh/)
[![Terraform](https://img.shields.io/badge/Terraform-7B42BC?logo=terraform&logoColor=white)](https://www.terraform.io/)
[![Kustomize](https://img.shields.io/badge/Kustomize-326CE5?logo=kubernetes&logoColor=white)](https://kustomize.io/)
[![Prometheus](https://img.shields.io/badge/Prometheus-E6522C?logo=prometheus&logoColor=white)](https://prometheus.io/)
[![Grafana](https://img.shields.io/badge/Grafana-F46800?logo=grafana&logoColor=white)](https://grafana.com/)
[![Fluent Bit](https://img.shields.io/badge/Fluent%20Bit-49BDA5?logo=fluentd&logoColor=white)](https://fluentbit.io/)
[![Loki](https://img.shields.io/badge/Loki-F46800?logo=grafana&logoColor=white)](https://grafana.com/oss/loki/)
[![Argo Rollouts](https://img.shields.io/badge/Argo%20Rollouts-EF7B4D?logo=argo&logoColor=white)](https://argoproj.github.io/rollouts/)
[![Istio](https://img.shields.io/badge/Istio-466BB0?logo=istio&logoColor=white)](https://istio.io/)
[![HashiCorp Vault](https://img.shields.io/badge/HashiCorp%20Vault-FFEC13?logo=vault&logoColor=black)](https://www.vaultproject.io/)
[![External Secrets Operator](https://img.shields.io/badge/External%20Secrets%20Operator-326CE5?logo=kubernetes&logoColor=white)](https://external-secrets.io/)
[![AWS EKS](https://img.shields.io/badge/AWS%20EKS-FF9900?logo=amazon-eks&logoColor=white)](https://aws.amazon.com/eks/)
[![cert-manager](https://img.shields.io/badge/cert--manager-2C3E50)](https://cert-manager.io/)
[![Let's Encrypt](https://img.shields.io/badge/Let's%20Encrypt-003A70)](https://letsencrypt.org/)
[![Cloudflare](https://img.shields.io/badge/Cloudflare-F38020?logo=cloudflare&logoColor=white)](https://www.cloudflare.com/)
[![GitHub OAuth SSO](https://img.shields.io/badge/SSO-GitHub%20OAuth-181717?logo=github&logoColor=white)](https://docs.github.com/en/apps/oauth-apps)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

*A comprehensive DevOps blueprint for deploying cloud-native applications with enterprise-grade tooling*

</div>


## 🎯 Overview

This project demonstrates a **production-ready DevOps pipeline** for deploying a MERN (MongoDB, Express, React, Node.js) application using modern cloud-native technologies and best practices. From local development to cloud deployment, this blueprint covers the entire application lifecycle.

**Quick navigation:** [Explore Other Branches](#-explore-other-branches) ·
[Application Versions](#-application-versions) ·
[Project Deployment Flow](#-project-deployment-flow) ·
[Technology Stack](#️-technology-stack) ·
[Documentation Hub](#-documentation-hub)

## 🌿 Explore Other Branches

This repository is organized as a set of branches. `main` (this one) is the broadest,
most comprehensive blueprint — the branches below are standalone, focused deep-dives
into a specific slice of the stack, each with its own complete setup and docs:

```mermaid
flowchart LR
    Begin["🌱 begineer<br/>core flow only"] -->|adds mesh, policy,<br/>secrets, log aggregation| Main["🚀 main<br/>broadest blueprint · this branch"]
    Main -->|focus: custom domain,<br/>TLS, GitHub SSO| TLS["🔐 domain-and-tls<br/>focused deep-dive"]
    Main -->|focus: real cloud,<br/>Terraform-provisioned EKS| Prod["☁️ prod<br/>production deployment"]

    classDef begin fill:#23ce26,color:#000,stroke:#23ce26
    classDef main fill:#57606a,color:#fff,stroke:#57606a
    classDef tls fill:#0ea5e9,color:#fff,stroke:#0ea5e9
    classDef prod fill:#7B42BC,color:#fff,stroke:#7B42BC

    class Begin begin
    class Main main
    class TLS tls
    class Prod prod
```

<table border="1" cellpadding="15" cellspacing="0" style="border-collapse: collapse; width: 100%; border: 2px solid #23ce26ff;">
<tr>
<td width="33%" style="border: 2px solid #23ce26ff; padding: 20px; vertical-align: top;">

### 🌱 **[`begineer`](https://github.com/atkaridarshan04/CloudNative-DevOps-Blueprint/tree/begineer)**
**Beginner-Friendly Core Flow**

The starting point, before `main`'s more advanced pieces (service mesh, policy engines, secrets management, log aggregation).

- Docker + Docker Compose
- Kubernetes on `kind` with Ingress
- Jenkins CI/CD
- Helm + ArgoCD GitOps
- Kustomize (dev/prod overlays)
- Prometheus/Grafana observability

</td>
<td width="33%" style="border: 2px solid #0ea5e9; padding: 20px; vertical-align: top;">

### 🔐 **[`domain-and-tls`](https://github.com/atkaridarshan04/CloudNative-DevOps-Blueprint/tree/domain-and-tls)**
**Domain, TLS & Platform**

A custom domain and TLS setup on Kubernetes, and everything that requires end-to-end.

- Gateway API + wildcard Let's Encrypt cert via DNS-01
- GitOps deployment (ArgoCD + Argo Rollouts canary)
- Prometheus/Grafana + blackbox-exporter TLS monitoring
- GitHub OAuth SSO (Dex, native Grafana OAuth, oauth2-proxy)

</td>
<td width="33%" style="border: 2px solid #7B42BC; padding: 20px; vertical-align: top;">

### ☁️ **[`prod`](https://github.com/atkaridarshan04/CloudNative-DevOps-Blueprint/tree/prod)**
**Real AWS EKS Production Deployment**

Actual cloud infrastructure, provisioned with Terraform, driven by a real CI/CD pipeline.

- Terraform-provisioned AWS EKS, VPC, ECR
- Envoy Gateway (Gateway API) + cert-manager
- Jenkins + Trivy + SonarQube CI/CD pipeline
- ArgoCD + Argo Rollouts canary, triggered by CI

</td>
</tr>
</table>

**At a glance — what each branch actually includes:**

| Capability | 🌱 begineer | 🚀 main (this branch) | 🔐 domain-and-tls | ☁️ prod |
|---|---|---|---|---|
| Containerization | ✅ Docker Compose | ✅ Docker | ✅ Docker | ✅ Docker |
| Kubernetes cluster | `kind` + Ingress | `kind` + Ingress/Gateway API | `kind` + Gateway API | Real AWS EKS |
| Infra as Code | — | ✅ Terraform (optional path) | — | ✅ Terraform (EKS, VPC, ECR) |
| CI/CD | ✅ Jenkins | ✅ Jenkins + Trivy + SonarQube + GitHub Actions (GHCR, cosign, Kyverno signature enforcement) | — | ✅ Jenkins + Trivy + SonarQube |
| GitOps | ✅ ArgoCD | ✅ ArgoCD + Kargo (promotion) | ✅ ArgoCD | ✅ ArgoCD |
| Progressive Delivery | — | ✅ Argo Rollouts (canary + blue-green) | ✅ Argo Rollouts (canary) | ✅ Argo Rollouts (canary) |
| Config management | Helm + Kustomize | Helm + Kustomize | Helm | Helm |
| Service Mesh | — | ✅ Istio | — | — |
| Policy Engine | — | ✅ Kyverno | — | — |
| Secrets Management | — | ✅ Vault + External Secrets Operator | — | — |
| Custom Domain + TLS | — | — | ✅ cert-manager, DNS-01 wildcard | ✅ cert-manager |
| SSO | — | — | ✅ GitHub OAuth (Dex, Grafana, oauth2-proxy) | — |
| Monitoring | ✅ Prometheus/Grafana | ✅ Prometheus/Grafana | ✅ + TLS cert-expiry alerts | ✅ Prometheus/Grafana |
| Log Aggregation | — | ✅ Fluent Bit + Loki | — | — |

## 📦 Application Versions

Three versions of the application are available, each with distinct visual and functional differences:

| Version | Frontend | Backend |
|---------|----------|---------|
| [`1.0.0`](./src/README.md) | 🔵 Blue theme | `v1.0.0` |
| [`2.0.0`](./src/README.md) | 🔴 Red theme | `v2.0.0` |
| [`3.0.0`](./src/README.md) | 🟣 Purple theme | `v3.0.0` |

> See **[src/README.md](./src/README.md)** for screenshots and build instructions.

## 🌟 Project Deployment Flow

<div align="center">

![workflow-gif](./docs/assets/workflow.gif)

*End-to-end deployment pipeline from code commit to production*

</div>

The gif above walks through one path end-to-end; it doesn't show every piece running at
once. Every box below is a real, working piece of this repo — but most of the per-tool
guides ([Kyverno.md](./docs/Kyverno.md), [Istio.md](./docs/Istio.md),
[ArgoRollouts.md](./docs/ArgoRollouts.md), etc.) demo their slice **standalone**, each with
its own `kind` cluster, not wired to the others. This is the *composite* architecture — how
they compose if you ran them together, not a claim that this exact end-to-end chain runs in
any single guide today. Note the two independent CI entry points feeding the same cluster:
Jenkins (Docker Hub, the primary GitOps path) and [GitHub Actions](./docs/GitHubActions.md)
(GHCR, signed images that Kyverno verifies at admission) — see
[concepts/SupplyChainSecurity.md](./docs/concepts/SupplyChainSecurity.md) for why that second
path exists:

```mermaid
flowchart TD
    Dev[Developer commit] --> CI[Jenkins CI<br/>SonarQube + Trivy scan<br/>build & push image]
    CI -->|triggers| CD[Jenkins CD<br/>gitops/Jenkinsfile<br/>updates image tag]
    CD -->|git commit + push| Git[(Git repo<br/>manifests / Helm values)]
    Git -.->|watched by| ArgoApp[ArgoCD Application]

    CI -.->|image published| Kargo[Kargo Warehouse<br/>watches image tags]
    Kargo -->|promotes dev→staging→prod<br/>opens PR, human merges| Git

    Dev -.->|parallel pipeline| GHA[GitHub Actions CI<br/>Trivy + Syft SBOM<br/>cosign sign, keyless]
    GHA --> GHCR[(GHCR: signed images<br/>+ SBOM attestation)]

    subgraph "AWS EKS cluster (provisioned by Terraform)"
        ArgoApp -->|sync| Kyverno[Kyverno<br/>admission policies +<br/>signature verification]
        GHCR -.->|verifyImages| Kyverno
        Kyverno -->|allowed| Rollout[Argo Rollouts<br/>canary / blue-green]

        subgraph "mern-devops namespace (Istio mesh)"
            Rollout --> FE[frontend<br/>+ Envoy sidecar]
            FE -->|mTLS| BE[backend<br/>+ Envoy sidecar]
            BE -->|mTLS| DB[(mongodb)]
        end

        Vault[(HashiCorp Vault)] --> ESO[External Secrets<br/>Operator] --> Secret[Kubernetes Secret]
        Secret --> BE
        Secret --> DB
    end

    FE -.->|metrics| Prom[Prometheus / Grafana]
    BE -.->|metrics| Prom
    FE -.->|logs| Fluent[Fluent Bit] --> Loki[Loki]
    BE -.->|logs| Fluent

    classDef controller fill:#1f6feb,color:#fff,stroke:#1f6feb
    classDef store fill:#2ea043,color:#fff,stroke:#2ea043
    classDef workload fill:#57606a,color:#fff,stroke:#57606a
    classDef external fill:#8b949e,color:#000,stroke:#8b949e,stroke-dasharray: 3 3
    classDef observability fill:#d29922,color:#000,stroke:#d29922

    class Dev external
    class CI,CD,ArgoApp,Kyverno,Rollout,ESO,Kargo,GHA controller
    class Git,Vault,GHCR store
    class FE,BE,DB,Secret workload
    class Prom,Fluent,Loki observability
```

## 🛠️ Technology Stack

<table width="100%">
<tr>
<td align="center"><strong>🏗️ Infrastructure</strong></td>
<td align="center"><strong>🔄 CI/CD</strong></td>
<td align="center"><strong>☸️ Orchestration & Config</strong></td>
<td align="center"><strong>🔐 Security & Secrets</strong></td>
<td align="center"><strong>📊 Observability</strong></td>
</tr>
<tr>
<td valign="top">• Terraform<br>• AWS EKS<br>• Docker<br>• Docker Bake<br>• Ingress / Gateway API</td>
<td valign="top">• Jenkins<br>• ArgoCD<br>• Kargo<br>• Argo Rollouts<br>• SonarQube<br>• Trivy<br>• GitHub Actions<br>• cosign<br>• Syft</td>
<td valign="top">• Kubernetes<br>• Helm<br>• Kustomize<br>• Istio<br>• Kyverno<br>• HPA / Locust</td>
<td valign="top">• HashiCorp Vault<br>• External Secrets Operator</td>
<td valign="top">• Prometheus<br>• Grafana<br>• Fluent Bit<br>• Loki</td>
</tr>
</table>

## 📚 Documentation Hub

> 📘 **[docs/concepts/](./docs/concepts/README.md)** — the guides below are how-to runbooks; the concepts folder covers the *why* (GitOps, service mesh, progressive delivery, policy-as-code, secrets management, Helm vs Kustomize, Ingress vs Gateway API).

<table border="1" cellpadding="15" cellspacing="0" style="border-collapse: collapse; width: 100%; border: 2px solid #2e6ccaff;">
<tr>
<td width="33%" style="border: 2px solid #2e6ccaff; padding: 20px; vertical-align: top;">

### 🐳 **Containerization**

**[Docker.md](./docs/Docker.md)**
*Build and run containers with Docker Compose for multi-service applications*
- Multi-stage Dockerfiles
- Production optimizations
- Container networking
- Volume management

</td>
<td width="33%" style="border: 2px solid #284cdfff; padding: 20px; vertical-align: top;">

### ☸️ **Kubernetes**

**[Kubernetes.md](./docs/Kubernetes.md)**
*Deploy on kind cluster with ingress*
- Persistent storage setup
- Deployments and Statefulsets
- Secrets and Configuration Management
- Ingress/Gateway API Deployment

</td>
<td width="33%" style="border: 2px solid #e05c00; padding: 20px; vertical-align: top;">

### 🔥 **Stress Testing & HPA**

**[StressTest.md](./docs/StressTest.md)**
*Load test the backend with Locust to trigger HPA autoscaling*
- Locust stress client (local & Kubernetes Job)
- HPA autoscaling demonstration
- Grafana metrics observation during load

</td>
</tr>
</table>


### 🔄 **CI/CD Pipeline**

<table border="1" cellpadding="15" cellspacing="0" style="border-collapse: collapse; width: 100%; border: 2px solid #b84c09ff;">
<tr>
<td width="30%" style="border: 2px solid #b84c09ff; padding: 20px ; vertical-align: top;">

**[Jenkins.md](./docs/Jenkins.md)**
*Automated build, test, and deployment*
- Multi-stage pipeline
- Sonar scanning
- Quality gates
- Trivy Scanning
- Docker Images Build and Push
- Notification system

</td>
<td width="60%" style="border: 2px solid #b84c09ff; margin-left:20px ; padding: 15px; vertical-align: middle; text-align: center;">

<img src="./docs/assets/jenkins/jenkins-ci.png" alt="Jenkins CI Image" width="100%">
<img src="./docs/assets/jenkins/jenkins-cd.png" alt="Jenkins CI Image" width="100%">

</td>
</tr>
<tr>
<td width="30%" style="border: 2px solid #b84c09ff; padding: 20px ; vertical-align: top;">

**[GitHubActions.md](./docs/GitHubActions.md)**  
*Signed CI/CD pipeline to GHCR*
- Multi-arch build via existing `docker-bake.hcl`
- Trivy scan + Syft SBOM
- cosign keyless signing (Sigstore)
- Kyverno signature enforcement at admission

</td>
<td width="60%" style="border: 2px solid #b84c09ff; margin-left:20px ; padding: 15px; vertical-align: middle; text-align: center;">

<img src="./docs/assets/supply-chain-signing/workflow-run-overview.png" alt="GitHub Actions Workflow run overview" width="100%">

</td>
</tr>
</table>

### 📦 **Package, Configuration & Policy Management**

<table border="1" cellpadding="15" cellspacing="0" style="border-collapse: collapse; width: 100%; border: 2px solid #23ce26ff;">
<tr>
<td width="33%" style="border: 2px solid #23ce26ff; padding: 20px; vertical-align: top;">

#### 📦 **Helm Charts**
**[Helm.md](./docs/Helm.md)**
*Template-based Kubernetes deployments*
- Chart customization
- Values management
- Release lifecycle

</td>
<td width="33%" style="border: 2px solid #23ce26ff; padding: 20px; vertical-align: top;">

#### 🔧 **Kustomize**
**[Kustomize.md](./docs/Kustomize.md)**
*Environment-specific configurations*
- Base and overlay patterns
- Patch management
- Multi-environment deployment

</td>

<td width="33%" style="border: 2px solid #23ce26ff; padding: 20px; vertical-align: top;">

#### 🛡️**Kyverno**
**[Kyverno.md](./docs/Kyverno.md)**
*Policy management and governance*
- Security policy enforcement
- Resource validation rules
- Compliance automation
</tr>
</table>

### 🔐 **Secrets Management**

<table border="1" cellpadding="15" cellspacing="0" style="border-collapse: collapse; width: 100%; border: 2px solid #6f42c1;">
<tr>
<td width="30%" style="border: 2px solid #6f42c1; padding: 20px ; vertical-align: top;">

**[ExternalSecrets.md](./docs/ExternalSecrets.md)**
*Secure secrets management with HashiCorp Vault integration*
- External Secrets Operator
- Vault secret synchronization
- Kubernetes secret automation

</td>
<td width="60%" style="border: 2px solid #6f42c1; margin-left:20px ; padding: 15px; vertical-align: middle; text-align: center;">

<img src="./docs/assets/external-secrets/vault-ui.png" alt="HashiCorp Vault UI Dashboard" width="100%">

</td>
</tr>
</table>

### 📈 **Monitoring**

<table border="1" cellpadding="15" cellspacing="0" style="border-collapse: collapse; width: 100%; border: 2px solid #bc2323ff;">
<tr>
<td width="30%" style="border: 2px solid #bc2323ff; padding: 20px ; vertical-align: top;">

**[Monitoring.md](./docs/Monitoring.md)**
*Metrics observability with Prometheus & Grafana*
- Metrics collection & storage
- Kube Prometheus Stack Dashboards
- Real-time monitoring dashboards
- Performance & resource tracking
- Alert management & notifications

</td>
<td width="60%" style="border: 2px solid #bc2323ff; margin-left:20px ; padding: 15px; vertical-align: middle; text-align: center;">

<img src="./docs/assets/observability/graphana-3.png" alt="Grafana Monitoring Dashboard" width="100%">

</td>
</tr>
</table>

### 🪵 **Logging**

<table border="1" cellpadding="15" cellspacing="0" style="border-collapse: collapse; width: 100%; border: 2px solid #49BDA5;">
<tr>
<td width="30%" style="border: 2px solid #49BDA5; padding: 20px ; vertical-align: top;">

**[Logging.md](./docs/Logging.md)**
*Centralized log collection with Fluent Bit, Loki & Grafana*
- Fluent Bit DaemonSet collection
- Kubernetes metadata enrichment
- JSON log parsing
- Loki log aggregation
- LogQL querying in Grafana

</td>
<td width="60%" style="border: 2px solid #49BDA5; margin-left:20px ; padding: 15px; vertical-align: middle; text-align: center;">

<img src="./docs/assets/observability/container-logs.png" alt="Grafana Logging Dashboard" width="100%">

</td>
</tr>
</table>

### 🚀 **GitOps Deployment**

<table border="1" cellpadding="15" cellspacing="0" style="border-collapse: collapse; width: 100%; border: 2px solid #c9772bff;">
<tr>
<td width="30%" style="border: 2px solid #c9772bff; padding: 20px ; vertical-align: top;">

**[ArgoCD.md](./docs/ArgoCD.md)**
*Continuous deployment with Git sync and automated application lifecycle management*
- Repository connection
- Application management
- Sync policies
- Multi-cluster deployment
- RBAC integration

</td>
<td width="60%" style="border: 2px solid #c9772bff; margin-left:20px ; padding: 15px; vertical-align: middle; text-align: center;">

<img src="./docs/assets/argocd/argocd-5.png" alt="ArgoCD Dashboard" width="100%">

</td>
</tr>
</table>

### 🚚 **Continuous Promotion**

<table border="1" cellpadding="15" cellspacing="0" style="border-collapse: collapse; width: 100%; border: 2px solid #c9772bff;">
<tr>
<td width="30%" style="border: 2px solid #c9772bff; padding: 20px ; vertical-align: top;">

**[Kargo.md](./docs/Kargo.md)**
*Verified, PR-gated promotion of builds across dev → staging → prod*
- Warehouse-driven Freight from image tags
- Health-gated Stage chaining (dev → staging → prod)
- PR-gated promotions, reviewed on GitHub before ArgoCD syncs
- Multi-environment Kustomize overlays

</td>
<td width="60%" style="border: 2px solid #c9772bff; margin-left:20px ; padding: 15px; vertical-align: middle; text-align: center;">

<img src="./docs/assets/kargo/karogo-ui-3_0.png" alt="Kargo Dashboard" width="100%">

</td>
</tr>
</table>


### 🎯 **Progressive Delivery**

<table border="1" cellpadding="15" cellspacing="0" style="border-collapse: collapse; width: 100%; border: 2px solid #c9772bff;">
<tr>
<td width="30%" style="border: 2px solid #c9772bff; padding: 20px ; vertical-align: top;">

**[ArgoRollouts.md](./docs/ArgoRollouts.md)**
*Canary and blue-green deployments with automated rollbacks*
- Canary traffic splitting
- Blue-green instant promotion
- Rollback strategies

</td>
<td width="60%" style="border: 2px solid #c9772bff; margin-left:20px ; padding: 15px; vertical-align: middle; text-align: center;">

<img src="./docs/assets/argo-rollouts/argo-rollouts-dash-3.png" alt="Argo Rollouts Dashboard Diagram" width="100%">

</td>
</tr>
</table>

### 🕸️ **Service Mesh**

<table border="1" cellpadding="15" cellspacing="0" style="border-collapse: collapse; width: 100%; border: 2px solid #4297ccff;">
<tr>
<td width="30%" style="border: 2px solid #42a4bcff; padding: 20px ; vertical-align: top;">

**[Istio.md](./docs/Istio.md)**
*Advanced traffic management and security with service mesh capabilities*
- mTLS encryption
- Traffic splitting & canary
- Observability & tracing
- Policy enforcement

</td>
<td width="60%" style="border: 2px solid #42a4bcff; margin-left:20px ; padding: 15px; vertical-align: middle; text-align: center;">

<img src="./docs/assets/istio/kiali-app-graph.png" alt="Kiali Service Mesh Graph" width="100%">

</td>
</tr>
</table>

### ☁︎ **Production Deployment**

<table border="1" cellpadding="15" cellspacing="0" style="border-collapse: collapse; width: 100%; border: 2px solid #7B42BC;">
<tr>
<td width="30%" style="border: 2px solid #7B42BC; padding: 20px ; vertical-align: top;">

#### 🏗️ **Cloud Infrastructure**
**[Terraform.md](./docs/Terraform.md)**
*Provision and Deploy on AWS EKS cluster with IaC*

- VPC and networking setup
- EKS cluster configuration
- Security groups and IAM
- Add-ons installation

</td>
<td width="60%" style="border: 2px solid #7B42BC; margin-left:20px ; padding: 15px; vertical-align: middle; text-align: center;">

<img src="./docs/assets/terraform/terraform_architecture.png" alt="Terraform AWS EKS Diagram" width="100%">

</td>
</tr>
</table>

<!-- ## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details. -->

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

<div align="center">

**⭐ Star this repository if you find it helpful!**

<!-- *Built with ❤️ for the DevOps community* -->

</div>
