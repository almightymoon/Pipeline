# Secure Supply-Chain CI/CD Platform

[![CI](https://github.com/almightymoon/Pipeline/actions/workflows/ci.yml/badge.svg)](https://github.com/almightymoon/Pipeline/actions/workflows/ci.yml)
[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](LICENSE)
[![Release](https://img.shields.io/github/v/release/almightymoon/Pipeline?include_prereleases)](https://github.com/almightymoon/Pipeline/releases)

A **reproducible, enforceable** DevSecOps platform: Tekton for CI security gates, GitOps for deployment, Cosign/Kyverno for artifact trust, and a one-command local demo.

This repository is designed so another engineer can **clone → `make demo` → watch a safe release succeed**, then **`make negative-tests` → watch bad releases fail**.

```text
Commit → Tekton CI (validate, SAST/SCA, secrets, tests)
      → Build → Scan → SBOM (Syft) → Sign (Cosign) → Publish (digest)
      → Verify signature → GitOps digest update → Deploy (dev→qa→perf→prod)
      → Metrics / logs visible
```

## Quick start (minimal profile)

**Prerequisites:** Docker, [kind](https://kind.sigs.k8s.io/), kubectl, helm, cosign, syft, trivy, gitleaks  
(~4–8 GB RAM free)

```bash
git clone https://github.com/almightymoon/Pipeline.git
cd Pipeline

make bootstrap          # kind cluster + Tekton + Kyverno + local registry
make demo               # build → scan → SBOM → sign → pipeline → deploy → smoke
make negative-tests     # prove gates block bad changes
make destroy            # tear down
```

Other targets:

| Target | Purpose |
|--------|---------|
| `make test` | Unit, integration, smoke |
| `make lint` | Python, shell, Helm, kubeconform |
| `make security` | Gitleaks, Trivy, Checkov |
| `make promote ENV=qa` | Promote the **same digest** to the next env |
| `make rollback ENV=dev` | Restore previous GitOps digest |

Full (enterprise-style) profile — Argo CD, Prometheus/Grafana, Tekton Chains:

```bash
make bootstrap PROFILE=full
make demo PROFILE=full
```

## What “done” looks like

| Priority | Capability | Proof in this repo |
|----------|------------|--------------------|
| P0 | One-command demo | `make demo` |
| P0 | Complete docs | `README` + `docs/` |
| P0 | Real security gates | Failures on secrets, vulns, bad Helm, unsigned images |
| P0 | Artifact trust | Syft SBOM + Cosign sign/attest + digest pins |
| P0 | Promotion | `gitops/{dev,qa,performance,production}` + `make promote` |
| P0 | Rollback | `make rollback ENV=…` |
| P1 | Automated tests | pytest, smoke, integration, negative, CI workflow |
| P1 | K8s hardening | Restricted PSS, NetworkPolicies, least-privilege SAs, no cluster-admin |
| P1 | Observability | Grafana dashboard CM, Prometheus rules, runbooks |
| P1 | Repo quality | Pinning, lint, reusable Tekton Tasks, Dependabot, CHANGELOG |

## Architecture

```text
┌─────────────────────────────────────────────────────────────┐
│  CI (Tekton)                                                │
│  gitleaks → trivy SCA → unit tests → helm/kubeconform → IaC │
└─────────────────────────────┬───────────────────────────────┘
                              │ produces image @sha256
                              ▼
┌─────────────────────────────────────────────────────────────┐
│  Supply chain                                               │
│  Syft SBOM → Cosign signature + attestation → registry      │
└─────────────────────────────┬───────────────────────────────┘
                              │ updates digest in Git
                              ▼
┌─────────────────────────────────────────────────────────────┐
│  CD (GitOps)                                                │
│  gitops/dev → qa → performance → production                 │
│  Kyverno: digest required, no :latest, non-root, signed     │
└─────────────────────────────────────────────────────────────┘
```

CI **never** deploys directly in the intended design. It updates an immutable digest under `gitops/`; the cluster applies that desired state (`kubectl apply -k` locally, Argo CD in `PROFILE=full`).

See [docs/architecture.md](docs/architecture.md) and [docs/threat-model.md](docs/threat-model.md).

## Repository layout

```text
.
├── Makefile
├── examples/demo-app/          # Sample app under test
├── tekton/tasks|pipelines|triggers/
├── platform/                   # Namespaces, RBAC, netpol, observability
├── security/policies|scanning|sbom/
├── gitops/{dev,qa,performance,production}/
├── charts/demo-app/
├── tests/{unit path via demo-app,integration,smoke,negative}/
├── scripts/                    # bootstrap, demo, promote, rollback…
└── docs/                       # architecture, ops, runbooks, ADRs
```

## Pipeline flow (demo)

1. **Bootstrap** — kind cluster, `localhost:5001` registry, Tekton, Kyverno, Cosign keypair (`.cosign/`, gitignored).
2. **Build & publish** — Docker build of `examples/demo-app`, push to local registry.
3. **Scan** — Trivy image gate (HIGH/CRITICAL).
4. **SBOM** — Syft SPDX + CycloneDX under `reports/`.
5. **Sign** — Cosign key-based signature + SBOM attestation (`--tlog-upload=false` for air-gapped/local).
6. **Tekton `secure-ci`** — secrets, SCA, unit tests, Helm/kubeconform, Checkov.
7. **GitOps** — write digest into `gitops/dev`, apply Deployment (digest-pinned).
8. **Verify** — `/healthz` and `/metrics` smoke checks.

## Security gates

| Gate | Tool | Blocks when |
|------|------|-------------|
| Secrets in source | Gitleaks | Credential patterns detected |
| Vulnerable deps / image | Trivy | HIGH/CRITICAL |
| IaC / K8s misconfig | Checkov, kubeconform | Policy failures |
| Bad Helm | `helm lint` / `helm template` | Invalid / `:latest` without digest |
| Unsigned image | Cosign + Kyverno | Admission denied |
| Floating tags | Kyverno | `:latest` or non-digest refs |
| Root containers | Kyverno + PSS Restricted | `runAsUser: 0` / missing non-root |

Negative fixtures live in `tests/negative/`. Run `make negative-tests`.

## Promotion & rollback

Same digest, four environments:

```bash
make demo                    # lands in dev
make promote ENV=qa
make promote ENV=performance
make promote ENV=production

# Something wrong in prod?
make rollback ENV=production
```

Rollback restores `gitops/<env>/image-digest.previous.txt` and re-applies the overlay. Every deploy is a Git-visible digest change.

## Secrets & credentials

- **Do not** commit kubeconfigs, registry passwords, or Cosign private keys.
- Bootstrap writes keys to `.cosign/` (gitignored).
- See [SECURITY.md](SECURITY.md) and [docs/getting-started.md](docs/getting-started.md).

## Profiles

| | `minimal` | `full` |
|--|-----------|--------|
| kind + local registry | ✓ | ✓ |
| Tekton + Kyverno | ✓ | ✓ |
| Cosign / Syft / Trivy / Gitleaks | ✓ | ✓ |
| Argo CD | | ✓ |
| Prometheus + Grafana | | ✓ |
| Tekton Chains | | ✓ |
| DAST (ZAP) policy hook | documented | intended for QA+ |

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| `Missing required tools` | `brew install kind kubectl helm cosign syft trivy gitleaks` |
| Docker not running | Start Docker Desktop / Colima / OrbStack |
| Image pull errors on kind | Ensure `make bootstrap` connected the registry to the `kind` network |
| Kyverno denies pod | Confirm image is signed with `.cosign/cosign.key` and referenced by digest |
| PipelineRun pending | `kubectl -n pipeline-ci get pods`; check Tekton controller logs |
| Port-forward smoke fails | `kubectl -n demo-dev get pods,svc`; `kubectl -n demo-dev describe deploy/demo-app` |

More: [docs/operations.md](docs/operations.md), [docs/runbooks/](docs/runbooks/), [docs/evidence.md](docs/evidence.md).

## Limitations (honest)

- Local Cosign uses **key-based** signing with Rekor upload disabled; production should use keyless/Fulcio + transparency log where possible.
- Minimal profile applies GitOps with `kubectl apply -k` rather than a long-running Argo CD controller (`PROFILE=full` installs Argo CD).
- On kind, Kyverno cannot dial the host registry at `localhost:5001` (pod loopback). Signature admission is **not** Enforce in minimal; host `cosign verify` (demo + promote) is the gate. Use `COSIGN_ENFORCE=1` with a cluster-reachable registry for in-cluster Enforce.
- SBOM + Cosign **sign** run host-side in `make demo`. Tekton includes `sbom-syft` / `cosign-verify` tasks when params are set; signing inside Tekton still expects registry credentials.
- DAST (`scripts/dast-zap.sh`) is optional and not part of the default promote path unless `DAST_REQUIRED=1`.
- GitHub EventListener is installed by bootstrap when Triggers CRDs are present; you must set a real `github-webhook-secret` and point GitHub at the listener Service before it is useful.
- kind + PVC/hostPath workspaces are for **demo fidelity**, not multi-tenant production isolation.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). Please add a negative test when you add a gate.

## License

Apache License 2.0 — see [LICENSE](LICENSE).
