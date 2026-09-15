#!/usr/bin/env bash
# Apply Cosign verifyImages policy with the bootstrap-generated public key.
#
# Kind limitation: Kyverno pods cannot reach the host-published registry at
# localhost:5001 (that address is the pod loopback). For PROFILE=minimal we skip
# in-cluster signature admission and rely on host-side `cosign verify` in make demo.
# Set COSIGN_ENFORCE=1 (or PROFILE=full with a cluster-reachable registry) to Enforce.
set -euo pipefail

ROOT="${ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
COSIGN_DIR="${COSIGN_DIR:-$ROOT/.cosign}"
PROFILE="${PROFILE:-minimal}"
PUB="$COSIGN_DIR/cosign.pub"

test -f "$PUB" || { echo "Missing $PUB — run bootstrap first"; exit 1; }

if [[ "$PROFILE" == "minimal" && "${COSIGN_ENFORCE:-0}" != "1" ]]; then
  kubectl delete clusterpolicy verify-image-signature --ignore-not-found >/dev/null 2>&1 || true
  echo "✓ Skipping in-cluster Cosign admission for kind/minimal (host cosign verify still runs in make demo)"
  echo "  Tip: COSIGN_ENFORCE=1 requires a registry hostname reachable from Kyverno pods"
  exit 0
fi

KEY_BLOCK="$(sed 's/^/                      /' "$PUB")"

kubectl apply -f - <<EOF
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: verify-image-signature
  annotations:
    policies.kyverno.io/title: Verify Cosign signature
    policies.kyverno.io/category: Supply Chain
    policies.kyverno.io/severity: critical
spec:
  validationFailureAction: Enforce
  webhookTimeoutSeconds: 30
  rules:
    - name: verify-signature
      match:
        any:
          - resources:
              kinds: ["Pod"]
              namespaces: ["demo-dev", "demo-qa", "demo-performance", "demo-prod"]
      verifyImages:
        - imageReferences:
            - "*"
          attestors:
            - count: 1
              entries:
                - keys:
                    publicKeys: |
${KEY_BLOCK}
                    rekor:
                      ignoreTlog: true
                    ctlog:
                      ignoreSCT: true
          mutateDigest: false
          required: true
EOF

echo "✓ verify-image-signature Enforced with local Cosign public key"
