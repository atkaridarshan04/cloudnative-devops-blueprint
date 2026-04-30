# 📊 Monitoring Stack: Prometheus & Grafana

Complete metrics monitoring setup for Kubernetes with Prometheus and Grafana.

> **For log collection and querying**, see [Logging.md](./Logging.md).

## 🎯 Components

**Monitoring:**
- **Prometheus** - Metrics collection & storage
- **Grafana** - Visualization & dashboards
- **Node Exporter** - System metrics
- **Kube State Metrics** - Kubernetes metrics

## 🚀 Setup

### 1. Cluster Configuration

**kind-config.yaml**
```yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
  - role: control-plane
    extraPortMappings:
      - containerPort: 80
        hostPort: 80
        protocol: TCP
      - containerPort: 30002 # prometheus
        hostPort: 30002
        protocol: TCP
      - containerPort: 30003 # grafana
        hostPort: 30003
        protocol: TCP
```

```bash
kind create cluster --config kind-config.yaml
```

### 2. Install Stack

```bash
kubectl create namespace monitoring

# Add repositories
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Install
helm install monitoring prometheus-community/kube-prometheus-stack -f ./observability/monitoring/monitoring-values.yml -n monitoring
```

### 3. Expose Services

```bash
# Prometheus
kubectl patch svc monitoring-kube-prometheus-prometheus -n monitoring \
  -p '{"spec": {"type": "NodePort", "ports": [{"port": 9090, "targetPort": 9090, "nodePort": 30002}]}}'

# Grafana
kubectl patch svc monitoring-grafana -n monitoring \
  -p '{"spec": {"type": "NodePort", "ports": [{"port": 80, "targetPort": 3000, "nodePort": 30003}]}}'
```

## 🔗 Access URLs

- **Prometheus:** [http://localhost:30002](http://localhost:30002)
- **Grafana:** [http://localhost:30003](http://localhost:30003) - `admin/password`

---

## 📈 Prometheus

Query metrics using PromQL, view targets, and configure alerts.

<table>
<tr>
<td width="50%"><img src="./assets/observability/prometheus-targets.png" width="100%"/></td>
<td width="50%"><img src="./assets/observability/prometheus-query.png" width="100%"/></td>
</tr>
</table>

---

## 📊 Grafana

Pre-configured dashboards for cluster overview, node metrics, pod performance etc.

<table>
<tr>
<td width="50%"><img src="./assets/observability/grafana-home.png" width="100%"/></td>
<td width="50%"><img src="./assets/observability/grafana-data-source.png" width="100%"/></td>
</tr>
</table>

### Drilldown

<table>
<tr>
<td width="50%"><img src="./assets/observability/metrics-drill.png" width="100%"/></td>
</tr>
</table>

---

## 🎨 Dashboards

<table>
<tr>
<td width="50%"><img src="./assets/observability/graphana-1.png" width="100%"/></td>
<td width="50%"><img src="./assets/observability/graphana-2.png" width="100%"/></td>
</tr>
<tr>
<td width="50%"><img src="./assets/observability/graphana-3.png" width="100%"/></td>
<td width="50%"><img src="./assets/argocd/argocd-dashboard.png" width="100%"/></td>
</tr>
</table>
  