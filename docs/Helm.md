#  📦 Packaging & Deploying Applications with Helm Charts

> 📘 See [concepts/HelmVsKustomize.md](./concepts/HelmVsKustomize.md) for how Helm compares to Kustomize and when to reach for each.

## Step 1: Cluster Setup

Cluster Configuration: `kind-config.yaml`
```yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
  - role: control-plane
    extraPortMappings:
      - containerPort: 80   # for nginx ingress
        hostPort: 80
        protocol: TCP
      - containerPort: 30080 # for gateway api
        hostPort: 30080
        protocol: TCP
```

- Run the following command to create a Kubernetes cluster using the provided `kind-config.yaml`:

  ```bash
  kind create cluster --config kind-config.yaml
  ```

- Create **mern-devops** namespace:

  ```bash
  kubectl create namespace mern-devops
  ```

## Step 2: Install Envoy Gateway Controller with Gateway API CRDs

```bash
helm install eg oci://docker.io/envoyproxy/gateway-helm --version v0.0.0-latest -n envoy-gateway-system --create-namespace
```

Wait for Envoy Gateway to become available:

```bash
kubectl wait --timeout=5m -n envoy-gateway-system deployment/envoy-gateway --for=condition=Available
```


## Step 3: Install the Helm Chart

```bash
helm install mern-devops ./helm-chart
```

## Step 4: Verify

### List Helm releases:

```bash
helm ls
```
![helm-install](./assets/helm/helm-ls.png)

Check the status of all resources:

```bash
kubectl get all -n mern-devops
```
![helm-get-all](./assets/helm/helm-get-all.png)


### Verify Gateway API Resources

```bash
kubectl get gatewayclass
kubectl get gateway -n mern-devops
kubectl get httproute -n mern-devops
```
![gateway-api-resources](./assets/kubernetes/gateway-api-resources.png)

> **⚠️ Important:** If running locally, the gateway status will show `Programmed: False` since kind has no LoadBalancer support. The NodePort patch in the next step resolves this for local access.

#### Verify Envoy Gateway Resources

```bash
kubectl get pods -n envoy-gateway-system
kubectl get svc -n envoy-gateway-system
```

### Access the Application

> **🔧 Local Testing Only:** Patch the envoy gateway service to NodePort for local access. Not needed in production (use LoadBalancer or proper DNS).

Get the envoy gateway service name:

```bash
kubectl get svc -n envoy-gateway-system
# Look for the service named: mern-devops-envoy-gateway-<hash>
```

Patch it to NodePort:

```bash
kubectl patch svc <service-name> -n envoy-gateway-system \
  -p '{"spec":{"type":"NodePort","ports":[{"port":80,"nodePort":30080,"protocol":"TCP"}]}}'
```
![envoy-mern-devops-gateway-patch](./assets/kubernetes/envoy-mern-devops-gateway-patch.png)

Access the application at:
```
http://localhost:30080
```
![gateway-api-webapp](./assets/kubernetes/gateway-api-webapp.png)

## Step 5: Cleanup

```bash
helm uninstall mern-devops
```

Confirm removal:

```bash
helm ls
kubectl get ns
```

---

## (Optional) Publish Helm Chart to GHCR (OCI)

This project supports publishing and consuming the Helm chart using **GitHub Container Registry (GHCR)** as an **OCI registry**.

---

### 1) Login to GHCR

```bash
export GHCR_USERNAME="atkaridarshan04"
export GHCR_TOKEN="<your_github_token>"

echo $GHCR_TOKEN | helm registry login ghcr.io -u $GHCR_USERNAME --password-stdin
```

---

### 2) Package the Helm Chart

Run this inside the chart directory (where `Chart.yaml` exists):

```bash
helm package .
```

This generates a versioned chart archive like:

```
mern-chart-2.0.0.tgz
```

---

### 3) Push the Chart to GHCR

```bash
helm push mern-chart-2.0.0.tgz oci://ghcr.io/atkaridarshan04/helm-charts
```

This will publish the chart as:

```
ghcr.io/atkaridarshan04/helm-charts/mern-charts:2.0.0
```

---

### 4) Pull the Chart from GHCR

```bash
helm pull oci://ghcr.io/atkaridarshan04/helm-charts/mern-chart --version 2.0.0
```

(Optional) Extract it:

```bash
helm pull oci://ghcr.io/atkaridarshan04/helm-charts/mern-chart --version 2.0.0 --untar
```

---

### 5) Install the Chart from GHCR

```bash
helm install mern-devops oci://ghcr.io/atkaridarshan04/helm-charts/mern-chart --version 2.0.0
```

---

### 6) Upgrade an Existing Release

```bash
helm upgrade mern-devops oci://ghcr.io/atkaridarshan04/helm-charts/mern-chart --version 2.0.0
```

---

### 7) Show Chart Metadata (Verify Version)

```bash
helm show chart oci://ghcr.io/atkaridarshan04/helm-charts/mern-chart --version 2.0.0
```


---
