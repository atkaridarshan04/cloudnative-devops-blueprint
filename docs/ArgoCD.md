# ⚡ GitOps Continuous Delivery with ArgoCD

> 📘 New to GitOps? See [concepts/GitOps.md](./concepts/GitOps.md) for the push-vs-pull model this guide implements.

This guide demonstrates how to deploy and manage the MERN stack application using ArgoCD for GitOps continuous delivery, enabling automated synchronization between Git repository and Kubernetes cluster.

## Overview

ArgoCD provides declarative GitOps continuous delivery for Kubernetes applications. This setup enables:

- Automated deployment from Git repository
- Real-time synchronization with cluster state
- Easy rollback and application lifecycle management
- Multi-environment deployment capabilities

```mermaid
flowchart LR
    CD[Jenkins CD<br/>gitops/Jenkinsfile<br/>updates image tag] -->|git commit + push| Git[(Git repo)]
    Git -.->|watched by| App[ArgoCD Application<br/>book-store]
    App -->|sync| Cluster[mern-devops namespace]
    App -.->|on-health-degraded / on-deployed| Notify[Email notifications]
    Cluster -.->|metrics| Prom[Prometheus<br/>via ServiceMonitor]

    classDef controller fill:#1f6feb,color:#fff,stroke:#1f6feb
    classDef store fill:#2ea043,color:#fff,stroke:#2ea043
    classDef workload fill:#57606a,color:#fff,stroke:#57606a
    classDef observability fill:#d29922,color:#000,stroke:#d29922

    class CD,App controller
    class Git store
    class Cluster workload
    class Notify,Prom observability
```

> Note: `gitops/Jenkinsfile` updates image tags in `kubernetes/*.yml`, while this
> `Application`'s `source.path` below is `helm-chart` — same GitOps mechanism (CD commits,
> ArgoCD watches Git), but pointed at different paths in this repo today. Point both at the
> same path if you want the CD job's commits to be exactly what this Application syncs.

## 🔀 Two Deployment Paths in This Repo

This guide covers two separate, self-contained ways to deploy the app via ArgoCD — pick one,
each is complete on its own:

- **Path A — Helm chart, single environment** (§3 *Deploy the Application* below): one
  `Application` (`argocd/application.yml`) deploying `helm-chart/` into one `mern-devops`
  namespace.
- **Path B — Kustomize overlays, multi-environment** (§5 *Multi-Environment Deployment*
  below): three `Application`s (`argocd/application-{dev,staging,prod}.yml`), each deploying
  its own `kustomize/overlays/{dev,staging,prod}` into its own namespace.

Both share the same `argocd/project.yml` `AppProject` — see that file's comments for which
`destinations`/whitelist entries belong to which path.

## Cluster Configuration

```yaml
# kind-config.yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
  - role: control-plane
    extraPortMappings:
      - containerPort: 30080 # for gateway api
        hostPort: 30080
        protocol: TCP
      - containerPort: 30001 # for ArgoCD UI
        hostPort: 30001
        protocol: TCP
```

## 1. Install and Configure ArgoCD

### Create ArgoCD Namespace

```bash
kubectl create namespace argocd
```

---

### Install ArgoCD

```bash
kubectl apply -n argocd \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

> Note: Installing using manifest because the metrics services of ArgoCD will be created by only official manifests, not with Helm. This is required for monitoring ArgoCD.

### Verify Installation

```bash
watch kubectl get pods -n argocd
```

Ensure all pods are in **Running** state.

---

### Configure Service Access

```bash
# Check services
kubectl get svc -n argocd

# Change to NodePort
kubectl patch svc argocd-server -n argocd \
  -p '{"spec": {"type": "NodePort", "ports": [{"port": 80, "targetPort": 8080, "nodePort": 30001}]}}'

# Confirm change
kubectl get svc -n argocd
```

---

### Access ArgoCD UI

```bash
# Get NodePort
kubectl get svc argocd-server -n argocd
```

Access at: `http://localhost:30001`

---

### Get Admin Credentials

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
```

- **Username:** `admin`
- **Password:** Use output from above command

> Change the default password after first login in **User Info**.

## 2. Integration with Email (Optional)

### Step 1: Install Triggers and Templates from the catalog
```bash
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/notifications_catalog/install.yaml
```

### Step 2: Configure SMTP Secret

Create a Kubernetes Secret with SMTP credentials:

Use: [notifications/secret-smtp.yml](../argocd/notifications/secret-smtp.yml)

> Replace `your-email@example.com` with your actual sender gmail address (In which you have created app password).

> Replace `your-smtp-password` with your actual app password created in gmail as it is (remove spaces between them).


Apply it:

```bash
kubectl apply -f argocd/notifications/secret-smtp.yml
```
---

### Step 3: Configure Notification ConfigMap

ArgoCD Notifications configuration lives in `argocd/notifications/configmap.yml` ConfigMap.

Apply it:
```bash
kubectl apply -f argocd/notifications/configmap.yml
```

### Step 4. Update ArgoCD Application Manifest
> Note: Add the annotations in your application manifest file for which you want to get notifications.

![argo-notify-annota](./assets/argocd/argo-notify-annota.png)

## 3. Deploy the Application

### Configure Gateway API

Gateway API installation and configuration steps are already documented in **[`docs/Helm.md`](./Helm.md)**.

Since **Argo CD deploys the same Helm chart**, this guide does not repeat those steps again.
Please refer to **[`docs/Helm.md`](./Helm.md)** to set up the Gateway API and expose the application externally.

---

### Method 1: Using Manifests

```bash
kubectl apply -f argocd/project.yml
kubectl apply -f argocd/application.yml
```
![argo-ui-latest](./assets/argocd/argo-ui-latest.png)
![argo-success-mail](./assets/argocd/argo-success-mail.png)

### Access the Application

✅ Make sure you have completed the application exposure steps from [docs/Helm.md](./Helm.md)


Then access Application at `http://localhost:30080`
![argocd-app-ui](./assets/argocd/argocd-app-ui.png)

<details>
<summary><strong>Method 2: Using ArgoCD UI</strong></summary>

#### Connect to Repository

1. Click **New App** in ArgoCD dashboard
2. Configure application:
   - **Application Name:** `mern-devops`
   - **Project:** `default`
   - **Sync Policy:** `Manual` or `Automatic`
   - Select `Auto-Create Namespace`

![argocd-1](./assets/argocd/argocd-1.png)

#### Configure Repository

- **Repository URL:** `https://github.com/atkaridarshan04/CloudNative-DevOps-Blueprint.git`
- **Revision:** `main`
- **Path:** `kubernetes`

![argocd-2](./assets/argocd/argocd-2.png)

#### Set Destination

- **Cluster:** Default cluster
- **Namespace:** `mern-devops`

![argocd-3](./assets/argocd/argocd-3.png)

#### Deploy Application

1. Click **Create**
2. Sync the application in ArgoCD dashboard

![argocd-4](./assets/terraform/terraform_argocd.png)
![argocd-5](./assets/argocd/argocd-5.png)

</details>


## 4. Monitor Application

1. Ensure Prometheus and Grafana are set up in the cluster. Steps: [Monitoring.md](./Monitoring.md)
2. Apply the ArgoCD service monitor configuration:
    ```bash
    kubectl apply -f argocd/monitoring/service-monitor.yml
    ```
    > Note: Ensure the `release` label matches your Prometheus installation. In this case, it's set to `monitoring`.

![Argocd Dashboard](./assets/argocd/argocd-dashboard.png)

---

## 5. Multi-Environment Deployment (Kustomize overlays)

**Path B** from the [Two Deployment Paths](#-two-deployment-paths-in-this-repo) section above
— an alternative to §3's Helm-chart Application, not something layered on top of it. Three
`Application`s — `argocd/application-dev.yml`, `argocd/application-staging.yml`,
`argocd/application-prod.yml` — each watching its own `kustomize/overlays/{dev,staging,prod}`
path and syncing into its own namespace. They share the same `book-store` `AppProject` as §3,
which whitelists `dev`/`staging`/`prod` as destinations alongside `mern-devops`.

```mermaid
flowchart LR
    Git[(Git repo<br/>kustomize/overlays/)]

    Git -->|dev| AppDev[Application<br/>book-store-dev]
    Git -->|staging| AppStaging[Application<br/>book-store-staging]
    Git -->|prod| AppProd[Application<br/>book-store-prod]

    AppDev --> NsDev[namespace: dev]
    AppStaging --> NsStaging[namespace: staging]
    AppProd --> NsProd[namespace: prod]

    classDef store fill:#2ea043,color:#fff,stroke:#2ea043
    classDef controller fill:#1f6feb,color:#fff,stroke:#1f6feb
    classDef workload fill:#57606a,color:#fff,stroke:#57606a

    class Git store
    class AppDev,AppStaging,AppProd controller
    class NsDev,NsStaging,NsProd workload
```

```bash
kubectl apply -f argocd/project.yml
kubectl apply -f argocd/application-dev.yml
kubectl apply -f argocd/application-staging.yml
kubectl apply -f argocd/application-prod.yml
```

See [`docs/Kustomize.md`](./Kustomize.md#gitops-deployment-via-argocd-multi-environment)
for the full context.

**Two ways to run this path.** Standalone, as described above: manually edit
`kustomize/overlays/{dev,staging,prod}/kustomization.yml` yourself and let these three
`Application`s sync whatever you commit — no approval step, no cross-environment ordering.
Or let [`Kargo.md`](./Kargo.md) drive it: Kargo watches the image registries, decides what's
allowed to move from `dev` → `staging` → `prod` (and only once the upstream environment is
actually healthy, not just synced), and opens a PR for each bump instead of you editing
overlays by hand. Both modes point at the exact same three `Application`s here — Kargo just
adds a promotion/approval layer in front of the Git commits ArgoCD reacts to; it doesn't
replace or duplicate anything in this section.

---
