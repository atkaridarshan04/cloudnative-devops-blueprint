# 🎯 Progressive Delivery

> Hands-on guide: [ArgoRollouts.md](../ArgoRollouts.md)

## The problem it solves

A standard Kubernetes `Deployment` does a rolling update: it replaces old pods with new ones a few at a time. That controls *how fast* the rollout happens, but not *how much real traffic* the new version sees before it's fully live, and there's no built-in way to automatically detect "this new version is failing" and stop.

Progressive delivery adds a traffic-aware, metric-aware layer on top of rollouts: ship the new version to a small slice of traffic, watch real signals, and decide — manually or automatically — whether to continue, pause, or roll back.

## Canary

Route a small percentage of traffic to the new version, watch it, then progressively increase the percentage (e.g. 10% → 25% → 50% → 100%), pausing between steps.

- **Risk exposure**: smallest — a bad version only ever sees a fraction of traffic before it's caught.
- **Cost**: no second full-size environment needed, just enough extra new-version pods to serve the current traffic slice.
- **Downside**: slower to fully roll out, and needs a way to actually split traffic by weight (a service mesh or a traffic-splitting ingress/gateway) plus real metrics to judge each step.

## Blue-Green

Run the new version ("green") fully scaled up alongside the old one ("blue"), fully idle from a traffic perspective, then cut over all traffic at once — and instantly cut back if something's wrong.

- **Risk exposure**: all-or-nothing — once you cut over, 100% of traffic hits the new version immediately.
- **Cost**: highest — you're running two full-size environments simultaneously during the transition.
- **Upside**: rollback is instant (flip the selector/route back), no traffic-splitting infrastructure required, no fractional-traffic weirdness for stateful sessions.

## Choosing between them

Canary when you can split traffic and want gradual risk reduction with real production traffic as the signal. Blue-green when you need an instant, clean rollback and can afford briefly running double the infrastructure — or when your traffic can't be meaningfully split (e.g. sticky sessions where users must land consistently on one version).

## How Argo Rollouts drives this

Argo Rollouts replaces the `Deployment` kind with a `Rollout` CR that understands canary/blue-green steps natively. The useful part isn't just the staged traffic shift — it's `AnalysisTemplate`, which queries a metrics source (Prometheus, in this repo) after each step and automatically aborts/rolls back if error rate or latency crosses a threshold, instead of relying on someone watching a dashboard.

This is why progressive delivery pairs with [GitOps](./GitOps.md): the `Rollout` spec is declared in Git like any other resource, and ArgoCD reconciles it — the rollout strategy itself becomes version-controlled and auditable.
