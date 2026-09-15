# Architecture

## Goals

1. **Reproducible** — `make demo` on a laptop with kind.
2. **Enforceable** — gates fail closed with fixtures that prove it.
3. **Separable CI/CD** — Tekton builds/scans; GitOps deploys.
4. **Trustworthy artifacts** — SBOM + signature + digest + admission verify.

## Component map

| Layer | Components |
|-------|------------|
| Source | GitHub repo, Dependabot |
| CI | Tekton Pipelines (`secure-ci`), reusable Tasks |
| Supply chain | Syft, Trivy, Cosign, (Chains in full) |
| Policy | Kyverno ClusterPolicies, PSS Restricted |
| CD | Kustomize overlays under `gitops/`; Argo CD (full) |
| Runtime | Hardened `demo-app` Deployment + NetworkPolicies |
| Observe | `/metrics`, Grafana dashboard ConfigMap, PrometheusRules |

## Trust flow

```text
developer commit
    → gitleaks / SCA / unit / IaC (Tekton)
    → container build
    → trivy image
    → syft SBOM
    → cosign sign + attest
    → registry (tag + digest)
    → cosign verify
    → gitops/<env> digest pin
    → kyverno (digest, non-root, signature)
    → kubelet pulls digest
```

## Why CI does not kubectl-apply production

Direct CI deploys hide the desired state and make rollback a cluster imperative.
GitOps keeps every environment change as a digest file + patch in Git, which is auditable and one-command reversible (`make rollback`).

## ADR index

- [ADR-001: Tekton for CI, GitOps for CD](adr/001-tekton-ci-gitops-cd.md)
- [ADR-002: Cosign key-based local signing](adr/002-cosign-local-keys.md)
