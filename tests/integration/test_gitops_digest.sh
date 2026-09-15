#!/usr/bin/env bash
# Prove update-gitops-digest.sh never mutates env-patch.yaml
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

cp -R "$ROOT/gitops/qa/." "$TMP/qa/"
BEFORE=$(cksum "$TMP/qa/env-patch.yaml")

# Invoke against the temp overlay by temporarily pointing ROOT... easier: run python inline
# Call the real script on qa then restore — use a subshell copy approach via ROOT override
# Instead, duplicate the critical assertion using the script against repo qa with restore.

cp "$ROOT/gitops/qa/env-patch.yaml" "$TMP/before-env"
cp "$ROOT/gitops/qa/kustomization.yaml" "$TMP/before-kust"
cp "$ROOT/gitops/qa/image-digest.txt" "$TMP/before-digest" 2>/dev/null || true

FAKE='localhost:5001/demo-app@sha256:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb'
bash "$ROOT/scripts/update-gitops-digest.sh" qa "$FAKE"

if ! cmp -s "$TMP/before-env" "$ROOT/gitops/qa/env-patch.yaml"; then
  echo "FAIL: env-patch.yaml changed"
  diff -u "$TMP/before-env" "$ROOT/gitops/qa/env-patch.yaml" || true
  mv "$TMP/before-kust" "$ROOT/gitops/qa/kustomization.yaml"
  mv "$TMP/before-env" "$ROOT/gitops/qa/env-patch.yaml"
  exit 1
fi

# Restore
mv "$TMP/before-kust" "$ROOT/gitops/qa/kustomization.yaml"
mv "$TMP/before-digest" "$ROOT/gitops/qa/image-digest.txt" 2>/dev/null || \
  echo 'localhost:5001/demo-app@sha256:0000000000000000000000000000000000000000000000000000000000000000' > "$ROOT/gitops/qa/image-digest.txt"
rm -f "$ROOT/gitops/qa/image-digest.previous.txt"

# Confirm kustomize still has replicas: 2 from env-patch
out=$(kubectl kustomize "$ROOT/gitops/qa")
echo "$out" | grep -q 'replicas: 2'
echo "$out" | grep -q 'value: qa'
echo "✓ digest update preserves env-patch (replicas/env intact)"
