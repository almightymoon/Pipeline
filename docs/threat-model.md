# Threat model (lightweight)

## Assets

- Source code and CI credentials
- Container images and SBOMs
- Cluster workloads (demo-app) and kube-API
- Signing keys (`.cosign/`)

## Adversaries

| Actor | Goal |
|-------|------|
| Malicious PR author | Merge vulnerable code, leak secrets, run as root |
| Compromised dependency | RCE via supply chain |
| Registry tampering | Swap image contents under a tag |
| Insider with cluster access | Deploy unsigned / latest images |

## Controls

| Threat | Control |
|--------|---------|
| Secret committed | Gitleaks gate + CI |
| Vulnerable library | Trivy FS/image fail on HIGH/CRITICAL |
| Tag mutability | Digest-only GitOps + Kyverno |
| Unsigned artifact | Cosign sign + Kyverno verifyImages |
| Privilege escalation in pod | PSS Restricted, non-root, drop ALL caps, read-only root FS |
| Lateral movement | NetworkPolicies, dedicated SAs, no cluster-admin for tasks |
| Silent prod change | GitOps promotion trail + rollback file |

## Out of scope (v0.1)

- Multi-tenant hard isolation on kind
- Hardware-backed key storage (use KMS/HSM in production)
- Full runtime threat detection (Falco, etc.)
