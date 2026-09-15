#!/usr/bin/env bash
# Full bootstrap: kind + platform
set -euo pipefail

ROOT="${ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
export ROOT
export PROFILE="${PROFILE:-minimal}"
export CLUSTER="${CLUSTER:-pipeline-demo}"
export STATE_DIR="${STATE_DIR:-$ROOT/.demo-state}"
export COSIGN_DIR="${COSIGN_DIR:-$ROOT/.cosign}"
export REPORTS="${REPORTS:-$ROOT/reports}"

mkdir -p "$STATE_DIR" "$REPORTS" "$COSIGN_DIR"

echo "=== Bootstrap (profile=${PROFILE}) ==="
"$ROOT/scripts/kind-up.sh"
"$ROOT/scripts/install-platform.sh"
echo "${PROFILE}" > "$STATE_DIR/profile"
date -u +%Y-%m-%dT%H:%M:%SZ > "$STATE_DIR/bootstrapped_at"
echo "=== Bootstrap complete ==="
echo "Next: make demo"
