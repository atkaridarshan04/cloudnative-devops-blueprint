# 🔄 GitOps

> Hands-on guide: [ArgoCD.md](../ArgoCD.md)

## The problem it solves

Traditional CD (e.g. a Jenkins job running `kubectl apply` or `helm upgrade` at the end of a pipeline) works, but it has three structural issues:

- **Credentials live outside the cluster.** Your CI runner needs a kubeconfig with write access to production. That's a standing credential sitting in a system whose whole job is to run arbitrary pipeline code.
- **No single source of truth.** What's actually running in the cluster is whatever the last successful pipeline happened to apply — it can silently drift from what's in Git (someone `kubectl edit`s a Deployment directly, and now Git is lying).
- **No reconciliation.** If drift happens, nothing detects it or fixes it. You find out when something breaks.

## The GitOps model

GitOps flips the direction: instead of an external system **pushing** changes into the cluster, a controller **inside** the cluster continuously **pulls** the desired state from Git and reconciles the live state to match it.

| | Push (traditional CD) | Pull (GitOps) |
|---|---|---|
| Who initiates | CI pipeline | In-cluster controller |
| Cluster credentials | Held by CI system (external) | Held by controller (internal) |
| Source of truth | Whatever was last applied | Git, always |
| Drift handling | Undetected until it breaks something | Detected and optionally auto-corrected |
| Rollback | Re-run a pipeline / manual `kubectl` | `git revert` |

Git becomes the one place that describes what *should* be running. The controller's job is just to make reality match the repo, continuously — not just at deploy time.

## Where ArgoCD fits

ArgoCD is the pull controller. Its `Application` custom resource points at a Git path (or Helm chart / Kustomize overlay) and a target cluster/namespace, and continuously diffs live state against that source.

Two knobs matter most in practice:

- **Sync policy** — `manual` (you click "Sync" after reviewing the diff) vs `automated` (it applies changes the moment Git changes). Automated is the actual "GitOps" experience; manual is a safety net while you trust the pipeline.
- **Self-heal + prune** — if someone edits a live resource out-of-band, self-heal reverts it back to match Git on the next reconcile loop. `prune` removes resources that were deleted from Git. Together they make Git the *enforced* truth, not just the *intended* one.

This is also why GitOps composes naturally with [progressive delivery](./ProgressiveDelivery.md): ArgoCD reconciles the desired `Rollout` spec from Git, and Argo Rollouts drives the actual canary/blue-green traffic shift.
