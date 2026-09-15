#!/usr/bin/env bash
# Install platform components for PROFILE=minimal|full
set -euo pipefail

ROOT="${ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
PROFILE="${PROFILE:-minimal}"
CLUSTER="${CLUSTER:-pipeline-demo}"
COSIGN_DIR="${COSIGN_DIR:-$ROOT/.cosign}"
CTX="kind-${CLUSTER}"

kubectl config use-context "$CTX" >/dev/null

echo "→ Applying namespaces, RBAC, network policies"
kubectl apply -f "$ROOT/platform/namespaces/"
kubectl apply -f "$ROOT/platform/rbac/"
kubectl apply -f "$ROOT/platform/network-policies/"

# --- Tekton Pipelines ---
# Prefer "latest" (ghcr.io). Older previous/* releases pull from gcr.io which often 403s anonymously.
TEKTON_RELEASE_URL="${TEKTON_RELEASE_URL:-https://storage.googleapis.com/tekton-releases/pipeline/latest/release.yaml}"
if ! kubectl get deploy tekton-pipelines-controller -n tekton-pipelines >/dev/null 2>&1; then
  echo "→ Installing Tekton Pipelines from ${TEKTON_RELEASE_URL}"
  kubectl apply --filename "$TEKTON_RELEASE_URL"
elif kubectl -n tekton-pipelines get pods -o jsonpath='{range .items[*]}{.status.containerStatuses[0].state.waiting.reason}{"\n"}{end}' 2>/dev/null | grep -q ImagePullBackOff; then
  echo "→ Tekton pods stuck pulling (likely gcr.io). Re-applying latest release (ghcr.io)..."
  kubectl apply --filename "$TEKTON_RELEASE_URL"
  kubectl -n tekton-pipelines delete pods --all --force --grace-period=0 2>/dev/null || true
fi
echo "→ Waiting for Tekton pods"
kubectl wait --for=condition=Ready pods --all -n tekton-pipelines --timeout=360s

# --- Kyverno ---
if ! kubectl get ns kyverno >/dev/null 2>&1; then
  echo "→ Installing Kyverno"
  helm repo add kyverno https://kyverno.github.io/kyverno/ >/dev/null 2>&1 || true
  helm repo update >/dev/null
  helm upgrade --install kyverno kyverno/kyverno \
    --namespace kyverno --create-namespace \
    --set replicaCount=1 \
    --set admissionController.replicas=1 \
    --set backgroundController.replicas=1 \
    --set cleanupController.replicas=1 \
    --set reportsController.replicas=1 \
    --wait --timeout 10m
fi

echo "→ Applying Kyverno baseline policies"
kubectl apply -f "$ROOT/security/policies/"

# Cosign keypair for local signing (gitignored)
mkdir -p "$COSIGN_DIR"
if [[ ! -f "$COSIGN_DIR/cosign.key" ]]; then
  echo "→ Generating local Cosign keypair in .cosign/"
  COSIGN_PASSWORD=pipeline-demo cosign generate-key-pair --output-key-prefix "$COSIGN_DIR/cosign"
fi

# Publish public key as a ConfigMap/Secret for Kyverno verifyImages
kubectl -n pipeline-system create configmap cosign-pub \
  --from-file=cosign.pub="$COSIGN_DIR/cosign.pub" \
  --dry-run=client -o yaml | kubectl apply -f -

kubectl -n pipeline-ci create secret generic cosign-key \
  --from-file=cosign.key="$COSIGN_DIR/cosign.key" \
  --from-literal=COSIGN_PASSWORD=pipeline-demo \
  --dry-run=client -o yaml | kubectl apply -f -

chmod +x "$ROOT/scripts/apply-cosign-policy.sh"
"$ROOT/scripts/apply-cosign-policy.sh"

# Apply Tekton tasks & pipelines
echo "→ Applying Tekton tasks and pipelines"
kubectl apply -f "$ROOT/tekton/tasks/"
kubectl apply -f "$ROOT/tekton/pipelines/"

# GitOps overlays are applied by make demo / promote after a real digest exists
echo "→ GitOps overlays ready under gitops/{dev,qa,performance,production}"

if [[ "$PROFILE" == "full" ]]; then
  echo "→ Installing Argo CD (full profile)"
  if ! kubectl get ns argocd >/dev/null 2>&1; then
    kubectl create namespace argocd
    kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
    kubectl -n argocd wait --for=condition=Available deploy/argocd-server --timeout=300s
  fi

  echo "→ Installing kube-prometheus-stack (full profile)"
  helm repo add prometheus-community https://prometheus-community.github.io/helm-charts >/dev/null 2>&1 || true
  helm repo update >/dev/null
  helm upgrade --install monitoring prometheus-community/kube-prometheus-stack \
    --namespace monitoring --create-namespace \
    --set grafana.service.type=NodePort \
    --set grafana.service.nodePort=30300 \
    --set prometheus.service.type=NodePort \
    --set prometheus.service.nodePort=30909 \
    --wait --timeout 15m || echo "WARN: monitoring stack install issue (non-fatal for CI tasks)"

  kubectl apply -f "$ROOT/platform/observability/grafana-dashboard.yaml" || true
  kubectl apply -f "$ROOT/platform/observability/prometheus-rules.yaml" || true

  # Tekton Chains (provenance)
  CHAINS_VERSION="${CHAINS_VERSION:-v0.22.0}"
  if ! kubectl get deploy tekton-chains-controller -n tekton-chains >/dev/null 2>&1; then
    echo "→ Installing Tekton Chains ${CHAINS_VERSION}"
    kubectl apply -f "https://storage.googleapis.com/tekton-releases/chains/previous/${CHAINS_VERSION}/release.yaml" || true
  fi
else
  kubectl apply -f "$ROOT/platform/observability/grafana-dashboard.yaml" || true
fi

echo "✓ Platform installed (profile=${PROFILE})"
