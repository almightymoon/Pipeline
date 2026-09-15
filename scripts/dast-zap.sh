#!/usr/bin/env bash
# Optional: run OWASP ZAP baseline against a live target (QA+).
set -euo pipefail

TARGET="${1:?usage: dast-zap.sh http://host:port}"
REPORTS="${REPORTS:-$(cd "$(dirname "$0")/.." && pwd)/reports}"
mkdir -p "$REPORTS"

docker run --rm --network host \
  -v "$REPORTS:/zap/wrk:rw" \
  ghcr.io/zaproxy/zaproxy:stable \
  zap-baseline.py -t "$TARGET" -r zap-report.html -J zap-report.json || {
    status=$?
    # zap-baseline exits 2 when warnings present; treat High via JSON policy in CI
    echo "ZAP finished with exit $status — review $REPORTS/zap-report.html"
    exit "$status"
  }
