#!/usr/bin/env bash
# Promote an immutable digest through environments.
# Fails closed on missing digest, bad signature (when keys exist), or rollout failure.
set -euo pipefail

ROOT="${ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
ENV="${1:?ENV required (qa|performance|production)}"
CLUSTER="${CLUSTER:-pipeline-demo}"
COSIGN_DIR="${COSIGN_DIR:-$ROOT/.cosign}"

case "$ENV" in
  qa) SRC=dev ;;
  performance) SRC=qa ;;
  production) SRC=performance ;;
  *) echo "Promote target must be qa|performance|production"; exit 1 ;;
esac

DIGEST_FILE="$ROOT/gitops/${SRC}/image-digest.txt"
test -f "$DIGEST_FILE" || { echo "No digest in gitops/${SRC}. Run make demo first."; exit 1; }
DIGEST="$(tr -d '[:space:]' < "$DIGEST_FILE")"

if [[ ! "$DIGEST" =~ @sha256:[a-fA-F0-9]{64}$ ]]; then
  echo "Source digest looks invalid: $DIGEST"
  exit 1
fi
if [[ "$DIGEST" == *"@sha256:0000000000000000000000000000000000000000000000000000000000000000" ]]; then
  echo "Source digest is still the placeholder — run make demo / deploy a real image first."
  exit 1
fi

# Verify Cosign signature when a local key exists (minimal demo) or COSIGN_PUB is set
PUB="${COSIGN_PUB:-$COSIGN_DIR/cosign.pub}"
if [[ -f "$PUB" ]]; then
  echo "→ Verifying Cosign signature for ${DIGEST}"
  cosign verify --key "$PUB" --insecure-ignore-tlog=true --allow-insecure-registry "$DIGEST"
else
  echo "WARN: no Cosign public key at $PUB — skipping signature verify"
fi

# Snapshot env-patch before update (must remain byte-identical)
ENV_PATCH="$ROOT/gitops/${ENV}/env-patch.yaml"
test -f "$ENV_PATCH"
cp "$ENV_PATCH" "${TMPDIR:-/tmp}/env-patch.${ENV}.before"

"$ROOT/scripts/update-gitops-digest.sh" "$ENV" "$DIGEST"

if ! cmp -s "${TMPDIR:-/tmp}/env-patch.${ENV}.before" "$ENV_PATCH"; then
  echo "FATAL: update-gitops-digest.sh modified env-patch.yaml — refusing promotion"
  exit 1
fi

NS="demo-${ENV}"
[[ "$ENV" == "production" ]] && NS="demo-prod"

if kind get clusters 2>/dev/null | grep -qx "$CLUSTER"; then
  kubectl config use-context "kind-${CLUSTER}" >/dev/null
  kubectl apply -k "$ROOT/gitops/${ENV}"
  echo "→ Waiting for rollout in ${NS}"
  kubectl -n "$NS" rollout status deploy/demo-app --timeout=180s
else
  echo "No kind cluster '${CLUSTER}' — GitOps files updated; skip cluster apply"
fi

# Optional DAST gate for QA+ promotions when explicitly enabled.
if [[ "${DAST_REQUIRED:-0}" == "1" ]]; then
  echo "→ DAST required for ${ENV}"
  TARGET="${DAST_TARGET:-}"
  if [[ -z "$TARGET" ]]; then
    echo "DAST_REQUIRED=1 but DAST_TARGET is unset (e.g. http://demo-app.demo-qa.svc:8080)"
    exit 1
  fi
  "$ROOT/scripts/dast-zap.sh" "$TARGET"
fi

echo "✓ Promoted ${DIGEST} → ${ENV} (from ${SRC})"
echo "  Audit trail: gitops/${ENV}/image-digest.txt"
echo "  Overlay settings preserved: gitops/${ENV}/env-patch.yaml"
