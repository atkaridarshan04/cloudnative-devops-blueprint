# `ci.yml` — Pipeline Walkthrough

Line-by-line explanation of what [`ci.yml`](./ci.yml) actually does. For the *why* behind SBOM /
signing / signature enforcement, see
[`docs/concepts/SupplyChainSecurity.md`](../../docs/concepts/SupplyChainSecurity.md). For
one-time setup and how to run/verify this pipeline, see
[`docs/GitHubActions.md`](../../docs/GitHubActions.md) — that doc stays purely a guide; this file
is the technical breakdown of the workflow itself.

## Triggers

```yaml
on:
  push:
    # branches: [main]
    tags: ["v*"]
  workflow_dispatch:
```

- Push to `main` — builds and signs on every merge, same trigger as the Jenkins CI.
- Push of a `v*` git tag — for a deliberate, one-off signed build.
- `workflow_dispatch` — manual run from the Actions tab, for testing without a real push.

Regardless of which one fires, the pushed image is always tagged `signed-<short-sha>` (see the
`build` job below) — the git tag is only what *triggers* the run, not the image tag it produces.

## Permissions

```yaml
permissions:
  contents: read
  packages: write # push to GHCR
  id-token: write # OIDC token for cosign keyless signing
  security-events: write # upload Trivy SARIF to the Security tab
```

`packages: write` lets `GITHUB_TOKEN` push to GHCR. `id-token: write` is what lets the job request
a short-lived OIDC token from GitHub — that token is what Fulcio exchanges for a signing
certificate. `security-events: write` lets the `upload-sarif` step publish Trivy's findings to the
repo's Security tab. No stored secrets or keys anywhere in this file.

## Job: `build`

1. `actions/checkout@v4` — standard checkout.
2. `docker/setup-qemu-action@v3` + `docker/setup-buildx-action@v3` — needed for the multi-arch
   (`linux/amd64` + `linux/arm64`) build that `docker-bake.hcl` already declares.
3. `docker/login-action@v3` — logs into `ghcr.io` using `github.actor` / `GITHUB_TOKEN` (the
   built-in token, not a personal access token).
4. **Set image tag** — computes `signed-<short-sha>` (e.g. `signed-a3f9c2e`) from `GITHUB_SHA`.
   This is a separate tag created specifically for this signing/SBOM/Kyverno demo — deliberately
   outside the `1.0.0`/`2.0.0`/`3.0.0` versions already used across the rest of this repo's other
   implementations (Kustomize overlays, Kargo promotion, and elsewhere). The short SHA suffix also
   means every run leaves a distinct, traceable artifact instead of overwriting the same tag on
   each push. The same signing/SBOM approach demoed here can later be pointed at those existing
   tags too.
5. `docker/bake-action@v5` with `push: true` and a `set:` override — runs `docker-bake.hcl`'s
   `default` group (`frontend` + `backend`) unmodified, just overriding the `tags` field for both
   targets at invocation time to the computed `signed-<sha>` tag. `docker-bake.hcl` itself is
   never edited — `--set` is a normal buildx bake capability for exactly this.
6. **Extract pushed image digests** — `docker/bake-action` returns a JSON metadata blob
   (`steps.bake.outputs.metadata`) with one entry per target, each containing
   `containerimage.digest`. `jq` pulls out `frontend`/`backend` and republishes them as job
   outputs (`frontend_digest`, `backend_digest`) so the next job can act on the exact digest that
   was pushed — not the mutable tag.

## Job: `scan-sbom-sign`

Runs as a 2-way matrix (`frontend`, `backend`) instead of duplicating every step twice:

```yaml
strategy:
  matrix:
    include:
      - key: frontend
        image: bookstore-frontend
      - key: backend
        image: bookstore-backend
env:
  DIGEST: ${{ matrix.key == 'frontend' && needs.build.outputs.frontend_digest || needs.build.outputs.backend_digest }}
  REF: ghcr.io/atkaridarshan04/cloudnative-devops-blueprint/${{ matrix.image }}
```

Per matrix entry, in order:

1. `docker/login-action@v3` — logs into `ghcr.io` again, same as the `build` job. This job runs on
   its **own runner**, so it doesn't inherit the `build` job's Docker credentials — without this,
   `cosign sign`/`cosign attest` reach Sigstore fine (the Rekor log entry gets created) but then
   fail pushing the signature *back* to GHCR with `UNAUTHORIZED: unauthenticated`.
2. **Trivy image scan** (`aquasecurity/trivy-action`) — same tool as the Jenkinsfile, scanning
   `$REF@$DIGEST`. Output is `format: sarif` (instead of the human-readable `table`) so the results
   can be uploaded, not just printed to the job log. `exit-code: "0"` keeps it non-blocking for
   this pass, matching the current Jenkins pipeline's stance; making it fail the build is a later
   decision, not in scope for #14.
3. **Upload Trivy scan to Security tab** (`github/codeql-action/upload-sarif`) — publishes
   `trivy-results.sarif` to the repo's Security → Code scanning alerts, giving each finding a
   persistent record and a diff view across runs instead of a log line that scrolls away once the
   job finishes. `category: trivy-${{ matrix.key }}` keeps the frontend and backend results as
   separate alert sets — without it, the second matrix leg's upload would overwrite the first's.
4. **Syft SBOM** (`anchore/sbom-action`) — generates `spdx-json`, written to
   `<image>-sbom.spdx.json`, keyed to the same digest.
5. `sigstore/cosign-installer@v3` — installs the `cosign` CLI onto the runner.
6. **Sign image (keyless)** — `cosign sign --yes "$REF@$DIGEST"`. No `--key` flag: cosign detects
   it's running in GitHub Actions with `id-token: write` and does the OIDC → Fulcio → ephemeral
   cert → Rekor log flow automatically, then pushes the signature using the Docker credentials
   from step 1.
7. **Attach SBOM attestation** — `cosign attest --yes --predicate <image>-sbom.spdx.json --type
   spdxjson "$REF@$DIGEST"` — signs and attaches the SBOM itself the same way, so the SBOM inherits
   the same tamper-evident guarantee as the image.

## Design notes

- Matrix over copy-pasted steps: same steps run twice, once per image, without duplicating the
  YAML.
- Trivy results are persisted, not just logged: SARIF output + `upload-sarif` gives every scan a
  permanent, queryable record in the Security tab (with history across runs) instead of console
  output that scrolls away once the job finishes.
- Everything after `build` addresses images strictly by digest (`$REF@$DIGEST`), never by tag —
  tags can move, digests can't.
- `docker-bake.hcl` is untouched on disk; this workflow overrides the GHCR tag at invocation time
  (`signed-<sha>`) — its own tag for this signing/SBOM/Kyverno demo, kept separate from the
  `1.0.0`/`2.0.0`/`3.0.0` tags already used across the rest of this repo. Pointing the same
  approach at those existing tags is a natural follow-on once this is proven out.
