# Operations

## Day-2 commands

```bash
# Status
kubectl -n pipeline-ci get pipelinerun
kubectl -n demo-dev get deploy,pods,svc
kubectl get clusterpolicy

# Logs
kubectl -n pipeline-ci logs -l tekton.dev/pipelineRun=<name> --all-containers

# Promote / rollback
make promote ENV=qa
make rollback ENV=qa
```

## Health

- App: `GET /healthz`, `GET /readyz`
- Metrics: `GET /metrics` (`demo_app_up`, `demo_app_uptime_seconds`)

## Backups

- Git is the backup for desired state (`gitops/**/image-digest*.txt`).
- Protect `.cosign/cosign.key` offline; losing it means re-signing images with a new trust root and rotating Kyverno keys.

## Upgrades

Pin Tekton/Kyverno versions in `scripts/install-platform.sh` (`TEKTON_VERSION`, helm chart versions). Bump intentionally and re-run `make demo`.
