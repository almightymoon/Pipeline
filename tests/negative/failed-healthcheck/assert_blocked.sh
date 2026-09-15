#!/usr/bin/env bash
set -euo pipefail
FIX="$(dirname "$0")/deployment.yaml"
grep -q 'this-path-does-not-exist' "$FIX"
echo "Policy gate: broken readiness probe must fail rollout"
exit 1
