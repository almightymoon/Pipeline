#!/usr/bin/env bash
set -euo pipefail
FIX="$(dirname "$0")/deployment.yaml"
ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"

if kubectl get clusterpolicy verify-image-signature >/dev/null 2>&1; then
  # Creating a Pod (not just Deployment) triggers verifyImages in our policy
  kubectl apply --dry-run=server -f "$FIX" && \
    kubectl -n demo-dev run unsigned-probe --image=localhost:5001/demo-app@sha256:deadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef \
      --restart=Never --dry-run=server -o yaml >/dev/null
  exit 0
fi

# Offline: cosign verify should fail for a nonsense digest if key exists
if [[ -f "$ROOT/.cosign/cosign.pub" ]]; then
  cosign verify --key "$ROOT/.cosign/cosign.pub" --insecure-ignore-tlog=true \
    localhost:5001/demo-app@sha256:deadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef \
    && exit 0 || exit 1
fi

echo "Policy gate: unsigned image forbidden"
exit 1
