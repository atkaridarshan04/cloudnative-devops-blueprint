# Progressive Delivery via Argo Rollouts

Canary deployments for the app, using Argo Rollouts' Gateway API traffic-routing plugin to
shift traffic between `stable` and `canary` Services through the same `HTTPRoute`/Gateway
already set up for TLS. Dashboard exposed at `argorollouts.cndb.atkaridarshan.online`,
reusing the same wildcard cert. Do Phases 0–4 in [`tls-setup-guide.md`](./tls-setup-guide.md)
first (Gateway + `wildcard-tls` Secret need to already exist), and deploy the app via
[`argocd-deploy.md`](./argocd-deploy.md) — that's now the only supported path (see below).

## What changed in the Helm chart

`backend.yaml`/`frontend.yaml` now define an Argo Rollouts `Rollout` instead of a plain
`Deployment`, plus two Services per component (`-stable` and `-canary`, both selecting the
same Pods by label — Argo Rollouts repoints which Pods each Service's endpoints include
during a rollout). The `Rollout`'s `strategy.canary.trafficRouting.plugins.argoproj-labs/gatewayAPI`
points at the shared `HTTPRoute` (`helm-chart/templates/httproute.yaml`) — the plugin
mutates that HTTPRoute's `backendRefs[].weight` values as the canary progresses, instead of
you managing weights by hand.

Canary steps (same shape for both `Rollout`s):

```yaml
steps:
  - setWeight: 20
  - pause: {}              # indefinite — needs a manual promote
  - setWeight: 60
  - pause: { duration: 10s }
  - setWeight: 100
  - pause: { duration: 10s }
```

The first `pause: {}` has no duration — the rollout stops there until you promote it
manually (step 5 below). The rest advance automatically after their `duration`.

## Prerequisites

**1. Install the Argo Rollouts controller, with the dashboard enabled:**

```bash
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update
helm install argo-rollouts argo/argo-rollouts \
  -n argo-rollouts --create-namespace \
  --set dashboard.enabled=true
```

This creates the `argo-rollouts-dashboard` Service (port `3100`) that
`argorollouts/httproute.yml` routes to.

**2. Configure the Gateway API traffic-routing plugin** — not bundled by default, the
controller needs to be told where to fetch it:

```bash
kubectl apply -n argo-rollouts -f - <<'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: argo-rollouts-config
data:
  trafficRouterPlugins: |-
    - name: "argoproj-labs/gatewayAPI"
      location: "https://github.com/argoproj-labs/rollouts-plugin-trafficrouter-gatewayapi/releases/latest/download/gatewayapi-plugin-linux-amd64"
EOF

kubectl rollout restart deployment argo-rollouts -n argo-rollouts
```

Pin `location` to a specific released version rather than `latest` once you've confirmed
this works, so upgrades don't happen silently underneath you.

**3. Install the `kubectl argo rollouts` CLI plugin** (for promoting/watching from your
terminal — the dashboard also has promote/abort buttons if you'd rather not install it):

```bash
brew install argoproj/tap/kubectl-argo-rollouts
```

## Deploy

The `Rollout` and its two Services deploy the same way as everything else now — through
ArgoCD, per `argocd-deploy.md`. `argocd/project.yml`'s `namespaceResourceWhitelist` already
includes `argoproj.io/Rollout`.

**Route the dashboard:**

```bash
kubectl apply -f argorollouts/httproute.yml
```

## Verify

```bash
kubectl argo rollouts get rollout mern-backend-rollout -n mern-devops --watch
```

Watch it progress to the first `pause: {}` and stop. Promote it:

```bash
kubectl argo rollouts promote mern-backend-rollout -n mern-devops
```

**Dashboard**, same local-testing pattern as the app and ArgoCD:

```bash
echo "127.0.0.1 argorollouts.cndb.atkaridarshan.online" | sudo tee -a /etc/hosts
```

Open `https://argorollouts.cndb.atkaridarshan.online/` — same clean padlock, same wildcard
cert, same Gateway.

## Triggering a canary rollout

Since deployment now goes through ArgoCD (not `helm upgrade`), a new rollout starts by
committing an image tag change (`values.yaml`'s `backend.image.tag` /
`frontend.image.tag`) to git and pushing to the branch `argocd/application.yml`'s
`targetRevision` points at. ArgoCD syncs the change, the `Rollout` picks it up, and the
canary steps above run automatically until the first indefinite pause.
