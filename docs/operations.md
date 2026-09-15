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

## GitHub webhook (Tekton Triggers)

Bootstrap installs Tekton Triggers and applies `tekton/triggers/github-listener.yaml` when CRDs are available.

1. Replace `secretToken` in Secret `pipeline-ci/github-webhook-secret`.
2. Point a GitHub repo webhook at the EventListener Service (`el-github-listener`, NodePort `30080` on kind).
3. Content type: `application/json`; secret must match; events: `push`, `pull_request`.
4. The CEL interceptor normalizes `git_revision` for both push (`head_commit.id`) and PR (`pull_request.head.sha`), then the TriggerTemplate starts `secure-ci` with `git-url` / `git-revision` so the pipeline **clones** before scanning.
