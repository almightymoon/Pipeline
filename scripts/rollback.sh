#!/usr/bin/env bash
# One-command rollback: restore previous digest in GitOps and sync
set -euo pipefail

ROOT="${ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
ENV="${1:?ENV required}"
CLUSTER="${CLUSTER:-pipeline-demo}"
OVERLAY="$ROOT/gitops/${ENV}"

PREV="$OVERLAY/image-digest.previous.txt"
test -f "$PREV" || { echo "No previous digest recorded for ${ENV}. Nothing to roll back."; exit 1; }

DIGEST="$(cat "$PREV")"
echo "→ Rolling back ${ENV} to ${DIGEST}"
"$ROOT/scripts/update-gitops-digest.sh" "$ENV" "$DIGEST"

if kind get clusters 2>/dev/null | grep -qx "$CLUSTER"; then
  kubectl config use-context "kind-${CLUSTER}" >/dev/null
  kubectl apply -k "$ROOT/gitops/${ENV}"
  NS="demo-${ENV}"
  [[ "$ENV" == "production" ]] && NS="demo-prod"
  [[ "$ENV" == "dev" ]] && NS="demo-dev"
  kubectl -n "$NS" rollout status deploy/demo-app --timeout=180s
fi

echo "✓ Rollback complete for ${ENV}"
echo "  Documented command: make rollback ENV=${ENV}"
