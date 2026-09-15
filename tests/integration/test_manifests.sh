#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

# Basic YAML load via python
python3 - <<PY
import sys, pathlib
try:
    import yaml
except ImportError:
    print("PyYAML not installed — skipping deep parse")
    sys.exit(0)

root = pathlib.Path("$ROOT")
paths = list((root/"platform").rglob("*.yaml")) + list((root/"gitops").rglob("*.yaml")) + list((root/"security/policies").rglob("*.yaml"))
for p in paths:
    if p.name.endswith(".previous.txt"):
        continue
    with p.open() as f:
        list(yaml.safe_load_all(f))
print(f"✓ parsed {len(paths)} YAML manifests")
PY

if command -v kubectl >/dev/null 2>&1; then
  kubectl kustomize "$ROOT/gitops/dev" >/dev/null
  echo "✓ kustomize gitops/dev"
fi
