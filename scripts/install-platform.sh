#!/usr/bin/env bash
# Install platform components for PROFILE=minimal|full
# Versions are pinned in platform/versions.yaml (override via env).
set -euo pipefail

ROOT="${ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
PROFILE="${PROFILE:-minimal}"
CLUSTER="${CLUSTER:-pipeline-demo}"
COSIGN_DIR="${COSIGN_DIR:-$ROOT/.cosign}"
CTX="kind-${CLUSTER}"
VERSIONS="$ROOT/platform/versions.yaml"

kubectl config use-context "$CTX" >/dev/null

# --- pinned versions ---
yaml_get() {
  # Minimal YAML scalar reader: key: "value"
  local key="$1"
  local default="${2:-}"
  local val
  val="$(awk -v k="$key" '
    $0 ~ "^"k":" {
      sub("^[^:]+:[[:space:]]*", "");
      gsub(/"/, "");
      print; exit
    }' "$VERSIONS" 2>/dev/null || true)"
  if [[ -z "$val" ]]; then
    echo "$default"
  else
    echo "$val"
  fi
}

TEKTON_PIPELINES_URL="${TEKTON_RELEASE_URL:-$(yaml_get tekton_pipelines_url 'https://storage.googleapis.com/tekton-releases/pipeline/previous/v0.68.0/release.yaml')}"
TEKTON_FALLBACK_URL="$(yaml_get tekton_pipelines_url_ghcr_fallback 'https://storage.googleapis.com/tekton-releases/pipeline/latest/release.yaml')"
TEKTON_TRIGGERS_URL="${TEKTON_TRIGGERS_URL:-$(yaml_get tekton_triggers_url)}"
TEKTON_INTERCEPTORS_URL="${TEKTON_INTERCEPTORS_URL:-$(yaml_get tekton_triggers_interceptors_url)}"
TEKTON_CHAINS_URL="${TEKTON_CHAINS_URL:-$(yaml_get tekton_chains_url)}"
KYVERNO_CHART_VERSION="${KYVERNO_CHART_VERSION:-$(yaml_get kyverno_chart_version '3.3.4')}"
ARGO_CD_URL="${ARGO_CD_URL:-$(yaml_get argo_cd_url)}"
PROM_CHART_VERSION="${PROM_CHART_VERSION:-$(yaml_get kube_prometheus_stack_chart_version '65.1.0')}"

echo "→ Applying namespaces, RBAC, network policies"
kubectl apply -f "$ROOT/platform/namespaces/"
kubectl apply -f "$ROOT/platform/rbac/"
kubectl apply -f "$ROOT/platform/network-policies/"

# --- Tekton Pipelines (pinned URL; fallback if ImagePullBackOff on gcr.io) ---
install_tekton_pipelines() {
  local url="$1"
  echo "→ Installing Tekton Pipelines from ${url}"
  kubectl apply --filename "$url"
}

if ! kubectl get deploy tekton-pipelines-controller -n tekton-pipelines >/dev/null 2>&1; then
  install_tekton_pipelines "$TEKTON_PIPELINES_URL"
fi

echo "→ Waiting for Tekton pods"
if ! kubectl wait --for=condition=Ready pods --all -n tekton-pipelines --timeout=180s 2>/dev/null; then
  if kubectl -n tekton-pipelines get pods -o jsonpath='{range .items[*]}{.status.containerStatuses[0].state.waiting.reason}{"\n"}{end}' 2>/dev/null | grep -q ImagePullBackOff; then
    echo "→ Tekton image pull failed (often gcr.io 403). Falling back to ${TEKTON_FALLBACK_URL}"
    install_tekton_pipelines "$TEKTON_FALLBACK_URL"
    kubectl -n tekton-pipelines delete pods --all --force --grace-period=0 2>/dev/null || true
    kubectl wait --for=condition=Ready pods --all -n tekton-pipelines --timeout=360s
  else
    kubectl wait --for=condition=Ready pods --all -n tekton-pipelines --timeout=360s
  fi
fi

# --- Tekton Triggers (GitHub EventListener) ---
if [[ -n "$TEKTON_TRIGGERS_URL" ]]; then
  if ! kubectl get crd eventlisteners.triggers.tekton.dev >/dev/null 2>&1; then
    echo "→ Installing Tekton Triggers ${TEKTON_TRIGGERS_URL}"
    kubectl apply -f "$TEKTON_TRIGGERS_URL"
    kubectl apply -f "$TEKTON_INTERCEPTORS_URL"
    kubectl wait --for=condition=Ready pods --all -n tekton-pipelines --timeout=300s || true
  fi
fi

# --- Kyverno (pinned chart version) ---
if ! kubectl get ns kyverno >/dev/null 2>&1; then
  echo "→ Installing Kyverno chart ${KYVERNO_CHART_VERSION}"
  helm repo add kyverno https://kyverno.github.io/kyverno/ >/dev/null 2>&1 || true
  helm repo update >/dev/null
  helm upgrade --install kyverno kyverno/kyverno \
    --version "$KYVERNO_CHART_VERSION" \
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

for ns in pipeline-system pipeline-ci; do
  kubectl -n "$ns" create configmap cosign-pub \
    --from-file=cosign.pub="$COSIGN_DIR/cosign.pub" \
    --dry-run=client -o yaml | kubectl apply -f -
done

kubectl -n pipeline-ci create secret generic cosign-key \
  --from-file=cosign.key="$COSIGN_DIR/cosign.key" \
  --from-literal=COSIGN_PASSWORD=pipeline-demo \
  --dry-run=client -o yaml | kubectl apply -f -

chmod +x "$ROOT/scripts/apply-cosign-policy.sh"
"$ROOT/scripts/apply-cosign-policy.sh"

# Apply Tekton tasks, pipelines, triggers
echo "→ Applying Tekton tasks and pipelines"
kubectl apply -f "$ROOT/tekton/tasks/"
kubectl apply -f "$ROOT/tekton/pipelines/"

if kubectl get crd eventlisteners.triggers.tekton.dev >/dev/null 2>&1; then
  echo "→ Applying Tekton GitHub triggers"
  # ClusterRole may differ by Triggers version — apply and warn on RBAC mismatch
  kubectl apply -f "$ROOT/tekton/triggers/" || {
    echo "WARN: trigger apply had errors (check ClusterRole names for your Triggers version)"
  }
else
  echo "WARN: Tekton Triggers CRDs missing — GitHub EventListener not installed"
fi

echo "→ GitOps overlays ready under gitops/{dev,qa,performance,production}"

if [[ "$PROFILE" == "full" ]]; then
  echo "→ Installing Argo CD ${ARGO_CD_URL}"
  if ! kubectl get ns argocd >/dev/null 2>&1; then
    kubectl create namespace argocd
    kubectl apply -n argocd -f "$ARGO_CD_URL"
    kubectl -n argocd wait --for=condition=Available deploy/argocd-server --timeout=300s
  fi

  echo "→ Installing kube-prometheus-stack chart ${PROM_CHART_VERSION}"
  helm repo add prometheus-community https://prometheus-community.github.io/helm-charts >/dev/null 2>&1 || true
  helm repo update >/dev/null
  helm upgrade --install monitoring prometheus-community/kube-prometheus-stack \
    --version "$PROM_CHART_VERSION" \
    --namespace monitoring --create-namespace \
    --set grafana.service.type=NodePort \
    --set grafana.service.nodePort=30300 \
    --set prometheus.service.type=NodePort \
    --set prometheus.service.nodePort=30909 \
    --wait --timeout 15m || echo "WARN: monitoring stack install issue"

  kubectl apply -f "$ROOT/platform/observability/grafana-dashboard.yaml" || true
  kubectl apply -f "$ROOT/platform/observability/prometheus-rules.yaml" || true

  if [[ -n "$TEKTON_CHAINS_URL" ]] && ! kubectl get deploy tekton-chains-controller -n tekton-chains >/dev/null 2>&1; then
    echo "→ Installing Tekton Chains ${TEKTON_CHAINS_URL}"
    kubectl apply -f "$TEKTON_CHAINS_URL" || true
  fi
else
  kubectl apply -f "$ROOT/platform/observability/grafana-dashboard.yaml" || true
fi

echo "✓ Platform installed (profile=${PROFILE})"
echo "  Pins: platform/versions.yaml"
echo "  Webhook: replace secretToken in pipeline-ci/github-webhook-secret before public use"
