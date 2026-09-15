#!/usr/bin/env bash
# Prove that intentionally bad fixtures are rejected.
set -euo pipefail

ROOT="${ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
NEG="$ROOT/tests/negative"
pass=0
fail=0

run_expect_fail() {
  local name="$1"
  shift
  echo ""
  echo "▶ Negative case: $name (expect FAIL)"
  if "$@"; then
    echo "✗ UNEXPECTED PASS: $name"
    fail=$((fail + 1))
  else
    echo "✓ Correctly blocked: $name"
    pass=$((pass + 1))
  fi
}

run_expect_fail "secret committed" \
  gitleaks detect --source "$NEG/leaked-secret" --no-git \
  --config "$NEG/gitleaks-strict.toml"

run_expect_fail "vulnerable dependency" \
  bash -c "trivy fs --exit-code 1 --severity CRITICAL --scanners vuln '$NEG/vulnerable-deps' >/dev/null"

run_expect_fail "root container manifest" \
  bash "$NEG/root-container/assert_blocked.sh"

run_expect_fail "latest tag manifest" \
  bash "$NEG/latest-tag/assert_blocked.sh"

run_expect_fail "invalid helm values" \
  helm template demo "$ROOT/charts/demo-app" -f "$NEG/bad-helm/values.bad.yaml"

run_expect_fail "unsigned image policy fixture" \
  bash "$NEG/unsigned-image/assert_blocked.sh"

run_expect_fail "failed health check fixture" \
  bash "$NEG/failed-healthcheck/assert_blocked.sh"

echo ""
echo "Negative tests: ${pass} blocked correctly, ${fail} unexpectedly passed"
[[ "$fail" -eq 0 ]]
