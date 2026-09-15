# Runbook: pipeline failure

## Symptoms

- `PipelineRun` condition Succeeded=False
- GitHub CI red on `security` / `lint-test`

## Checks

```bash
kubectl -n pipeline-ci get pipelinerun
kubectl -n pipeline-ci describe pipelinerun <name>
# Task logs:
kubectl -n pipeline-ci logs -l tekton.dev/pipelineRun=<name> --all-containers --tail=200
```

## Gate-specific

| Task | Likely cause |
|------|----------------|
| gitleaks | Secret pattern in source |
| sca | HIGH/CRITICAL dependency |
| unit-test | Failing pytest |
| manifests | Helm/kubeconform error |
| iac-scan | Checkov CKV failure |

## Mitigation

Fix forward for security findings. Do not set Trivy `exit-code` to 0 to “go green.”
