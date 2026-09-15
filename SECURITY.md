# Security Policy

## Supported versions

| Version | Supported |
|---------|-----------|
| `main`  | Yes       |
| tagged releases | Yes (latest minor) |

## Reporting a vulnerability

Please **do not** open a public GitHub issue for security vulnerabilities.

1. Email the maintainers (or use GitHub Security Advisories for this repository).
2. Include a clear description, steps to reproduce, and impact assessment.
3. Allow reasonable time for a fix before public disclosure.

We aim to acknowledge reports within **72 hours**.

## Security model (what this project enforces)

This platform is designed so that the following conditions **fail the pipeline or admission**:

| Gate | Tool | Failure mode |
|------|------|--------------|
| Leaked secrets in source | Gitleaks | Pipeline fails |
| Vulnerable dependencies | pip-audit / Trivy fs | Pipeline fails on HIGH/CRITICAL |
| Vulnerable container image | Trivy image | Pipeline fails on HIGH/CRITICAL |
| Missing / invalid SBOM | Syft | Pipeline fails |
| Unsigned image | Cosign + Kyverno | Admission denied |
| `:latest` or unpinned tag | Kyverno | Admission denied |
| Root containers | Kyverno / PSS Restricted | Admission denied |
| Invalid Helm / K8s manifests | helm lint, kubeconform | Pipeline fails |
| IaC misconfigurations | Checkov | Pipeline fails on CRITICAL |
| Unsigned provenance | Cosign verify-attestation | Deploy blocked |

## Secrets handling

- Never commit real credentials, kubeconfigs, or signing private keys.
- Bootstrap generates Cosign keys under `.cosign/` (gitignored).
- Use Kubernetes Secrets / sealed-secrets / external secret managers in real environments.
- Example placeholders live in `docs/` and `.env.example` only.

## Supply-chain trust chain

```
Build → Scan → SBOM (Syft) → Sign (Cosign) → Publish (digest)
      → Verify signature + attestation → GitOps digest update → Deploy
```

Images must be referenced by **digest** (`@sha256:…`), never by floating tags in GitOps environments.

## Disclosure timeline

| Day | Action |
|-----|--------|
| 0 | Report received |
| 1–3 | Triage & confirm |
| ≤14 | Patch / mitigation on `main` |
| ≤30 | Advisory / coordinated disclosure |
