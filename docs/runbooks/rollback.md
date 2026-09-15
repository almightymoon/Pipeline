# Runbook: rollback a release

## When

Failed smoke, rising error rate, or bad config after promote.

## Command

```bash
make rollback ENV=production   # or dev|qa|performance
```

## What it does

1. Reads `gitops/<env>/image-digest.previous.txt`
2. Rewrites current digest + `image-patch.yaml`
3. Applies the Kustomize overlay and waits for rollout

## Verify

```bash
kubectl -n demo-prod rollout status deploy/demo-app
curl -sf .../healthz
```
