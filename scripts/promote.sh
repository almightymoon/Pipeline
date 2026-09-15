#!/usr/bin/env bash
# Promote current digest from previous env chain into ENV
set -euo pipefail

ROOT="${ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
ENV="${1:?ENV required (qa|performance|production)}"
CLUSTER="${CLUSTER:-pipeline-demo}"

case "$ENV" in
  qa) SRC=dev ;;
  performance) SRC=qa ;;
  production) SRC=performance ;;
  *) echo "Promote target must be qa|performance|production"; exit 1 ;;
esac

DIGEST_FILE="$ROOT/gitops/${SRC}/image-digest.txt"
test -f "$DIGEST_FILE" || { echo "No digest in gitops/${SRC}. Run make demo first."; exit 1; }
DIGEST="$(cat "$DIGEST_FILE")"

"$ROOT/scripts/update-gitops-digest.sh" "$ENV" "$DIGEST"

if kind get clusters 2>/dev/null | grep -qx "$CLUSTER"; then
  kubectl config use-context "kind-${CLUSTER}" >/dev/null
  kubectl apply -k "$ROOT/gitops/${ENV}"
  NS="demo-${ENV}"
  [[ "$ENV" == "production" ]] && NS="demo-prod"
  kubectl -n "$NS" rollout status deploy/demo-app --timeout=180s || true
fi

echo "✓ Promoted ${DIGEST} → ${ENV} (from ${SRC})"
echo "  Audit trail: gitops/${ENV}/image-digest.txt"
