#!/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
fail=0

echo "=== Shell syntax ==="
while IFS= read -r -d '' f; do
  bash -n "$f" || fail=1
done < <(find "$ROOT/scripts" -name '*.sh' -print0)

echo "=== Python (ruff) ==="
if command -v ruff >/dev/null 2>&1; then
  ruff check "$ROOT/examples/demo-app" || fail=1
else
  echo "  (ruff not installed — skip)"
fi

echo "=== Helm lint ==="
if command -v helm >/dev/null 2>&1; then
  helm lint "$ROOT/charts/demo-app" || fail=1
else
  echo "  (helm not installed — skip)"
fi

echo "=== Kubeconform ==="
if command -v kubeconform >/dev/null 2>&1; then
  kubeconform -summary -ignore-missing-schemas \
    "$ROOT/platform/namespaces" \
    "$ROOT/platform/rbac" \
    "$ROOT/platform/network-policies" \
    "$ROOT/gitops/base" \
    "$ROOT/security/policies" || fail=1
else
  echo "  (kubeconform not installed — skip)"
fi

if [[ "$fail" -ne 0 ]]; then
  echo "Lint failed"
  exit 1
fi
echo "✓ Lint passed"
