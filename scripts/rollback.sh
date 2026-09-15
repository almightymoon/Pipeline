#!/usr/bin/env bash
# One-command rollback: restore previous digest in GitOps and sync.
# Fails closed if rollout does not become healthy.
set -euo pipefail

ROOT="${ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
ENV="${1:?ENV required}"
CLUSTER="${CLUSTER:-pipeline-demo}"
OVERLAY="$ROOT/gitops/${ENV}"

PREV="$OVERLAY/image-digest.previous.txt"
test -f "$PREV" || { echo "No previous digest recorded for ${ENV}. Nothing to roll back."; exit 1; }

DIGEST="$(tr -d '[:space:]' < "$PREV")"
echo "→ Rolling back ${ENV} to ${DIGEST}"

ENV_PATCH="$OVERLAY/env-patch.yaml"
cp "$ENV_PATCH" "${TMPDIR:-/tmp}/env-patch.${ENV}.rollback.before"
"$ROOT/scripts/update-gitops-digest.sh" "$ENV" "$DIGEST"
if ! cmp -s "${TMPDIR:-/tmp}/env-patch.${ENV}.rollback.before" "$ENV_PATCH"; then
  echo "FATAL: rollback modified env-patch.yaml"
  exit 1
fi

NS="demo-${ENV}"
[[ "$ENV" == "production" ]] && NS="demo-prod"
[[ "$ENV" == "dev" ]] && NS="demo-dev"

if kind get clusters 2>/dev/null | grep -qx "$CLUSTER"; then
  kubectl config use-context "kind-${CLUSTER}" >/dev/null
  kubectl apply -k "$OVERLAY"
  kubectl -n "$NS" rollout status deploy/demo-app --timeout=180s
fi

echo "✓ Rollback complete for ${ENV}"
echo "  Documented command: make rollback ENV=${ENV}"
