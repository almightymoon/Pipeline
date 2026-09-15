# Evidence pack (what “working” looks like)

This page is the article-facing proof checklist. Prefer live CI badges on the README over stale screenshots.

## Automated (CI)

| Check | Where |
|-------|--------|
| Lint, unit tests, digest-update safety, Gitleaks | Job **Lint & Unit Tests** |
| Trivy vuln/secret (repo), Trivy config (base + rendered overlays), negative fixtures | Job **Security Gates** |
| Workflow | [`.github/workflows/ci.yml`](../.github/workflows/ci.yml) |

Green `main` CI: https://github.com/almightymoon/Pipeline/actions/workflows/ci.yml

## Local demo (after `make demo`)

```bash
# Signed digest on disk
cat .demo-state/image-digest

# Cosign verify (host-side gate for kind)
cosign verify --key .cosign/cosign.pub --insecure-ignore-tlog=true --allow-insecure-registry \
  "$(cat .demo-state/image-digest)"

# App healthy
kubectl -n demo-dev get deploy,pods
kubectl -n demo-dev port-forward svc/demo-app 18080:8080 &
curl -sf localhost:18080/healthz
```

## Blocked paths (`make negative-tests`)

Expected: each fixture exits non-zero / admission deny.

| Fixture | Gate |
|---------|------|
| `tests/negative/leaked-secret` | Gitleaks |
| `tests/negative/vulnerable-deps` | Trivy |
| `tests/negative/latest-tag` | Kyverno `disallow-latest-tag` / `require-image-digest` |
| `tests/negative/root-container` | Kyverno `require-non-root` (+ PSS) |
| `tests/negative/bad-helm` | `helm template` fail |
| `tests/negative/unsigned-image` | Cosign verify fail / policy |

## Promotion safety

```bash
# env-patch must be unchanged
bash tests/integration/test_gitops_digest.sh
```

Digest updates only touch `gitops/<env>/kustomization.yaml` → `images[].digest`.

## Screenshots

Drop PNGs into `docs/screenshots/` when recording a demo:

- `demo-success.png` — terminal banner from `make demo`
- `pipelinerun-succeeded.png` — `kubectl get pipelinerun`
- `kyverno-deny-latest.png` — admission error for `:latest`
- `ci-green.png` — GitHub Actions green check on `main`

See also [screenshots/README.md](screenshots/README.md).
