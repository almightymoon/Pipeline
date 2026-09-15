#!/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
export ROOT
"$ROOT/scripts/kind-down.sh"
rm -rf "${STATE_DIR:-$ROOT/.demo-state}" "${REPORTS:-$ROOT/reports}"
# Keep .cosign by default so re-verify works; remove with DESTROY_KEYS=1
if [[ "${DESTROY_KEYS:-0}" == "1" ]]; then
  rm -rf "${COSIGN_DIR:-$ROOT/.cosign}"
fi
echo "✓ Destroy complete (set DESTROY_KEYS=1 to also remove Cosign keys)"
