# Getting started

## Prerequisites

| Tool | Why |
|------|-----|
| Docker | kind nodes + local registry |
| kind | Local Kubernetes |
| kubectl | Cluster control |
| helm | Kyverno / monitoring installs |
| cosign | Sign & verify images |
| syft | SBOM generation |
| trivy | Vulnerability scanning |
| gitleaks | Secret scanning |
| Python 3.11+ | Demo app tests |

macOS (Homebrew):

```bash
brew install kind kubectl helm cosign syft trivy gitleaks jq ruff
```

## First run

```bash
cp .env.example .env   # optional
make bootstrap
make demo
```

Expected artifacts after a successful demo:

- `reports/sbom.spdx.json`, `reports/sbom.cdx.json`
- `reports/trivy-image.txt`, `reports/smoke-healthz.json`
- `.demo-state/image-digest`
- Updated `gitops/dev/image-digest.txt` + `image-patch.yaml`

## Profiles

```bash
make bootstrap PROFILE=minimal   # default
make bootstrap PROFILE=full      # + Argo CD, Prometheus/Grafana, Chains
```

## Cleaning up

```bash
make destroy
DESTROY_KEYS=1 make destroy   # also delete .cosign/
```
