# 🚚 Progressive Delivery Across Environments with Kargo

> 📘 See [`concepts/Kargo.md`](./concepts/Kargo.md) for the object model (Project, Warehouse,
> Freight, Stage, Promotion, PromotionTask), why the promotion chain works the way it does,
> and the theme-color design conflict this setup resolves. Read that first — this doc is
> just the runnable checklist.

Depends on [`docs/ArgoCD.md`](./ArgoCD.md) §5 and [`docs/Kustomize.md`](./Kustomize.md) — the
three per-environment ArgoCD `Application`s need to already be `Synced`/`Healthy` on their
own, standalone, before anything here will make sense.

## ⚠️ Before applying anything

Kargo's promotion-step schema has genuinely changed shape across releases. The manifests in
`kargo/` were written against the current docs at
[docs.kargo.io](https://docs.kargo.io/user-guide/reference-docs/promotion-steps) — but
verify against your installed version before trusting them blindly:

```bash
kargo version
kubectl explain warehouse.spec.subscriptions.image --recursive
```

A mismatch here won't error loudly — a `Warehouse` or `Promotion` will just silently never
produce the result you expect.

## Step 1 — Install cert-manager (real prerequisite, easy to miss)

Kargo's Helm chart requires cert-manager already running in the cluster — it provisions the
TLS certs Kargo's own webhook servers need:

```bash
helm repo add jetstack https://charts.jetstack.io
helm repo update
helm install cert-manager jetstack/cert-manager \
  -n cert-manager --create-namespace \
  --set crds.enabled=true

kubectl get pods -n cert-manager
```

## Step 2 — Install Kargo

Kargo ships as an OCI Helm chart, not a classic chart-repo install, and needs a generated
admin password + signing key even for local testing:

```bash
pass=$(openssl rand -base64 48 | tr -d "=+/" | head -c 32)
hashed_pass=$(htpasswd -bnBC 10 "" "$pass" | tr -d ':\n')
signing_key=$(openssl rand -base64 48 | tr -d "=+/" | head -c 32)
echo "Kargo admin password: $pass"   # save this, you'll need it to log into the UI

helm install kargo \
  oci://ghcr.io/akuity/kargo-charts/kargo \
  --namespace kargo \
  --create-namespace \
  --set api.adminAccount.passwordHash="$hashed_pass" \
  --set api.adminAccount.tokenSigningKey="$signing_key" \
  --wait

kubectl get pods -n kargo
# all pods Running before continuing
```

> This configuration is only suitable for trying Kargo locally, not for anything
> internet-facing — see [Advanced Installation](https://docs.kargo.io/operator-guide/advanced-installation/advanced-with-helm) if that ever matters here.

**Accessing the dashboard, for now:** unlike ArgoCD/Ingress, no NodePort/hostPort is mapped
for Kargo in `kind-config.yml` — adding one would mean recreating the cluster, which isn't
worth it just to reach a UI. `kubectl port-forward` is the right tool for exactly this
temporary, local-only access case:

```bash
kubectl port-forward svc/kargo-api -n kargo 8443:443
```

Open `https://localhost:8443` and log in with the admin password saved from Step 2. The
`kargo-api` Service serves HTTPS on `443` with a self-signed/local cert — your browser will
flag it as untrusted, same as the Let's Encrypt staging warnings elsewhere in this repo;
accept and continue.

## Step 3 — Create the Project

```bash
kubectl apply -f kargo/project.yml
kubectl get namespace book-store
# should exist, created by the Project controller
```

## Step 4 — Authorize the ArgoCD Applications

Already present as annotations on `argocd/application-{dev,staging,prod}.yml`
(`kargo.akuity.io/authorized-stage: book-store:<stage>`) — re-apply them if you haven't
since this was added:

```bash
kubectl apply -f argocd/application-dev.yml
kubectl apply -f argocd/application-staging.yml
kubectl apply -f argocd/application-prod.yml
```

Without this annotation, Kargo refuses to touch these `Application`s at all — a deliberate
safety boundary, not a bug.

## Step 5 — Create the Warehouse, confirm Freight actually appears

```bash
kubectl apply -f kargo/warehouse.yml
kubectl get freight -n book-store -w
```

**Stop here and confirm Freight shows up before continuing.** This is the step most likely
to silently misbehave if something in the subscription config doesn't match reality — fix
it here, in isolation, rather than debugging it later tangled up with Stage/Promotion issues
too.

## Step 6 — Create the PromotionTask and the three Stages

```bash
kubectl apply -f kargo/promotion-task.yml
kubectl apply -f kargo/stage-dev.yml
kubectl apply -f kargo/stage-staging.yml
kubectl apply -f kargo/stage-prod.yml

kubectl get stages -n book-store
```

`dev` should pick up the existing Freight and promote automatically (`sources.direct: true`
means it takes any new Freight right away). Watch it happen:

```bash
kubectl get promotions -n book-store -w
```

## Step 7 — Verify the full chain

```bash
kubectl get stages -n book-store
# dev picks up new Freight first; staging and prod only move once their upstream Stage
# is actually verified healthy, not just synced
kubectl get application -n argocd -w
```

If a build makes it all the way to `prod` and the app's theme color visibly changes at each
stage in sequence, that's the whole pipeline confirmed working end to end.

## Related reading

- [`concepts/Kargo.md`](./concepts/Kargo.md) — the object model and design notes
- [`ArgoCD.md`](./ArgoCD.md) §5 — the per-environment `Application`s this depends on
- [Kargo docs: Basic Installation](https://docs.kargo.io/operator-guide/basic-installation)
- [Kargo docs: Working with Warehouses](https://docs.kargo.io/user-guide/how-to-guides/working-with-warehouses)
- [Kargo docs: Working with Stages](https://docs.kargo.io/user-guide/how-to-guides/working-with-stages)
- [Kargo docs: Argo CD Integration](https://docs.kargo.io/user-guide/how-to-guides/argo-cd-integration)
- [Kargo promotion steps reference](https://docs.kargo.io/user-guide/reference-docs/promotion-steps)
