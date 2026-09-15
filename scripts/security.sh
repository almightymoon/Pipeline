#!/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
REPORTS="${REPORTS:-$ROOT/reports}"
mkdir -p "$REPORTS"
fail=0

echo "=== Gitleaks (secrets) ==="
gitleaks detect --source "$ROOT" --no-git -v --report-path "$REPORTS/gitleaks.json" \
  --config "$ROOT/security/scanning/gitleaks.toml" || fail=1

echo "=== Trivy filesystem (deps + config) ==="
trivy fs --exit-code 1 --severity HIGH,CRITICAL \
  --scanners vuln,secret,misconfig \
  --ignorefile "$ROOT/security/scanning/.trivyignore" \
  "$ROOT/examples/demo-app" | tee "$REPORTS/trivy-fs.txt" || fail=1

echo "=== Checkov (IaC) ==="
if command -v checkov >/dev/null 2>&1; then
  checkov -d "$ROOT/gitops" -d "$ROOT/charts" -d "$ROOT/platform" \
    --framework kubernetes,helm \
    --compact --quiet \
    -o json > "$REPORTS/checkov.json" || fail=1
else
  echo "  (checkov not installed — skip)"
fi

echo "=== Kyverno policy test (if kubectl ctx available) ==="
if kubectl get clusterpolicy >/dev/null 2>&1; then
  echo "  Cluster policies present: $(kubectl get clusterpolicy --no-headers 2>/dev/null | wc -l | tr -d ' ')"
else
  echo "  (no cluster / kyverno — skip live policy check)"
fi

if [[ "$fail" -ne 0 ]]; then
  echo "Security checks failed — see reports/"
  exit 1
fi
echo "✓ Security checks passed"
