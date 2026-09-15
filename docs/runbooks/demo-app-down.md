# Runbook: demo-app down

## Symptoms

- Alert `DemoAppDown` or `/healthz` failing
- Pods `CrashLoopBackOff` / `ImagePullBackOff`

## Checks

```bash
kubectl -n demo-dev get pods -l app.kubernetes.io/name=demo-app
kubectl -n demo-dev describe deploy/demo-app
kubectl -n demo-dev logs deploy/demo-app
```

## Common causes

1. **Bad digest** — image missing from `localhost:5001` → re-run `make demo` or promote a known-good digest.
2. **Kyverno deny** — unsigned / `:latest` / root → fix image metadata; see `kubectl get events -n demo-dev`.
3. **Resource pressure** — kind node starved → free Docker resources.

## Mitigation

```bash
make rollback ENV=dev
```
