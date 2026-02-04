# 🚀 CloudNative DevOps Blueprint

<div align="center">

[![Docker](https://img.shields.io/badge/Docker-2496ED?logo=docker&logoColor=white)](https://www.docker.com/)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-326CE5?logo=kubernetes&logoColor=white)](https://kubernetes.io/)
[![Jenkins](https://img.shields.io/badge/Jenkins-D24939?logo=jenkins&logoColor=white)](https://www.jenkins.io/)
[![ArgoCD](https://img.shields.io/badge/ArgoCD-EF7B4D?logo=argo&logoColor=white)](https://argoproj.github.io/cd/)
[![Helm](https://img.shields.io/badge/Helm-0F1689?logo=helm&logoColor=white)](https://helm.sh/)
[![Terraform](https://img.shields.io/badge/Terraform-7B42BC?logo=terraform&logoColor=white)](https://www.terraform.io/)
[![Kustomize](https://img.shields.io/badge/Kustomize-326CE5?logo=kubernetes&logoColor=white)](https://kustomize.io/)
[![Prometheus](https://img.shields.io/badge/Prometheus-E6522C?logo=prometheus&logoColor=white)](https://prometheus.io/)
[![Grafana](https://img.shields.io/badge/Grafana-F46800?logo=grafana&logoColor=white)](https://grafana.com/)
[![Argo Rollouts](https://img.shields.io/badge/Argo%20Rollouts-EF7B4D?logo=argo&logoColor=white)](https://argoproj.github.io/rollouts/)  
[![Istio](https://img.shields.io/badge/Istio-466BB0?logo=istio&logoColor=white)](https://istio.io/)
[![AWS EKS](https://img.shields.io/badge/AWS%20EKS-FF9900?logo=amazon-eks&logoColor=white)](https://aws.amazon.com/eks/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

*A comprehensive DevOps blueprint for deploying cloud-native applications with enterprise-grade tooling*

</div>


## 🎯 Overview

This project demonstrates a **production-ready DevOps pipeline** for deploying a MERN (MongoDB, Express, React, Node.js) application using modern cloud-native technologies and best practices. From local development to cloud deployment, this blueprint covers the entire application lifecycle.

## 🌟 Project Deployment Flow

<div align="center">

![workflow-gif](./docs/assets/workflow.gif)

*End-to-end deployment pipeline from code commit to production*

</div>


## 🛠️ Technology Stack

<table>
<tr>
<td align="center"><strong>🏗️ Infrastructure</strong></td>
<td align="center"><strong>🔄 CI/CD</strong></td>
<td align="center"><strong>☸️ Orchestration</strong></td>
<td align="center"><strong>📊 Observability</strong></td>
</tr>
<tr>
<td>
• Terraform<br>
• AWS EKS<br>
• Docker<br>
• Ingress/Gateway API
</td>
<td>
• Jenkins<br>
• ArgoCD<br>
• Argo Rollouts<br>
• SonarQube
</td>
<td>
• Kubernetes<br>
• Helm<br>
• Kustomize<br>
• Istio
</td>
<td>
• Prometheus<br>
• Grafana<br>
• Loki<br>
• Alloy
</td>
</tr>
</table>

## 📚 Documentation Hub

### 🐳 **Containerization**

<table border="1" cellpadding="15" cellspacing="0" style="border-collapse: collapse; width: 100%; border: 2px solid #2e6ccaff;">
<tr>
<td width="30%" style="border: 2px solid #2e6ccaff; padding: 20px ; vertical-align: top;">

**[Docker.md](./docs/Docker.md)**  
*Build and run containers with Docker Compose for multi-service applications*
- Multi-stage Dockerfiles
- Production optimizations
- Container networking
- Volume management

</td>
<td width="60%" style="border: 2px solid #2e6ccaff; margin-left:20px ; padding: 15px; vertical-align: middle; text-align: center;">

<img src="./docs/assets/docker-compose.png" alt="Docker Compose Image" width="100%">

</td>
</tr>
</table>

### ☸️ **Kubernetes**

<table border="1" cellpadding="15" cellspacing="0" style="border-collapse: collapse; width: 100%; border: 2px solid #284cdfff;">
<tr>
<td width="30%" style="border: 2px solid #284cdfff; padding: 20px ; vertical-align: top;">

**[Kubernetes.md](./docs/Kubernetes.md)**  
*Deploy on kind cluster with ingress*
- Persistent storage setup
- Demonset and Statefulset Deployments
- Health checks
- Secrets and Configuration Management
- Ingress/Gateway API Deployment

</td>
<td width="60%" style="border: 2px solid #284cdfff; margin-left:20px ; padding: 15px; vertical-align: middle; text-align: center;">

<img src="./docs/assets/k8s-dash-2.png" alt="Kubernetes Dashboard Image" width="100%">

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

<img src="./docs/assets/jenkins-ci.png" alt="Jenkins CI Image" width="100%">
<img src="./docs/assets/jenkins-cd.png" alt="Jenkins CI Image" width="100%">

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
- Secret rotation policies
- Multi-environment secret management

</td>
<td width="60%" style="border: 2px solid #6f42c1; margin-left:20px ; padding: 15px; vertical-align: middle; text-align: center;">

<img src="./docs/assets/vault-ui.png" alt="HashiCorp Vault UI Dashboard" width="100%">

</td>
</tr>
</table>

### 📈 **Observability**

<table border="1" cellpadding="15" cellspacing="0" style="border-collapse: collapse; width: 100%; border: 2px solid #bc2323ff;">
<tr>
<td width="30%" style="border: 2px solid #bc2323ff; padding: 20px ; vertical-align: top;">

**[Observability.md](./docs/Observability.md)**  
*Comprehensive observability with Prometheus, Grafana, Loki & Alloy*
- Metrics collection & storage
- Kube Prometheus Stack Dashboards
- Real-time monitoring dashboards
- Centralized log aggregation
- Performance & resource tracking
- Alert management & notifications
- Log analysis & troubleshooting

</td>
<td width="60%" style="border: 2px solid #bc2323ff; margin-left:20px ; padding: 15px; vertical-align: middle; text-align: center;">

<img src="./docs/assets/graphana-3.png" alt="Grafana Monitoring Dashboard" width="100%">
<img src="./docs/assets/logs-1.png" alt="Grafana Logging Dashboard" width="100%">

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

<img src="./docs/assets/argocd-5.png" alt="ArgoCD Dashboard" width="100%">

</td>
</tr>
</table>


### 🎯 **Progressive Delivery**

<table border="1" cellpadding="15" cellspacing="0" style="border-collapse: collapse; width: 100%; border: 2px solid #c9772bff;">
<tr>
<td width="30%" style="border: 2px solid #c9772bff; padding: 20px ; vertical-align: top;">

**[ArgoRollouts.md](./docs/ArgoRollouts.md)**  
*Canary deployments with automated rollbacks*
- Traffic splitting
- Analysis templates
- Rollback strategies  

</td>
<td width="60%" style="border: 2px solid #c9772bff; margin-left:20px ; padding: 15px; vertical-align: middle; text-align: center;">

<img src="./docs/assets/argo-rollouts-dash-3.png" alt="Argo Rollouts Dashboard Diagram" width="100%">

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

<img src="./docs/assets/kiali-app-graph.png" alt="Kiali Service Mesh Graph" width="100%">

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

<img src="./docs/assets/terraform_architecture.png" alt="Terraform AWS EKS Diagram" width="100%">

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
