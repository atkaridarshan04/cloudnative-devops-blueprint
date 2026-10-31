# 📕 Alert Runbooks

One entry per custom alert in [`observability/monitoring/alerts/`](../observability/monitoring/alerts), plus the dead man's switch alarm. Each alert's `runbook_url` links to its heading here.

Chart-default alerts (`Kube*`, `Node*`, `Prometheus*`) link to the upstream [runbooks.prometheus-operator.dev](https://runbooks.prometheus-operator.dev/) instead. For how alerts are routed and delivered, see [Monitoring.md](./Monitoring.md#-alerting).

## 📋 Overview

| Alert | Severity | Fires after | Inhibited by |
|---|---|---|---|
| [DeploymentFullyDown](#deploymentfullydown) | 🔴 critical | 5m | — |
| [DeploymentDegraded](#deploymentdegraded) | 🟡 warning | 15m | DeploymentFullyDown |
| [DeploymentRolloutStuck](#deploymentrolloutstuck) | 🟡 warning | 20m | — |
| [StatefulSetFullyUnavailable](#statefulsetfullyunavailable) | 🔴 critical | 5m | — |
| [StatefulSetReplicasNotReady](#statefulsetreplicasnotready) | 🟡 warning | 10m | StatefulSetFullyUnavailable |
| [ContainerOOMKilled](#containeroomkilled) | 🔴 critical | immediately | — |
| [ContainerMemoryNearLimit](#containermemorynearlimit) | 🟡 warning | 15m | — |
| [ContainerHighCPUThrottling](#containerhighcputhrottling) | 🟡 warning | 20m | — |
| [ArgoCDAppDegraded](#argocdappdegraded) | 🔴 critical | 5m | ArgoCDAppSyncFailed |
| [ArgoCDAppSyncFailed](#argocdappsyncfailed) | 🔴 critical | 5m | — |
| [ArgoCDAppSyncStuck](#argocdappsyncstuck) | 🟡 warning | 20m | — |
| [ArgoCDAppUnhealthy](#argocdappunhealthy) | 🟡 warning | 20m | — |
| [ArgoCDControllerDown](#argocdcontrollerdown) | 🔴 critical | 5m | — |
| [Heartbeat missing](#heartbeat-missing) | 🔴 CloudWatch alarm | 15m | — |

A 🔴 critical alert also inhibits a 🟡 warning of the same name in the same namespace, and critical alerts repeat every 3h.

---

## 🚀 Deployments

### DeploymentFullyDown

🔴 **critical** · fires after 5m · Deployment not paused

Every replica is unavailable. The service is unreachable.

**Check**

```bash
kubectl get pods -n <namespace>
kubectl describe pod -n <namespace> <pod>
kubectl logs -n <namespace> <pod> --previous
```

**Usual causes**

- Unpullable image
- Failing readiness probe
- Startup crash (bad config or missing secret)
- Nothing schedulable

**Fix**

If a rollout caused it, roll back, which restores service fastest:

```bash
kubectl rollout undo deployment/<name> -n <namespace>
```

### DeploymentDegraded

🟡 **warning** · fires after 15m · more than 25% of replicas unavailable · inhibited by `DeploymentFullyDown`

The service is up with reduced capacity.

**Check**

Compare failing pods against healthy ones:

```bash
kubectl get pods -n <namespace> -o wide
```

**Usual causes**

- A bad node
- A PVC pinned to one AZ
- An unsatisfiable anti-affinity rule

**Fix**

If every failure is on one node, cordon it: `kubectl cordon <node>`.

### DeploymentRolloutStuck

🟡 **warning** · fires after 20m · `metadata.generation` ahead of `status.observedGeneration`

A new revision was submitted but not rolled out.

**Check**

```bash
kubectl rollout status deployment/<name> -n <namespace>
kubectl describe deployment <name> -n <namespace>   # see Conditions
```

**Usual cause**

The new ReplicaSet can't reach readiness, so the old one never scales down.

---

## 🗄️ StatefulSets

### StatefulSetFullyUnavailable

🔴 **critical** · fires after 5m · zero ready replicas

Typically a database or message broker. Expect knock-on failures in whatever depends on it.

**Check**

Pods start **in order**, so diagnose the lowest-ordinal pod first, and check storage before blaming the app:

```bash
kubectl get pvc -n <namespace>
kubectl describe pod -n <namespace> <statefulset>-0
```

**Usual causes**

- Unbindable PVC (wrong StorageClass, AZ mismatch)
- Failing readiness probe on `-0`, which blocks the rest

### StatefulSetReplicasNotReady

🟡 **warning** · fires after 10m · some but not all replicas ready · inhibited by `StatefulSetFullyUnavailable`

For quorum services, losing a majority stops writes even while some pods look up.

**Check**

```bash
kubectl get pods -n <namespace> -l <statefulset-selector>
kubectl describe pod -n <namespace> <not-ready-pod>
```

---

## 📦 Containers

### ContainerOOMKilled

🔴 **critical** · fires immediately · OOM kill in the last 10m

The event is instantaneous, so there is no `for:` delay.

**Check**

```bash
kubectl describe pod -n <namespace> <pod>   # Last State: Terminated, Reason: OOMKilled
```

Compare the limit against actual usage in Grafana over 30 days:

```promql
max_over_time(container_memory_working_set_bytes{container="<name>"}[30d])
```

**Fix**

- **Limit too low**: raise it to the observed peak.
- **Leak** (usage climbs and never plateaus): fix the leak. Raising the limit only delays the kill.

### ContainerMemoryNearLimit

🟡 **warning** · fires after 15m · working set above 90% of the limit

`ContainerOOMKilled` is likely next.

**Check**

Containers closest to their limit, worst first:

```promql
topk(10,
  container_memory_working_set_bytes{container!=""}
  / on(namespace, pod, container)
  kube_pod_container_resource_limits{resource="memory"}
)
```

### ContainerHighCPUThrottling

🟡 **warning** · fires after 20m · more than 50% of CPU periods throttled

The container is being slowed by its own limit, so latency will be visibly bad.

**Check**

CPU p95 in Grafana, ignoring the first 5m after start so startup bursts don't skew it.

**Fix**

Raise or remove the CPU limit. A limit is a throttle, not a safety net: the request already guarantees the share, so don't reserve the startup burst permanently.

---

## 🔄 ArgoCD

Highest-signal alerts in this set: broken ArgoCD blocks deploys for everyone.

### ArgoCDAppDegraded

🔴 **critical** · fires after 5m · health `Degraded` · inhibited by `ArgoCDAppSyncFailed`

The app synced, but the resulting workload is unhealthy.

**Check**

Pods in the target namespace. The Deployment and StatefulSet entries above apply.

### ArgoCDAppSyncFailed

🔴 **critical** · fires after 5m · `Degraded` **and** `OutOfSync`

A sync ran and left the app broken.

**Check**

Last Sync → Result in the ArgoCD UI.

**Usual causes**

- Invalid manifest
- Missing CRD
- Admission webhook rejection (for example a Kyverno policy)

**Fix**

Fix in git and re-sync. Don't hand-edit the live resource: ArgoCD reverts it if self-heal is on.

### ArgoCDAppSyncStuck

🟡 **warning** · fires after 20m · `Progressing` and not `Synced`

Not failed, but not converging, and it blocks later syncs.

**Check**

The ArgoCD UI shows which resource is still progressing.

### ArgoCDAppUnhealthy

🟡 **warning** · fires after 20m · health `Missing` or `Unknown`

- `Missing`: someone usually deleted a live resource by hand.
- `Unknown`: often a referenced CRD isn't installed.

### ArgoCDControllerDown

🔴 **critical** · fires after 5m · no `argocd_app_info` series

> [!WARNING]
> Every other ArgoCD alert is blind while this one fires, because they all read the same metric.

It uses `absent()` rather than `up == 0` deliberately: a deleted ServiceMonitor or renamed job label produces no series, and `up == 0` can't fire on a series that doesn't exist.

**Check**

The controller pod first. If it's healthy, the metrics pipeline is at fault:

```promql
count by (job) (up)
```

Compare the job label against the ServiceMonitors in [`argocd/monitoring/service-monitor.yml`](../argocd/monitoring/service-monitor.yml).

---

## 💓 Dead man's switch

### Heartbeat missing

🔴 **CloudWatch alarm** `<cluster>-alertmanager-heartbeat-missing` · fires after 15m with no heartbeat

> [!IMPORTANT]
> This is a monitoring outage, not a false positive. While it fires, no alert can reach anyone, so treat the cluster as unmonitored.

Alertmanager publishes the always-firing `Watchdog` alert to the heartbeat SNS topic every 5m. This alarm fires when that stream stops.

**Check, in order**

```bash
# 1. Are Prometheus and Alertmanager running?
kubectl get pods -n monitoring

# 2. Is Watchdog firing in Prometheus?  (query: ALERTS{alertname="Watchdog"})
kubectl port-forward -n monitoring svc/monitoring-kube-prometheus-prometheus 9090:9090

# 3. Is Alertmanager failing to publish?
kubectl logs -n monitoring alertmanager-monitoring-kube-prometheus-alertmanager-0 \
  -c alertmanager | grep -i "Notify for alerts failed"

# 4. Is the pod assuming the IRSA role?
kubectl get pod -n monitoring alertmanager-monitoring-kube-prometheus-alertmanager-0 \
  -o jsonpath='{.spec.containers[0].env[?(@.name=="AWS_ROLE_ARN")].value}'
```

**Usual causes**

| Symptom | Cause | Fix |
|---|---|---|
| Pods down or crash-looping | Prometheus or Alertmanager outage | Fix the pod; the alarm clears on the next heartbeat |
| `403 ... not authorized to perform: SNS:Publish` | Pod started before the IRSA annotation, or role trust mismatch | Delete the Alertmanager pod; check the role's trust policy |
| Watchdog not in Prometheus | Rule group disabled or Prometheus not evaluating rules | Check `defaultRules.rules.general` and Prometheus rule status |
| Everything healthy, still no heartbeat | A silence on `Watchdog` | Expire it in the Alertmanager UI |
| Alarm stays `ALARM` from first deploy, publishes visible in logs | The metric isn't reported for this topic | See the WARNING in [Monitoring.md](./Monitoring.md#dead-mans-switch) |

An `OK` email follows once heartbeats resume.
