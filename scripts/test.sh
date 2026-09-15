#!/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
export ROOT
export REPORTS="${REPORTS:-$ROOT/reports}"
mkdir -p "$REPORTS"

echo "=== Unit tests (demo-app) ==="
python3 -m venv "$ROOT/.venv" 2>/dev/null || true
# shellcheck disable=SC1091
source "$ROOT/.venv/bin/activate"
pip install -q -r "$ROOT/examples/demo-app/requirements.txt" pytest
(cd "$ROOT/examples/demo-app" && pytest -q | tee "$REPORTS/pytest.txt")

echo "=== Smoke tests (scripts) ==="
bash "$ROOT/tests/smoke/test_scripts_exist.sh"

echo "=== Integration checks (manifests parse) ==="
bash "$ROOT/tests/integration/test_manifests.sh"
bash "$ROOT/tests/integration/test_gitops_digest.sh"

echo "✓ All tests passed"
