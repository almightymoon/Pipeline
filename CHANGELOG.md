# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Fixed

- CI Trivy action pinned to `aquasecurity/trivy-action@v0.36.0` (0.24.0 was unresolvable)
- GitOps digest updates only change `kustomization.yaml` `images[].digest` — never rewrite env overlays
- `make promote` / `make rollback` fail on rollout errors and verify Cosign signatures when keys exist
- NetworkPolicies: default-deny on all demo envs; production allow rules require `from`; CI egress allowlisted
- Tekton GitHub Triggers installed by bootstrap; CEL overlays for push/PR; git-clone + real PipelineRun params
- `make security` scans the whole repo and requires Checkov (fail closed)
- Platform installs pin chart/manifest versions in `platform/versions.yaml`

### Added

- Tekton tasks: `git-clone`, `sbom-syft`, `cosign-verify`
- Integration test proving digest updates preserve `env-patch.yaml`

### Changed

- Documentation (`SECURITY.md`, README limitations) aligned with what is actually enforced

## [0.1.0] - 2025-09-15

### Added

- Initial public platform skeleton: kind demo, Tekton `secure-ci`, Kyverno baseline policies, GitOps envs, sample app
