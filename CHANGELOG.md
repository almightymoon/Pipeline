# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Reproducible platform with `make bootstrap`, `make demo`, `make test`, `make lint`, `make security`, `make destroy`
- Minimal and full install profiles (kind-based local demo)
- Sample `examples/demo-app` with unit, smoke, and negative security fixtures
- Tekton reusable tasks: validate, build, SAST/SCA, secret scan, SBOM, sign, verify, test, GitOps update
- Supply-chain chain: Syft SBOM → Cosign sign → digest-pinned GitOps → Kyverno verify
- Environment promotion: `dev` → `qa` → `performance` → `production`
- Documented one-command rollback via GitOps
- Kyverno policies: require signature, ban `:latest`, ban root, require resource limits
- Platform RBAC (least privilege), network policies, Restricted PSS namespaces
- Observability manifests (Prometheus rules, Grafana dashboard) and operational runbooks
- Repository quality: linting, Dependabot, CI workflow, Apache-2.0 license, SECURITY.md

### Removed

- Non-reproducible dashboard helper scripts and committed credential examples
- Placeholder “enterprise” claims that were not enforceable in CI/CD

## [0.1.0] - 2025-09-15

### Added

- Initial public, article-ready platform release
