# Running on kind (local)

Everything in the root `README.md` applies here too — architecture, GitOps flow, defense in
depth, the manual-secrets sequence. This file only covers what's different about running the
same stack on a local `kind` cluster instead of EKS: no Terraform, no real cloud load
balancer, no real DNS.

## Prerequisites

- `kind`, `kubectl`, `helm`
- `kind-config.yml` (repo root) — local cluster config, includes the `extraPortMappings`
  used below to reach the cluster from `localhost:80`/`443`

## Bootstrap

Unlike EKS (where `terraform apply` handles ArgoCD's own install, the Gateway API CRDs, both
`AppProject`s, and the root Application), all of that is manual here — see
`terraform/modules/argocd/main.tf` for the exact sequence being replicated by hand below:

```bash
kind create cluster --config kind-config.yml

helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

helm install argocd argo/argo-cd -n argocd --create-namespace -f argocd/values.yaml

# HTTPRoute is a Gateway API CRD — must exist before ArgoCD's own route below can be
# created. Normally installed as the gateway-api-crds Application (wave 0), but that only
# starts existing once root-application.yml is applied further down — a fresh cluster has
# no HTTPRoute kind yet, so install it once by hand here. --server-side because the bundle's
# embedded OpenAPI schemas are too large for client-side apply's annotation limit.
kubectl apply --server-side -f gateway/gateway-api-crds.yaml
kubectl apply -f argocd/httproute.yml   # ArgoCD's own route — manual, since ArgoCD isn't self-managed

kubectl apply -f argocd/project.yml
kubectl apply -f argocd/platform-project.yml
kubectl apply -f argocd/root-application.yml
```

```bash
kubectl get application -n argocd
# watch the waves land: gateway-api-crds (0) → cert-manager/istio/external-secrets/
# kyverno/argo-rollouts (1) → gateway-platform (2) → book-store-{dev,staging,prod}/monitoring/
# kiali (3) → kargo (4) → sso-oauth2-proxy (5, optional)
```

From here, follow the root README's "Secrets: still-manual steps" section exactly as
written — it's identical on `kind` and EKS.

## ArgoCD upgrades

Also manual here, same reasoning as the initial install:

```bash
helm upgrade argocd argo/argo-cd -n argocd -f argocd/values.yaml
```

## Verify + DNS

`kind` has no cloud load balancer to hand out a real address — the Gateway's backing Service
lands on random `NodePort`s. Pin them to the exact ports `kind-config.yml`'s
`extraPortMappings` forwards from `localhost:80`/`443`:

```bash
kubectl patch svc istio-gateway-istio -n mern-devops --type=json -p '[
  {"op":"replace","path":"/spec/ports/1/nodePort","value":30080},
  {"op":"replace","path":"/spec/ports/2/nodePort","value":30443}
]'
```

Then point every hostname at your own machine (real DNS/Cloudflare only matters for the
Let's Encrypt DNS-01 challenge itself, not for reaching the Gateway locally):

```bash
echo "127.0.0.1 app.cndb.atkaridarshan.online
127.0.0.1 dev.cndb.atkaridarshan.online
127.0.0.1 staging.cndb.atkaridarshan.online
127.0.0.1 argocd.cndb.atkaridarshan.online
127.0.0.1 kargo.cndb.atkaridarshan.online
127.0.0.1 grafana.cndb.atkaridarshan.online
127.0.0.1 argorollouts.cndb.atkaridarshan.online" | sudo tee -a /etc/hosts
```

From here, the browser-access table and everything else in the root README's "Verify + DNS"
section applies as-is — same URLs, same logins, same port-forward-only tools.

## Tear down

```bash
kind delete cluster
```

No separate state to clean up — unlike EKS, there's no bootstrap S3 bucket or Terraform
state involved on `kind` at all.
