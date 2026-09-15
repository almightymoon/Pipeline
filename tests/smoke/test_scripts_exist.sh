#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

required=(
  scripts/bootstrap.sh
  scripts/demo.sh
  scripts/test.sh
  scripts/lint.sh
  scripts/security.sh
  scripts/destroy.sh
  scripts/promote.sh
  scripts/rollback.sh
  Makefile
  examples/demo-app/src/app.py
  tekton/pipelines/secure-ci.yaml
  security/policies/kyverno-policies.yaml
  gitops/base/deployment.yaml
)

missing=0
for f in "${required[@]}"; do
  if [[ ! -e "$ROOT/$f" ]]; then
    echo "missing: $f"
    missing=1
  fi
done
[[ "$missing" -eq 0 ]]
echo "✓ smoke: required scripts and manifests exist"
