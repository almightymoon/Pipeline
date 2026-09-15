#!/usr/bin/env bash
# Update ONLY the image digest in a GitOps overlay.
# Never rewrites env-patch.yaml (replicas, env, resources stay intact).
set -euo pipefail

ROOT="${ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
ENV="${1:?env required}"
DIGEST_REF="${2:?digest required}" # repo@sha256:... OR sha256:...

OVERLAY="$ROOT/gitops/${ENV}"
test -d "$OVERLAY" || { echo "Unknown env: $ENV"; exit 1; }
test -f "$OVERLAY/kustomization.yaml" || { echo "Missing $OVERLAY/kustomization.yaml"; exit 1; }
test -f "$OVERLAY/env-patch.yaml" || { echo "Missing $OVERLAY/env-patch.yaml (refusing to invent overlay settings)"; exit 1; }

# Normalize to bare digest (sha256:...)
if [[ "$DIGEST_REF" == *"@"* ]]; then
  DIGEST="${DIGEST_REF##*@}"
  IMAGE_REF="$DIGEST_REF"
else
  DIGEST="$DIGEST_REF"
  IMAGE_REF="localhost:5001/demo-app@${DIGEST}"
fi

if [[ ! "$DIGEST" =~ ^sha256:[a-fA-F0-9]{64}$ ]]; then
  echo "Invalid digest: $DIGEST (expected sha256:<64 hex>)"
  exit 1
fi

# Keep previous digest for rollback
if [[ -f "$OVERLAY/image-digest.txt" ]]; then
  cp "$OVERLAY/image-digest.txt" "$OVERLAY/image-digest.previous.txt"
fi
echo "$IMAGE_REF" > "$OVERLAY/image-digest.txt"

# Patch only images[].digest in kustomization.yaml (leave patches/resources alone)
python3 - <<PY
from pathlib import Path
import re

path = Path("$OVERLAY/kustomization.yaml")
text = path.read_text()
digest = "$DIGEST"

# Replace digest under images: for localhost:5001/demo-app
pattern = re.compile(
    r"(images:\s*\n(?:.*\n)*?\s+- name:\s*localhost:5001/demo-app\s*\n\s+digest:\s*)sha256:[a-fA-F0-9]+",
    re.MULTILINE,
)
new, n = pattern.subn(rf"\1{digest}", text, count=1)
if n != 1:
    # Fallback: any digest line immediately after demo-app name
    pattern2 = re.compile(
        r"(- name:\s*localhost:5001/demo-app\s*\n\s+digest:\s*)sha256:[a-fA-F0-9]+"
    )
    new, n = pattern2.subn(rf"\1{digest}", text, count=1)
if n != 1:
    raise SystemExit(f"Could not update images digest in {path} (matches={n})")

path.write_text(new)
print(f"✓ Updated {path} digest → {digest}")
PY

# Sanity: env-patch must still exist and must NOT contain an image: override
if grep -qE '^\s*image:' "$OVERLAY/env-patch.yaml"; then
  echo "ERROR: $OVERLAY/env-patch.yaml contains an image: field — remove it so digests only live in kustomization.yaml"
  exit 1
fi

echo "✓ GitOps ${ENV} → ${IMAGE_REF} (env-patch untouched)"
