# Dependency Updates: Dependabot + Scoped Renovate

This repository uses two complementary dependency update tools, split by ecosystem to avoid duplicate PRs and maximize coverage across all managed artifacts.

## Why Two Tools?

- **Dependabot** is natively supported by GitHub and excels at updating npm packages, Docker base images, GitHub Actions versions, and Terraform providers.
- **Renovate** has superior support for GitOps-specific ecosystems like Helm values, Kustomize overlays, and ArgoCD Application `targetRevision`s — which Dependabot does not track.

Running both tools unscoped would cause duplicate PRs for the same dependency bumps (e.g., both would update `react` or `node:alpine`). To prevent this, responsibility is strictly partitioned by ecosystem.

## Ecosystem Ownership

| Ecosystem | Tool | Scope / Location |
|-----------|------|------------------|
| `npm` (frontend & backend) | Dependabot | `src/frontend/package.json`, `src/backend/package.json` |
| `docker` (base images) | Dependabot | Root `Dockerfile`s |
| `github-actions` | Dependabot | `.github/workflows/` |
| `terraform` (providers/modules) | Dependabot | `terraform/` |
| `helm-values` | Renovate | Helm chart `values.yaml` & subcharts |
| `kustomize` (image tags) | Renovate | `kustomize/overlays/{dev,staging,prod}` |
| `argocd` (targetRevision) | Renovate | `argocd/application-*.yml` |

## How It Works

- **Dependabot** is configured in `.github/dependabot.yml`. It opens PRs for npm, Docker, GitHub Actions, and Terraform updates on a weekly schedule.
- **Renovate** is installed via the Renovate GitHub App and configured in the root `renovate.json`. Its `enabledManagers` list is restricted to `helm-values`, `kustomize`, and `argocd`. All other managers (including `npm`, `dockerfile`, and `github-actions`) are explicitly disabled to ensure zero overlap.

## Review Process

All dependency updates are delivered as standard pull requests for manual review. There is no auto-merge or environment gating. This overlay-based approach ensures that version bumps are safely reviewed and merged like any other infrastructure or application change.
