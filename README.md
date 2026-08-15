# Cloudnative DevOps Blueprint — Production GitOps Pipeline

One coherent path from a git push to a running, promoted, secured deployment — not a
collection of isolated demos. `git push` → **Kargo** watches the image registry and drives
promotion **dev → staging → prod** via PR → **ArgoCD** syncs each environment's
**Kustomize** overlay → **Argo Rollouts** runs the change through a canary, shifting traffic
via **Istio**'s native `VirtualService`/`DestinationRule` traffic management → mongodb credentials never touch git, synced
live from **Vault** via **ExternalSecrets** → every admission is checked by **Pod Security
Admission** and **Kyverno**, every namespace defaults to **zero-trust NetworkPolicies**, and
every mesh connection is **mTLS** by default. TLS, domain routing, and SSO across the
platform UIs (from this branch's `domain-and-tls` origin) sit underneath all of it.

Concept explanations — the "why" behind each piece — live on `main` and the single-feature
branches this one draws from (`domain-and-tls`, `kargo-promotion`). This branch is the
integration: only what's needed to stand the whole pipeline up.

Terraform/EKS provisioning is intentionally out of scope here — this targets an
already-existing cluster. Moving this onto real EKS, and layering Velero backup/DR on top,
are deliberate later steps once this is proven out.

## Architecture

### End-to-end (one environment; dev/staging/prod are structurally identical)

```mermaid
flowchart TD
    Browser["Browser<br/>https://{env}.cndb... (prod: app.cndb...)"] --> GW

    subgraph MD["mern-devops namespace"]
        GW["Istio Gateway: istio-gateway<br/>HTTP :80 / HTTPS :443, TLS Terminate<br/>wildcard hostname *.cndb.atkaridarshan.online"]
    end

    subgraph IS["istio-system namespace"]
        Istiod["istiod (control plane)"]
        PA["PeerAuthentication: default<br/>mTLS STRICT, mesh-wide"]
    end

    subgraph CM["cert-manager namespace"]
        CI["ClusterIssuer<br/>letsencrypt-staging / letsencrypt-prod"]
    end

    subgraph ENV["env namespace: dev / staging / prod<br/>PSA enforce=baseline, istio-injection=enabled"]
        Route["HTTPRoute: mern-route<br/>(plain 100%, no weight split here)"]
        FESvc["frontend-service (single)"]
        BESvc["backend-service (single)"]
        FEDR["frontend DestinationRule<br/>subsets: stable / canary"]
        BEDR["backend DestinationRule<br/>subsets: stable / canary"]
        FEVS["frontend VirtualService<br/>weighted stable/canary (mesh-only)"]
        BEVS["backend VirtualService<br/>weighted stable/canary (mesh-only)"]
        FE["frontend Rollout<br/>+ istio-proxy sidecar"]
        BE["backend Rollout<br/>+ istio-proxy sidecar"]
        DB[("mongodb StatefulSet<br/>+ istio-proxy sidecar")]
        NP["NetworkPolicy<br/>default-deny-all + explicit allows"]
        ES["ExternalSecret: mongodb-external-secret"]
        Sec["Secret: mongodb-credentials-external"]
    end

    subgraph VNS["vault namespace"]
        Vault[("Vault, dev-mode")]
    end

    CSS["ClusterSecretStore: vault-backend<br/>(shared across dev/staging/prod)"]

    Istiod -.->|"config + certs"| FE
    Istiod -.->|"config + certs"| BE
    Istiod -.->|"config + certs"| DB
    Istiod -.->|"provisions + configures"| GW
    CI -->|"certificateRefs: wildcard-tls"| GW

    GW --> Route
    Route -->|"path /"| FESvc
    Route -->|"path /books"| BESvc
    FESvc -.->|"VirtualService intercepts<br/>at the sidecar"| FEVS -->|"routes via subset"| FEDR --> FE
    BESvc -.->|"VirtualService intercepts<br/>at the sidecar"| BEVS -->|"routes via subset"| BEDR --> BE
    BE -->|"mTLS, NetworkPolicy allows :27017"| DB
    BE -.->|"env from"| Sec
    DB -.->|"env from"| Sec
    ES -->|"via"| CSS -->|"reads secret/{env}/mern-backend/mongodb"| Vault
    ES -->|"creates"| Sec

    classDef gateway fill:#1f6feb,color:#fff,stroke:#1f6feb
    classDef mesh fill:#0b7285,color:#fff,stroke:#0b7285
    classDef certmgr fill:#2ea043,color:#fff,stroke:#2ea043
    classDef app fill:#57606a,color:#fff,stroke:#57606a
    classDef secret fill:#8957e5,color:#fff,stroke:#8957e5
    classDef external fill:#8b949e,color:#000,stroke:#8b949e,stroke-dasharray: 3 3

    class Browser external
    class GW gateway
    class Istiod,PA mesh
    class CI certmgr
    class Route,FESvc,BESvc,FEDR,BEDR,FEVS,BEVS,FE,BE,DB,NP app
    class ES,Sec,CSS,Vault secret
```

Rollouts shifts canary traffic entirely at the mesh layer, using its native Istio
integration: the `VirtualService`'s weighted `stable`/`canary` subsets, patched by the
`DestinationRule`'s `rollouts-pod-template-hash` labels as a rollout progresses.
`HTTPRoute` only handles the external Gateway attachment, at a constant 100% to the single
Service — Istio's own guidance is against attaching `VirtualService` directly to a Gateway
API `Gateway` (relies on internal implementation details, not a stable API contract).

Since Rollouts patches the live `VirtualService`/`DestinationRule` directly rather than
through git, each `book-store-*` Application's `ignoreDifferences` excludes those specific
fields (the weight, the subset labels) — otherwise `selfHeal` would revert a canary's
weight back to git's static value mid-rollout. A canary in progress showing those two
resources as unrelated to sync status is expected, not a stuck sync.

### GitOps promotion pipeline

```mermaid
flowchart TD
    GHCR[("Image repo<br/>new tag published")] -.->|watched by| WH[Kargo Warehouse]
    WH -->|produces| Freight[Freight]

    Freight -->|direct| Dev[Stage: dev]
    Dev -->|verified healthy| Staging[Stage: staging]
    Staging -->|verified healthy| Prod[Stage: prod]

    Dev -->|opens PR, auto-promotion| Git[("GitHub repo<br/>this branch")]
    Staging -->|opens PR, auto-promotion| Git
    Prod -->|opens PR, human merges| Git

    Git -.->|watched by| AppDev[ArgoCD Application<br/>book-store-dev]
    Git -.->|watched by| AppStaging[ArgoCD Application<br/>book-store-staging]
    Git -.->|watched by| AppProd[ArgoCD Application<br/>book-store-prod]

    AppDev -->|sync kustomize/overlays/dev| NsDev[namespace: dev]
    AppStaging -->|sync kustomize/overlays/staging| NsStaging[namespace: staging]
    AppProd -->|sync kustomize/overlays/prod| NsProd[namespace: prod]

    NsDev -->|Rollout picks up new tag| CanaryDev[Argo Rollouts canary<br/>via Istio VirtualService/DestinationRule]
    NsStaging -->|Rollout picks up new tag| CanaryStaging[Argo Rollouts canary<br/>via Istio VirtualService/DestinationRule]
    NsProd -->|Rollout picks up new tag| CanaryProd[Argo Rollouts canary<br/>via Istio VirtualService/DestinationRule]

    classDef store fill:#2ea043,color:#fff,stroke:#2ea043
    classDef controller fill:#1f6feb,color:#fff,stroke:#1f6feb
    classDef workload fill:#57606a,color:#fff,stroke:#57606a

    class GHCR,Freight,Git store
    class WH,Dev,Staging,Prod,AppDev,AppStaging,AppProd controller
    class NsDev,NsStaging,NsProd,CanaryDev,CanaryStaging,CanaryProd workload
```

`dev`/`staging` auto-promote (`kargo/project-config.yml`); `prod` requires a human to merge
the PR Kargo opens. Every promotion is a real commit — `kustomize-set-image` bumps the tag
in that environment's overlay, not a live `kubectl set image` that git would immediately
drift from.

### Defense in depth

Four independent layers, each catching what the others structurally can't:

```mermaid
flowchart LR
    Req["New/updated Pod spec"] --> PSA["Pod Security Admission<br/>namespace label: enforce=baseline<br/>audit/warn=restricted"]
    PSA --> Kyverno["Kyverno ClusterPolicies<br/>require-userns-or-nonroot (closes PSA's<br/>hostUsers blind spot), verify-ghcr-image-signatures,<br/>disallow-latest-tag, require-labels, ..."]
    Kyverno --> API["kube-apiserver admits the Pod"]
    API --> NetPol["NetworkPolicy<br/>default-deny-all + explicit allows<br/>L3/L4, enforced by the CNI"]
    NetPol --> Mesh["Istio sidecar<br/>PeerAuthentication STRICT mTLS<br/>L4/L7, cert-based workload identity"]
    Mesh --> Dest["Destination pod"]

    classDef layer fill:#57606a,color:#fff,stroke:#57606a
    class PSA,Kyverno,NetPol,Mesh layer
```

PSA alone can't block a pod running real root via `hostUsers` left at its default — it has
no concept of Linux user namespaces at all. That's the specific gap
`kyverno/policies/require-userns-or-nonroot.yaml` exists to close.

## Layout

```
.
├── gateway/            # GatewayClass (implicit via Istio), Gateway, ClusterIssuers, Certificate
├── istio/              # mesh-wide policy — PeerAuthentication (STRICT mTLS)
├── kustomize/
│   ├── base/           # frontend/backend Rollouts, VirtualService/DestinationRule subsets,
│   │                   # mongodb, HTTPRoute, NetworkPolicies
│   └── overlays/       # dev/staging/prod — namespace, image tags, per-env patches
├── kargo/              # promotion pipeline: Project, Warehouse, Stages, PromotionTask,
│                       # git credential ExternalSecret, dashboard route + SSO
├── argocd/
│   ├── project.yml, platform-project.yml   # AppProjects — manual bootstrap, not GitOps-synced
│   ├── root-application.yml                # the one Application applied by hand
│   └── applications/                       # everything else — platform tools + book-store, all app-of-apps children
├── argorollouts/       # dashboard route + SSO
├── external-secrets/   # dev-mode Vault, ClusterSecretStore, SSO credential ExternalSecrets
├── kyverno/policies/    # admission policies (pod security, supply chain, best practices)
├── monitoring/         # kube-prometheus-stack + blackbox-exporter, Istio/cert-manager metrics
└── kind-config.yml     # local kind cluster config
```

## Setup

A fresh cluster needs almost no manual `kubectl apply`/`helm install` — ArgoCD reconstructs
the platform *and* the app from git. What ArgoCD **installs** (cert-manager, Istio, External
Secrets, Kyverno, Argo Rollouts, monitoring, Kargo — each as an Application combining its
Helm chart with this repo's extra manifests for it) is separate from what it **manages after
installing** (the same Applications, continuously reconciled). See
`argocd/applications/*.yml` for the actual definitions; what follows is the bootstrap.

### What stays manual, and why

Four things, all genuinely irreducible — everything else self-assembles from one
`kubectl apply`:

1. **The cluster itself** — ArgoCD needs somewhere to run.
2. **ArgoCD itself** — install and every future upgrade (`argocd/values.yaml` changes, e.g.
   enabling SSO) via `helm upgrade` by hand. Deliberately kept as a manual exception rather
   than a self-referential Application — everything else here is GitOps-managed, ArgoCD's
   own lifecycle isn't, for now.
3. **The two `AppProject`s** (`argocd/project.yml`, `argocd/platform-project.yml`) —
   deliberately kept outside GitOps. An Application creating/modifying its own `AppProject`
   would let a compromised git repo grant itself broader RBAC; see
   `argocd/platform-project.yml`'s comment.
4. **Real secret material** — the Cloudflare DNS token, Vault's per-env mongodb credentials,
   GitHub OAuth secrets, Kargo's admin credentials, and Kargo's git credential. None of this
   can live in git by definition; each corresponding Application will sit
   `Progressing`/`Degraded` until its secret exists — expected, not a sync failure to chase.

### Bootstrap

```bash
# Cluster — pick one:
kind create cluster --config kind-config.yml     # local
# or: point kubeconfig at an existing cluster

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

kubectl get application -n argocd
# watch the waves land: gateway-api-crds (0) → cert-manager/istio/external-secrets/
# kyverno/argo-rollouts (1) → gateway-platform (2) → book-store-{dev,staging,prod}/monitoring
# (3) → kargo (4) → sso-oauth2-proxy (5, optional)
```

Sync-waves here are Application-level, gating on each child Application's own `Healthy`
status before the next wave starts — same app-of-apps + sync-wave pattern as any other
dependency graph in ArgoCD, just applied to platform tools instead of app resources.

### Secrets: still-manual steps, once the corresponding wave is up

**Cloudflare DNS token** (unblocks `gateway-platform`'s `ClusterIssuer`s):

```bash
kubectl create secret generic cloudflare-api-token-secret \
  -n cert-manager --from-literal=api-token='<your-cloudflare-dns-edit-token>'
```

Prove the cert on staging before touching Let's Encrypt's production rate limit — edit
`gateway/certificate.yml`'s `issuerRef.name` to `letsencrypt-staging` first, confirm
`READY=True` (`kubectl describe certificate wildcard-tls -n mern-devops`), then switch to
`letsencrypt-prod` and let selfHeal pick up the change.

**mongodb credentials** (unblocks the `ExternalSecret` in each `book-store-*` Application):

```bash
kubectl port-forward -n vault deploy/vault 8200:8200 &
sleep 2

for env in dev staging prod; do
  kubectl exec -n vault deploy/vault -- \
    env VAULT_ADDR=http://127.0.0.1:8200 VAULT_TOKEN=root \
    vault kv put secret/${env}/mern-backend/mongodb username=admin password=<pick-a-real-password-per-env>
done
```

**Kargo admin credentials** — needed before the `kargo` Application's chart source will
produce a working login; see `argocd/applications/kargo.yml`'s comment on why this isn't
inlined as a Helm value:

```bash
pass=$(openssl rand -base64 48 | tr -d "=+/" | head -c 32)
hashed_pass=$(htpasswd -bnBC 10 "" "$pass" | tr -d ':\n')
signing_key=$(openssl rand -base64 48 | tr -d "=+/" | head -c 32)
echo "Kargo admin password: $pass"   # save this
# create/reference a Secret with these — verify against the kargo chart's values schema
```

**Kargo's git credential** — needed before `kargo/promotion-task.yml`'s `git-clone`/
`git-push`/`git-open-pr` steps can do anything. Routed through Vault like mongodb's creds,
not a raw `kubectl create secret` — `kargo/external-secret.yml` labels the Secret it
creates with `kargo.akuity.io/cred-type: git` (how Kargo recognizes a repo credential at
all) via its `target.template`, same mechanism as any other ExternalSecret here. A GitHub
PAT with repo write access works as both the git password and the GitHub API token
`git-open-pr`/`git-wait-for-pr` need:

```bash
kubectl exec -n vault deploy/vault -- \
  env VAULT_ADDR=http://127.0.0.1:8200 VAULT_TOKEN=root \
  vault kv put secret/kargo/git-creds \
    repoURL='https://github.com/atkaridarshan04/CloudNative-DevOps-Blueprint.git' \
    username='<your-github-username>' \
    password='<a-github-pat-with-repo-write-access>'
```

Note there's no separate ArgoCD API credential to create — the `argocd-update` step
authenticates via Kargo's own ServiceAccount RBAC (Kubernetes-native, not a token), gated
per-Stage by the `kargo.akuity.io/authorized-stage` annotation already on each
`book-store-*` Application.

**GitHub OAuth (SSO, optional)** — four separate OAuth Apps (ArgoCD, Grafana, Rollouts
dashboard, Kargo; classic OAuth Apps only support one callback URL each). Kargo bundles its
own Dex broker (`kargo/values.yaml`'s `api.oidc.dex`) — same pattern as ArgoCD, real auth,
unlike the Rollouts dashboard's bolted-on oauth2-proxy. Callback URLs: ArgoCD
`/api/dex/callback`, Grafana `/login/github`, Rollouts `/oauth2/callback`, Kargo
`/dex/callback`.

All four OAuth secrets are sourced from Vault (`external-secrets/sso-secrets.yml` for
ArgoCD/Grafana/Rollouts, `kargo/external-secret.yml` for Kargo) — seed them once:

```bash
kubectl exec -n vault deploy/vault -- \
  env VAULT_ADDR=http://127.0.0.1:8200 VAULT_TOKEN=root \
  vault kv put secret/argocd/dex \
    clientId='<argocd-oauth-app-client-id>' \
    clientSecret='<argocd-oauth-app-client-secret>'

kubectl exec -n vault deploy/vault -- \
  env VAULT_ADDR=http://127.0.0.1:8200 VAULT_TOKEN=root \
  vault kv put secret/monitoring/grafana-oauth \
    clientId='<grafana-oauth-app-client-id>' \
    clientSecret='<grafana-oauth-app-client-secret>'

COOKIE_SECRET=$(python3 -c 'import secrets,base64; print(base64.urlsafe_b64encode(secrets.token_bytes(32)).decode())')
kubectl exec -n vault deploy/vault -- \
  env VAULT_ADDR=http://127.0.0.1:8200 VAULT_TOKEN=root \
  vault kv put secret/argo-rollouts/oauth2-proxy \
    clientId='<rollouts-oauth-app-client-id>' \
    clientSecret='<rollouts-oauth-app-client-secret>' \
    cookieSecret="$COOKIE_SECRET"

kubectl exec -n vault deploy/vault -- \
  env VAULT_ADDR=http://127.0.0.1:8200 VAULT_TOKEN=root \
  vault kv put secret/kargo/github-oauth clientSecret='<kargo-oauth-app-client-secret>'
```

`argocd-dex-external-secret` merges its two keys into the `argocd-secret` ArgoCD's own
chart already created, rather than owning a separate Secret — `creationPolicy: Merge`.

Also fill in `kargo/values.yaml`'s `clientID` and `admins.claims.email` placeholders (same
`REPLACE_WITH_...` pattern as `argocd/values.yaml`'s RBAC line) — the Client ID isn't
secret, so it's a plain committed value, not something Vault needs to hold.

ArgoCD's own upgrade is manual (ArgoCD isn't self-managed — see "What stays manual, and
why") — re-apply the Dex connector config with:

```bash
helm upgrade argocd argo/argo-cd -n argocd -f argocd/values.yaml
```

Grafana and `sso-oauth2-proxy` pick up their secrets on their own next reconcile, no
re-apply needed.

### Verify + DNS

```bash
for env in dev staging prod; do kubectl get pods -n $env; done
kubectl argo rollouts get rollout dev-backend-rollout -n dev --watch
kubectl get stage -n book-store
```

On a cloud cluster, `kubectl get gateway istio-gateway -n mern-devops -o wide` populates an
`ADDRESS` once Istio's provisioned load balancer is up — point a wildcard `A`/`CNAME` record
at it (`CNAME` on EKS, since ALB/NLB DNS names can rotate the underlying IP; usually `A` on
AKS/GKE). On `kind`, there's no LB controller to hand out a real address, and the Gateway's
backing Service lands on random `NodePort`s — pin them to the exact ports `kind-config.yml`'s
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
127.0.0.1 prometheus.cndb.atkaridarshan.online
127.0.0.1 argorollouts.cndb.atkaridarshan.online" | sudo tee -a /etc/hosts
```

**Browser access** — all on the same wildcard cert and Gateway, no separate NodePorts:

| URL | Login |
|---|---|
| `https://app.cndb.atkaridarshan.online/` | prod app |
| `https://staging.cndb.atkaridarshan.online/` | staging app |
| `https://dev.cndb.atkaridarshan.online/` | dev app |
| `https://argocd.cndb.atkaridarshan.online/` | GitHub SSO once seeded (see below), else `admin` + `argocd-initial-admin-secret` — only exists if `admin.enabled` was `"true"` at install/upgrade time |
| `https://kargo.cndb.atkaridarshan.online/` | GitHub SSO (Kargo's own bundled Dex), or the admin password saved during bootstrap |
| `https://grafana.cndb.atkaridarshan.online/` | GitHub SSO once `monitoring/grafana-oauth` is seeded |
| `https://argorollouts.cndb.atkaridarshan.online/` | GitHub SSO (oauth2-proxy) once `argo-rollouts/oauth2-proxy` is seeded |
| `https://prometheus.cndb.atkaridarshan.online/` | no auth |

GitHub OAuth Apps are unforgiving about the callback URL — it must match protocol, host,
and path *exactly* (`https`, not `http`; `/api/dex/callback` for ArgoCD, not `/dex/callback` —
that one's Kargo's). A mismatch surfaces as GitHub's own "Invalid redirect URL" page, not an
ArgoCD/Kargo error.

```bash
curl -v https://app.cndb.atkaridarshan.online/
```

**Vault UI** — this repo runs Vault in dev mode, which means a fixed root token:

```bash
kubectl port-forward -n vault deploy/vault 8200:8200
```

Open `http://127.0.0.1:8200/ui`, method **Token**, value `root`.

**Promoting a paused canary** — each Rollout's `pause: {}` step (no duration) waits for a
human:

```bash
kubectl argo rollouts promote dev-backend-rollout -n dev
kubectl argo rollouts promote dev-frontend-rollout -n dev
# same for staging-*/prod-* once verified
```
