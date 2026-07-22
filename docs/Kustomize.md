# Multi-Environment Configuration with Kustomize

> 📘 See [concepts/HelmVsKustomize.md](./concepts/HelmVsKustomize.md) for how Kustomize compares to Helm and when to reach for each.

## Overview
Kustomize simplifies Kubernetes configurations by allowing environment-specific customizations without modifying the base YAML files. This part demonstrates how to manage multiple environments using Kustomize with ingress-based routing, enabling you to deploy and access different versions of your MERN application through distinct hostnames.

## Environment Stages
We have configured the following environments with separate namespaces and ingress hosts:

- **Development (`overlays/dev`)** - Accessible via `dev.local`
- **Staging (`overlays/staging`)** - Accessible via `staging.local`
- **Production (`overlays/prod`)** - Accessible via `prod.local`

### Environment Matrix

| Environment | Namespace | Host | Replicas | Image Tag | Theme |
|-------------|-----------|------|----------|-----------|-------|
| **Development** | `dev` | `dev.local` | 1 | `1.0.0` | 🔵 Blue |
| **Staging** | `staging` | `staging.local` | 1 | `2.0.0` | 🔴 Red |
| **Production** | `prod` | `prod.local` | 2 | `3.0.0` | 🟣 Purple |

Before deploying, ensure the image tags are set correctly in each overlay file:

- [`kustomize/overlays/dev/kustomization.yml`](../kustomize/overlays/dev/kustomization.yml) → `newTag: 1.0.0`
- [`kustomize/overlays/staging/kustomization.yml`](../kustomize/overlays/staging/kustomization.yml) → `newTag: 2.0.0`
- [`kustomize/overlays/prod/kustomization.yml`](../kustomize/overlays/prod/kustomization.yml) → `newTag: 3.0.0`


## Configuration Management
We use `configMapGenerator` and `secretGenerator` in Kustomize to manage ConfigMaps and Secrets. Each environment has its own backend configuration with environment-specific MongoDB URLs.

## Prerequisites

### 1. Create kind Cluster with Port 80 Exposed

Ingress requires port 80 to be mapped from the host. Create the cluster with this config:

```bash
cat <<EOF | kind create cluster --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
  - role: control-plane
    extraPortMappings:
      - containerPort: 80
        hostPort: 80
        protocol: TCP
EOF
```

### 2. Install Nginx Ingress Controller
Before deploying any environment, ensure the Nginx Ingress Controller is installed:

```bash
kubectl apply -f https://kind.sigs.k8s.io/examples/ingress/deploy-ingress-nginx.yaml
```

Wait for the ingress controller to be ready:

```bash
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=90s
```

### 3. Configure /etc/hosts
To access the applications via their respective hostnames, add the following entries to your `/etc/hosts` file:

```bash
# Get your cluster's ingress IP (usually localhost for kind clusters)
kubectl get service -n ingress-nginx ingress-nginx-controller

# Add these entries to /etc/hosts
sudo tee -a /etc/hosts << EOF
127.0.0.1 dev.local
127.0.0.1 staging.local
127.0.0.1 prod.local
EOF
```

**Note:** The kind cluster setup and port mapping above is only required for local development. If you are using a cloud cluster (EKS, GKE, AKS), skip the kind step — the ingress controller gets a real public IP/hostname automatically

## Step-by-Step Deployment Guide

### Step 1: Verify Kustomize Configuration
Before deploying, verify the configurations for each environment:

```bash
# Verify Development environment
kubectl kustomize kustomize/overlays/dev

# Verify Staging environment
kubectl kustomize kustomize/overlays/staging

# Verify Production environment
kubectl kustomize kustomize/overlays/prod
```

### Step 2: Deploy Development Environment

```bash
# Deploy to Development
kubectl apply -k kustomize/overlays/dev

# Verify deployment
kubectl get pods -n dev
kubectl get svc -n dev
kubectl get ingress -n dev
```

Wait for all pods to be running:

```bash
kubectl wait --for=condition=ready pod --all -n dev --timeout=300s
```

**Access Development Application:**
Open your browser and navigate to: `http://dev.local`

### Step 3: Deploy Staging Environment

```bash
# Deploy to Staging
kubectl apply -k kustomize/overlays/staging

# Verify deployment
kubectl get pods -n staging
kubectl get svc -n staging
kubectl get ingress -n staging
```

Wait for all pods to be running:

```bash
kubectl wait --for=condition=ready pod --all -n staging --timeout=300s
```

**Access Staging Application:**
Open your browser and navigate to: `http://staging.local`

### Step 4: Deploy Production Environment

```bash
# Deploy to Production
kubectl apply -k kustomize/overlays/prod

# Verify deployment
kubectl get pods -n prod
kubectl get svc -n prod
kubectl get ingress -n prod
```

Wait for all pods to be running:

```bash
kubectl wait --for=condition=ready pod --all -n prod --timeout=300s
```

**Access Production Application:**
Open your browser and navigate to: `http://prod.local`


## Application Testing
| Environment | Frontend URL | API Endpoint | Expected Version |
|-------------|--------------|--------------|-----------------|
| Development | http://dev.local | http://dev.local/books | 🔵 Blue banner — v1.0.0 |
| Staging | http://staging.local | http://staging.local/books | 🔴 Red banner — v2.0.0 |
| Production | http://prod.local | http://prod.local/books | 🟣 Purple banner — v3.0.0 |

> Verify the backend version: `curl http://<host>/books` should return `Welcome to MERN Stack Book Shop - v<X.0.0>`


![kustomize-dev](./assets/kustomize/kustomize-dev.png)
![kustomize-staging](./assets/kustomize/kustomize-stage.png)
![kustomize-prod](./assets/kustomize/kustomize-prod.png)


## Post-Deployment Verification

### Check All Environments
```bash
# View all namespaces
kubectl get namespaces

# Check pods across all environments
kubectl get pods --all-namespaces | grep -E "(dev|staging|prod)"

# Check ingress configurations
kubectl get ingress --all-namespaces
```
![kustomize-overview](./assets/kustomize/kustomize-overview.png)

## Cleanup

### Delete Specific Environment
```bash
# Delete development environment
kubectl delete -k kustomize/overlays/dev

# Delete staging environment
kubectl delete -k kustomize/overlays/staging

# Delete production environment
kubectl delete -k kustomize/overlays/prod
```

### Delete All Environments
```bash
# Delete all application namespaces
kubectl delete namespace dev staging prod
```

### Remove /etc/hosts Entries
```bash
# Remove the added entries from /etc/hosts
sudo sed -i '/dev.local/d; /staging.local/d; /prod.local/d' /etc/hosts
```

---

## GitOps Deployment via ArgoCD (multi-environment)

Everything above deploys each overlay by hand via `kubectl apply -k`. Each overlay can
instead be managed by its own ArgoCD `Application` — one per environment, each watching its
own `kustomize/overlays/{dev,staging,prod}` path and syncing automatically whenever that
path changes in Git, instead of anyone running `kubectl apply -k` by hand.

```bash
kubectl apply -f argocd/project.yml
kubectl apply -f argocd/application-dev.yml
kubectl apply -f argocd/application-staging.yml
kubectl apply -f argocd/application-prod.yml
```

Verify all three synced:

```bash
kubectl get application -n argocd
# SYNC STATUS should show Synced, HEALTH STATUS should show Healthy for all three
```

---
