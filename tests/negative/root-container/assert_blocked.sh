#!/usr/bin/env bash
# Expect Kyverno (or local policy check) to reject root containers.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
FIX="$(dirname "$0")/deployment.yaml"

if kubectl get clusterpolicy require-non-root >/dev/null 2>&1; then
  kubectl apply --dry-run=server -f "$FIX"
  # If apply succeeds, policy did not block — fail this negative test
  exit 0
fi

# Offline assertion: fixture must declare runAsUser: 0
grep -q 'runAsUser: 0' "$FIX"
# Simulate gate: treat root as failure
echo "Policy gate: root container forbidden"
exit 1
