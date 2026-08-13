# 🛡️ Pod Security Admission: Cluster-Level Enforcement

> Hands-on guide: [Kubernetes.md](../Kubernetes.md) (Section 2 — Create a Namespace)

## The problem

[PodSecurityHardening.md](./PodSecurityHardening.md) hardened `backend.yml` and `frontend.yml` by hand — `securityContext`, dropped capabilities, `hostUsers: false`. But nothing stops the *next* manifest in this namespace from skipping all of it. Per-manifest hardening only works if every author remembers to do it, every time.

Pod Security Admission (PSA) is Kubernetes' built-in admission controller for this — it enforces the [Pod Security Standards](https://kubernetes.io/docs/concepts/security/pod-security-standards/) (`privileged` / `baseline` / `restricted`) at the **namespace** level, so the API server itself rejects (or flags) non-compliant pods before they're ever scheduled. No extra controller to install — it's been stable since Kubernetes 1.25.

## Three independent modes, one namespace

```yaml
pod-security.kubernetes.io/enforce: baseline
pod-security.kubernetes.io/audit: restricted
pod-security.kubernetes.io/warn: restricted
```

- **`enforce`** — actually rejects the pod at admission time.
- **`audit`** — allows the pod, but logs a violation to the audit log.
- **`warn`** — allows the pod, but prints a warning back to whoever ran `kubectl apply`.

These are independent and can point at different levels, which is what makes this useful rather than all-or-nothing.

## Why `mern-devops` is `enforce: baseline`, not `enforce: restricted`

`restricted` is the level that actually requires non-root (`runAsNonRoot: true`, non-zero `runAsUser`) and an explicit `seccompProfile`. Checked against what's actually in this namespace:

| Workload | Passes `restricted`? | Why |
|---|---|---|
| `backend` | ✅ Yes | non-root UID 1000, `allowPrivilegeEscalation: false`, capabilities dropped, `seccompProfile: RuntimeDefault` |
| `mongodb` | ✅ Yes | mongo:4.4's image ships a built-in `mongodb` user (UID/GID 999) — runs as that directly instead of root, same capabilities/seccomp treatment as backend |
| `frontend` | ❌ No | nginx forces root — see [PodSecurityHardening.md](./PodSecurityHardening.md) |

Setting `enforce: restricted` on the namespace would still hard-block frontend from ever starting — PSA is a namespace-wide switch, it can't exempt one workload while enforcing another in the same namespace. As long as even one workload has a real reason to run as root, `restricted` isn't a viable *enforce* level for the namespace as a whole.

So the split used in [`kubernetes/namespace.yml`](../../kubernetes/namespace.yml):

- **`enforce: baseline`** — a real floor. Blocks privileged containers, host namespaces (`hostNetwork`/`hostPID`/`hostIPC`), `hostPath` volumes, and dangerous added capabilities — categories nothing in this app legitimately needs, so there's no cost to enforcing it.
- **`audit` + `warn: restricted`** — visibility without blocking. Every `kubectl apply` on frontend prints exactly which restricted-level control it fails, without stopping the deploy. Backend and mongodb now apply clean with zero warnings.

## Verify

**1. Apply the namespace and confirm the labels landed:**

```bash
kubectl apply -f kubernetes/namespace.yml
kubectl get ns mern-devops --show-labels
```

**2. Deploy and watch the warnings:**

```bash
cd kubernetes/
kubectl apply -f secrets.yml
kubectl apply -f mongodb.yml    # clean — restricted-compliant (runs as its built-in UID 999 user)
kubectl apply -f config.yml
kubectl apply -f backend.yml    # clean — already restricted-compliant
kubectl apply -f frontend.yml   # warns: runs as root, no seccompProfile
```

`frontend` is now the only warning left. `backend` and `mongodb` applying clean is the concrete payoff of closing their gaps in [`backend.yml`](../../kubernetes/backend.yml) (`seccompProfile`) and [`mongodb.yml`](../../kubernetes/mongodb.yml) (non-root UID 999, dropped capabilities, `seccompProfile`) — both are now fully `restricted`-compliant, not just `baseline`. frontend can't follow the same path since nginx forces root — that's the one gap this namespace carries on purpose.

**3. Prove `enforce` actually blocks something (not just `warn`):**

```bash
kubectl run privileged-test -n mern-devops --image=nginx --restart=Never \
  --overrides='{"spec":{"containers":[{"name":"privileged-test","image":"nginx","securityContext":{"privileged":true}}]}}'
```

This must be **rejected outright** — `Error from server (Forbidden): ... violates PodSecurity "baseline:latest": privileged (container "privileged-test" must not set securityContext.privileged=true)`. No pod object gets created at all, unlike the mongodb/frontend warnings which still let the pod through.

## Architecture

```mermaid
flowchart TD
    Apply[kubectl apply] --> AdmissionController{PSA admission controller<br/>on mern-devops namespace}

    AdmissionController -->|enforce: baseline| Check1{Privileged? hostNetwork?<br/>hostPath? dangerous caps?}
    Check1 -->|yes| Rejected[❌ Rejected — pod never created]
    Check1 -->|no| Check2{audit/warn: restricted<br/>runAsNonRoot? seccomp?}

    Check2 -->|fails| Warned[⚠️ Created, with warning + audit log entry]
    Check2 -->|passes| Clean[✅ Created, no warning]

    classDef danger fill:#cf222e,color:#fff,stroke:#cf222e
    classDef warn fill:#9a6700,color:#fff,stroke:#9a6700
    classDef safe fill:#2da44e,color:#fff,stroke:#2da44e

    class Rejected danger
    class Warned warn
    class Clean safe
```
