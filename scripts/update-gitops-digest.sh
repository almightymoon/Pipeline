#!/usr/bin/env bash
# Update image digest in GitOps overlay for ENV
set -euo pipefail

ROOT="${ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
ENV="${1:?env required}"
DIGEST="${2:?digest required}" # repo@sha256:...

OVERLAY="$ROOT/gitops/${ENV}"
test -d "$OVERLAY" || { echo "Unknown env: $ENV"; exit 1; }

# Keep previous digest for rollback
if [[ -f "$OVERLAY/image-digest.txt" ]]; then
  cp "$OVERLAY/image-digest.txt" "$OVERLAY/image-digest.previous.txt"
fi
echo "$DIGEST" > "$OVERLAY/image-digest.txt"

# Patch kustomization or deployment patch
cat > "$OVERLAY/image-patch.yaml" <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: demo-app
spec:
  template:
    spec:
      containers:
      - name: demo-app
        image: ${DIGEST}
EOF

echo "✓ GitOps ${ENV} → ${DIGEST}"
