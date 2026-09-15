#!/usr/bin/env bash
# Fail-closed local security gates across the repository.
set -euo pipefail

ROOT="${ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
REPORTS="${REPORTS:-$ROOT/reports}"
mkdir -p "$REPORTS"
fail=0

require() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required tool for make security: $1"
    fail=1
    return 1
  fi
}

require gitleaks || true
require trivy || true

echo "=== Gitleaks (secrets, whole repo) ==="
if command -v gitleaks >/dev/null 2>&1; then
  gitleaks detect --source "$ROOT" --no-git -v --report-path "$REPORTS/gitleaks.json" \
    --config "$ROOT/security/scanning/gitleaks.toml" || fail=1
fi

echo "=== Trivy filesystem (vuln + secret, whole repo) ==="
if command -v trivy >/dev/null 2>&1; then
  trivy fs --exit-code 1 --severity HIGH,CRITICAL \
    --scanners vuln,secret \
    --skip-dirs "$ROOT/tests/negative,$ROOT/.git,$ROOT/.venv,$ROOT/reports,$ROOT/.demo-state,$ROOT/.cosign" \
    --ignorefile "$ROOT/security/scanning/.trivyignore" \
    "$ROOT" | tee "$REPORTS/trivy-fs.txt" || fail=1

  echo "=== Trivy config (base/platform/charts + rendered overlays) ==="
  trivy config --exit-code 1 --severity HIGH,CRITICAL \
    --skip-dirs "$ROOT/tests/negative,$ROOT/.git,$ROOT/.venv,$ROOT/gitops/dev,$ROOT/gitops/qa,$ROOT/gitops/performance,$ROOT/gitops/production,$ROOT/tekton" \
    "$ROOT" | tee "$REPORTS/trivy-config.txt" || fail=1

  if command -v kubectl >/dev/null 2>&1; then
    mkdir -p "$REPORTS/rendered"
    for env in dev qa performance production; do
      kubectl kustomize "$ROOT/gitops/${env}" > "$REPORTS/rendered/${env}.yaml"
    done
    trivy config --exit-code 1 --severity HIGH,CRITICAL "$REPORTS/rendered" | tee "$REPORTS/trivy-rendered.txt" || fail=1
  else
    echo "kubectl missing — skip rendered overlay misconfig scan"
  fi
fi

echo "=== Checkov (IaC) — required ==="
if ! command -v checkov >/dev/null 2>&1; then
  echo "checkov is required for make security (pip install checkov / brew install checkov)"
  fail=1
else
  checkov -d "$ROOT/gitops" -d "$ROOT/charts" -d "$ROOT/platform" -d "$ROOT/tekton" \
    --framework kubernetes,helm \
    --compact --quiet \
    -o json > "$REPORTS/checkov.json" || fail=1
fi

echo "=== Helm / kubeconform ==="
if command -v helm >/dev/null 2>&1; then
  helm lint "$ROOT/charts/demo-app" || fail=1
else
  echo "helm missing — fail closed"
  fail=1
fi

echo "=== Kyverno policy presence (optional live cluster) ==="
if kubectl get clusterpolicy >/dev/null 2>&1; then
  count="$(kubectl get clusterpolicy --no-headers 2>/dev/null | wc -l | tr -d ' ')"
  echo "  Cluster policies present: $count"
  if [[ "$count" -lt 1 ]]; then
    fail=1
  fi
else
  echo "  (no cluster / kyverno — skipped)"
fi

if [[ "$fail" -ne 0 ]]; then
  echo "Security checks failed — see reports/"
  exit 1
fi
echo "✓ Security checks passed"
