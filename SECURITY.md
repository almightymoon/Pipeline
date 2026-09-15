# Security Policy

## Supported versions

| Version | Supported |
|---------|-----------|
| `main`  | Yes       |
| tagged releases | Yes (latest minor) |

## Reporting a vulnerability

Please **do not** open a public GitHub issue for security vulnerabilities.

1. Use GitHub Security Advisories for this repository (preferred), or contact the maintainers privately.
2. Include a clear description, steps to reproduce, and impact assessment.
3. Allow reasonable time for a fix before public disclosure.

We aim to acknowledge reports within **72 hours**.

## What this project actually enforces today

| Gate | Where it runs | Failure mode |
|------|---------------|--------------|
| Leaked secrets | `make security`, Tekton `gitleaks`, GitHub Actions | Exit non-zero |
| Vulnerable deps / misconfig | Trivy FS (repo) in CI + `make security` | HIGH/CRITICAL fail |
| Vulnerable container image | Host-side Trivy in `make demo` | HIGH/CRITICAL fail |
| SBOM generation | Host-side Syft in `make demo`; Tekton `sbom-syft` when `image` param set | Missing SBOM fails the task |
| Image signing | Host-side Cosign in `make demo` | Sign/verify required for demo success |
| Signature admission (Kyverno) | **Not Enforce on kind/minimal** (`localhost:5001` unreachable from pods). Host `cosign verify` + `make promote` verify instead. Set `COSIGN_ENFORCE=1` with a reachable registry for in-cluster Enforce. | — |
| `:latest` / non-digest / root / missing resources | Kyverno ClusterPolicies (Enforce) | Admission denied |
| Invalid Helm | `helm lint` / `helm template` + negative fixtures | Exit non-zero |
| IaC (selected CIS) | Checkov in Tekton + **required** for `make security` | Exit non-zero |
| DAST (OWASP ZAP) | Optional via `scripts/dast-zap.sh`; **not** a default promotion gate | Manual / `DAST_REQUIRED=1` |
| Provenance (Tekton Chains) | Installed in `PROFILE=full` only | Optional |

## Secrets handling

- Never commit real credentials, kubeconfigs, or Cosign private keys.
- Bootstrap generates Cosign keys under `.cosign/` (gitignored).
- `tests/negative/leaked-secret/` holds **fake** fixtures for gate testing only.
- Replace `pipeline-ci/github-webhook-secret` before exposing the EventListener.

## Supply-chain flow (demo / intended)

```
Build → Trivy image → Syft SBOM → Cosign sign (+ attest) → publish digest
      → cosign verify → GitOps digest-only update → Kyverno (digest/non-root/…) → Deploy
```

Images in GitOps must use **digest** pins via `kustomization.yaml` `images:`; `env-patch.yaml` must never carry `image:`.

## Disclosure timeline

| Day | Action |
|-----|--------|
| 0 | Report received |
| 1–3 | Triage & confirm |
| ≤14 | Patch / mitigation on `main` |
| ≤30 | Advisory / coordinated disclosure |
