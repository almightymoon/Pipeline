#!/usr/bin/env bash
set -euo pipefail
FIX="$(dirname "$0")/deployment.yaml"

if kubectl get clusterpolicy disallow-latest-tag >/dev/null 2>&1; then
  kubectl apply --dry-run=server -f "$FIX"
  exit 0
fi

grep -q ':latest' "$FIX"
echo "Policy gate: :latest tag forbidden"
exit 1
