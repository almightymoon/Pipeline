# Contributing

Thanks for helping make this platform reproducible and secure.

## Development setup

```bash
# Prerequisites: Docker, kind, kubectl, helm, cosign, syft, trivy, gitleaks
make bootstrap PROFILE=minimal
make demo
make test
make lint
make security
```

## Profiles

| Profile | What it installs | Laptop-friendly |
|---------|------------------|-----------------|
| `minimal` | kind, local registry, Tekton, Kyverno, demo pipeline | Yes (~4–8 GB RAM) |
| `full` | + Argo CD, Prometheus, Grafana, Tekton Chains | Prefer 12+ GB RAM |

## Pull requests

1. Fork and create a feature branch.
2. Keep changes focused; prefer reusable Tekton Tasks over duplicated YAML.
3. Pin image digests / chart versions where possible.
4. Add or update negative tests under `tests/negative/` when adding a security gate.
5. Run `make lint test security` before opening a PR.
6. Update `CHANGELOG.md` under the Unreleased section.

## Code & manifest standards

- **Python**: ruff + pytest; apps run as non-root.
- **Kubernetes**: Restricted Pod Security; resource requests/limits; no privileged pods; no Docker socket mounts.
- **Tekton**: timeouts, retries for flaky network steps, `finally` cleanup, labeled PipelineRuns, pinned task images.
- **GitOps**: CI updates digests in `gitops/`; CD (Argo CD) syncs. Never deploy directly from CI in the full profile.

## Commit messages

Use concise, imperative subjects:

```
add kyverno policy to reject unsigned images
fix rollback script to target previous digest
```

## Security contributions

If your change weakens a gate (e.g. changes Trivy `exit-code` to 0), explain why in the PR and add a compensating control. Prefer failing closed.
