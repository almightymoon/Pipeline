#!/usr/bin/env bash
# End-to-end demo: ensure platform → build/sign/push → pipeline gates → deploy → smoke
set -euo pipefail

ROOT="${ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
export ROOT
export PROFILE="${PROFILE:-minimal}"
export CLUSTER="${CLUSTER:-pipeline-demo}"
export REGISTRY="${REGISTRY:-localhost:5001}"
export IMAGE="${IMAGE:-$REGISTRY/demo-app}"
export STATE_DIR="${STATE_DIR:-$ROOT/.demo-state}"
export COSIGN_DIR="${COSIGN_DIR:-$ROOT/.cosign}"
export REPORTS="${REPORTS:-$ROOT/reports}"
CTX="kind-${CLUSTER}"

mkdir -p "$STATE_DIR" "$REPORTS" "$COSIGN_DIR"

if [[ ! -f "$STATE_DIR/bootstrapped_at" ]] || ! kind get clusters 2>/dev/null | grep -qx "$CLUSTER"; then
  echo "→ Platform not ready; running bootstrap"
  "$ROOT/scripts/bootstrap.sh"
fi

kubectl config use-context "$CTX" >/dev/null

TAG="$(git -C "$ROOT" rev-parse --short HEAD 2>/dev/null || echo manual)"
TAG="${TAG}-$(date +%s)"
FULL_IMAGE="${IMAGE}:${TAG}"

echo "=== Demo build → scan → SBOM → sign → push ==="
echo "Image: ${FULL_IMAGE}"

docker build -t "$FULL_IMAGE" "$ROOT/examples/demo-app"
docker push "$FULL_IMAGE"
# Resolve registry digest after push
REPO_DIGEST="$(docker inspect --format='{{index .RepoDigests 0}}' "$FULL_IMAGE" 2>/dev/null || true)"
if [[ -z "$REPO_DIGEST" || "$REPO_DIGEST" == "<no value>" ]]; then
  # Fallback: query local registry v2 API
  DIGEST_HASH="$(curl -sI "http://${REGISTRY}/v2/demo-app/manifests/${TAG}" \
    -H 'Accept: application/vnd.docker.distribution.manifest.v2+json' \
    | tr -d '\r' | awk -F': ' 'tolower($1)=="docker-content-digest"{print $2}')"
  REPO_DIGEST="${IMAGE}@${DIGEST_HASH}"
fi
echo "$REPO_DIGEST" > "$STATE_DIR/image-digest"
echo "$TAG" > "$STATE_DIR/image-tag"
echo "Published: $REPO_DIGEST"

echo "→ Trivy image scan (fail on HIGH/CRITICAL)"
trivy image --exit-code 1 --severity HIGH,CRITICAL --ignore-unfixed "$FULL_IMAGE" \
  | tee "$REPORTS/trivy-image.txt"

echo "→ Syft SBOM"
syft "$FULL_IMAGE" -o spdx-json > "$REPORTS/sbom.spdx.json"
syft "$FULL_IMAGE" -o cyclonedx-json > "$REPORTS/sbom.cdx.json"

if [[ ! -f "$COSIGN_DIR/cosign.key" ]]; then
  COSIGN_PASSWORD=pipeline-demo cosign generate-key-pair --output-key-prefix "$COSIGN_DIR/cosign"
fi

echo "→ Cosign sign + SBOM attestation"
export COSIGN_PASSWORD=pipeline-demo
cosign sign --key "$COSIGN_DIR/cosign.key" --tlog-upload=false --allow-insecure-registry "$REPO_DIGEST"
cosign attest --key "$COSIGN_DIR/cosign.key" --tlog-upload=false --allow-insecure-registry \
  --predicate "$REPORTS/sbom.spdx.json" --type spdxjson "$REPO_DIGEST"

echo "→ Verify signature"
cosign verify --key "$COSIGN_DIR/cosign.pub" --insecure-ignore-tlog=true --allow-insecure-registry "$REPO_DIGEST"

echo "=== Run Tekton security pipeline (source gates) ==="
"$ROOT/scripts/run-pipeline.sh"

echo "=== Update GitOps digest (dev) & apply ==="
"$ROOT/scripts/update-gitops-digest.sh" dev "$REPO_DIGEST"
kubectl apply -k "$ROOT/gitops/dev"
kubectl -n demo-dev rollout status deploy/demo-app --timeout=180s

echo "=== Smoke check ==="
# Port-forward briefly
kubectl -n demo-dev port-forward svc/demo-app 18080:8080 >/tmp/pf-demo.log 2>&1 &
PF_PID=$!
trap 'kill $PF_PID 2>/dev/null || true' EXIT
sleep 3
curl -sf http://127.0.0.1:18080/healthz | tee "$REPORTS/smoke-healthz.json"
echo ""
curl -sf http://127.0.0.1:18080/metrics | head -n 5 | tee "$REPORTS/smoke-metrics.txt"
echo ""

kill $PF_PID 2>/dev/null || true
trap - EXIT

cat <<EOF

╔══════════════════════════════════════════════════════════╗
║  DEMO SUCCEEDED                                          ║
╠══════════════════════════════════════════════════════════╣
║  Image digest : ${REPO_DIGEST}
║  Environment  : demo-dev (GitOps)
║  SBOM         : reports/sbom.spdx.json
║  Signature    : verified with .cosign/cosign.pub
║  Metrics      : /metrics on demo-app
║                                                          ║
║  Try negative gates:  make negative-tests                ║
║  Promote:             make promote ENV=qa                ║
║  Rollback:            make rollback ENV=dev              ║
║  Destroy:             make destroy                       ║
╚══════════════════════════════════════════════════════════╝
EOF
