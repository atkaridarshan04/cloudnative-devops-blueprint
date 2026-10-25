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

Namespace creation is handled by `--create-namespace` in Step 4 - no manual step needed.

## Step 2: Install Envoy Gateway Controller with Gateway API CRDs

```bash
helm install eg oci://docker.io/envoyproxy/gateway-helm --version v0.0.0-latest -n envoy-gateway-system --create-namespace
```

Wait for Envoy Gateway to become available:

```bash
kubectl wait --timeout=5m -n envoy-gateway-system deployment/envoy-gateway --for=condition=Available
```


## Step 3: Create the Shared Gateway

The chart's `HTTPRoute` attaches to one shared `Gateway` rather than creating
its own per release - apply this once, before installing the chart for any
environment:

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: GatewayClass
metadata:
  name: envoy-gatewayclass
spec:
  controllerName: gateway.envoyproxy.io/gatewayclass-controller

---
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: envoy-gateway
  namespace: envoy-gateway-system
spec:
  gatewayClassName: envoy-gatewayclass
  listeners:
    - name: http
      protocol: HTTP
      port: 80
      allowedRoutes:
        namespaces:
          from: All
```

Save as `gateway.yaml` and apply:

```bash
kubectl apply -f gateway.yaml
```

`allowedRoutes.namespaces.from: All` is what lets each environment's
`HTTPRoute` (living in `dev`/`staging`/`prod`, not `envoy-gateway-system`)
attach to this one Gateway.

## Step 4: Install the Helm Chart

One release per environment, each with its own namespace and value files.
Shown here for `dev` - `staging`/`prod` follow the same pattern with their
own `values-<env>.yaml`:

```bash
helm install dev ./helm-chart -n dev --create-namespace \
  -f values/values-base.yaml -f values/values-dev.yaml
```

## Step 5: Verify

### List Helm releases:

```bash
helm ls -n dev
```
![helm-install](./assets/helm/helm-ls.png)

Check the status of all resources:

```bash
kubectl get all -n dev
```
![helm-get-all](./assets/helm/helm-get-all.png)


### Verify Gateway API Resources

```bash
kubectl get gatewayclass
kubectl get gateway -n envoy-gateway-system
kubectl get httproute -n dev
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

Find the envoy data-plane service (named after the `envoy-gateway` Gateway from Step 3, in `envoy-gateway-system`):

```bash
kubectl get svc -n envoy-gateway-system
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

## Step 6: Cleanup

```bash
helm uninstall dev -n dev
```

This doesn't remove the namespace or the shared Gateway from Step 3. Full teardown:

```bash
kubectl delete namespace dev
kubectl delete -f gateway.yaml
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
helm install dev oci://ghcr.io/atkaridarshan04/helm-charts/mern-chart --version 2.0.0 \
  -n dev --create-namespace -f values/values-base.yaml -f values/values-dev.yaml
```

---

### 6) Upgrade an Existing Release

```bash
helm upgrade dev oci://ghcr.io/atkaridarshan04/helm-charts/mern-chart --version 2.0.0 \
  -n dev -f values/values-base.yaml -f values/values-dev.yaml
```

---

### 7) Show Chart Metadata (Verify Version)

```bash
helm show chart oci://ghcr.io/atkaridarshan04/helm-charts/mern-chart --version 2.0.0
```


---
