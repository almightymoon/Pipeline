# License compliance

This project is Apache-2.0.

Third-party tools invoked by the platform (Tekton, Kyverno, Cosign, Syft, Trivy,
Gitleaks, Checkov, OWASP ZAP, etc.) retain their own licenses. Pin versions in
`scripts/install-platform.sh` and Task image tags before production use.

Policy: fail the release if Copyleft contamination is introduced into
`examples/demo-app` runtime dependencies without an explicit exception in
`SECURITY.md`.
