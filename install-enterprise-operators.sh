#!/bin/bash
# ===========================================================
# Install Enterprise ML Pipeline Operators
# Installs: ArgoCD, Vault, Prometheus, Gatekeeper
# ===========================================================

set -e

SUDO_PASS="${1:-qwert1234}"

echo "=========================================="
echo "🚀 Installing Enterprise Pipeline Operators"
echo "=========================================="
echo ""

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# 1. Install Helm
echo "[1/5] Installing Helm..."
if ! command_exists helm; then
    curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
    echo "✓ Helm installed"
else
    echo "✓ Helm already installed ($(helm version --short))"
fi

# 2. Install ArgoCD
echo ""
echo "[2/5] Installing ArgoCD..."
if ! kubectl get namespace argocd &>/dev/null; then
    kubectl create namespace argocd
    kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
    
    echo "  Waiting for ArgoCD to be ready..."
    kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd || true
    
    # Expose ArgoCD (NodePort for easy access)
    kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "NodePort"}}'
    
    echo "✓ ArgoCD installed"
    echo "  ArgoCD UI: http://$(hostname -I | awk '{print $1}'):$(kubectl get svc argocd-server -n argocd -o jsonpath='{.spec.ports[0].nodePort}')"
    echo "  Username: admin"
    echo "  Password: $(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)"
else
    echo "✓ ArgoCD already installed"
fi

# 3. Install Prometheus Operator
echo ""
echo "[3/5] Installing Prometheus Operator..."
if ! kubectl get namespace monitoring &>/dev/null; then
    kubectl create namespace monitoring
    
    # Add prometheus-community helm repo
    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
    helm repo update
    
    # Install kube-prometheus-stack (includes Prometheus Operator, Grafana, AlertManager)
    helm install prometheus prometheus-community/kube-prometheus-stack \
        --namespace monitoring \
        --set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false \
        --set grafana.service.type=NodePort \
        --set grafana.adminPassword=admin123 \
        --wait --timeout=10m
    
    echo "✓ Prometheus Operator installed"
    echo "  Grafana UI: http://$(hostname -I | awk '{print $1}'):$(kubectl get svc prometheus-grafana -n monitoring -o jsonpath='{.spec.ports[0].nodePort}')"
    echo "  Username: admin"
    echo "  Password: admin123"
else
    echo "✓ Prometheus Operator already installed"
fi

# 4. Install HashiCorp Vault
echo ""
echo "[4/5] Installing HashiCorp Vault..."
if ! kubectl get namespace vault &>/dev/null; then
    kubectl create namespace vault
    
    # Add hashicorp helm repo
    helm repo add hashicorp https://helm.releases.hashicorp.com
    helm repo update
    
    # Install Vault in dev mode (for testing)
    helm install vault hashicorp/vault \
        --namespace vault \
        --set "server.dev.enabled=true" \
        --set "server.dev.devRootToken=root" \
        --set "injector.enabled=true" \
        --set "csi.enabled=true" \
        --wait --timeout=5m
    
    echo "✓ Vault installed (dev mode)"
    echo "  Vault Token: root"
    echo "  Access: kubectl exec -it vault-0 -n vault -- vault status"
else
    echo "✓ Vault already installed"
fi

# Install Secrets Store CSI Driver
echo "  Installing Secrets Store CSI Driver..."
if ! kubectl get namespace secrets-store-csi &>/dev/null; then
    helm repo add secrets-store-csi-driver https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts
    helm repo update
    
    helm install csi-secrets-store secrets-store-csi-driver/secrets-store-csi-driver \
        --namespace kube-system \
        --set syncSecret.enabled=true \
        --wait
    
    echo "  ✓ Secrets Store CSI Driver installed"
else
    echo "  ✓ Secrets Store CSI Driver already installed"
fi

# 5. Install OPA Gatekeeper
echo ""
echo "[5/5] Installing OPA Gatekeeper..."
if ! kubectl get namespace gatekeeper-system &>/dev/null; then
    kubectl apply -f https://raw.githubusercontent.com/open-policy-agent/gatekeeper/release-3.14/deploy/gatekeeper.yaml
    
    echo "  Waiting for Gatekeeper to be ready..."
    kubectl wait --for=condition=available --timeout=300s deployment/gatekeeper-controller-manager -n gatekeeper-system || true
    
    echo "✓ OPA Gatekeeper installed"
else
    echo "✓ OPA Gatekeeper already installed"
fi

# 6. Create SecretProviderClass for Vault
echo ""
echo "[6/6] Configuring Vault SecretProviderClass..."
cat <<EOF | kubectl apply -f -
apiVersion: secrets-store.csi.x-k8s.io/v1
kind: SecretProviderClass
metadata:
  name: vault-provider
  namespace: ml-prod
spec:
  provider: vault
  parameters:
    vaultAddress: "http://vault.vault:8200"
    roleName: "ml-pipeline"
    objects: |
      - objectName: "harbor-creds"
        secretPath: "secret/data/ml-pipeline/harbor"
        secretKey: "password"
EOF

echo "✓ Vault SecretProviderClass created"

# 7. Install GPU Operator (if GPUs available)
echo ""
echo "[Optional] Checking for GPU support..."
if lspci | grep -i nvidia &>/dev/null; then
    echo "  NVIDIA GPU detected, installing GPU Operator..."
    
    helm repo add nvidia https://nvidia.github.io/gpu-operator
    helm repo update
    
    helm install --wait --generate-name \
        -n gpu-operator --create-namespace \
        nvidia/gpu-operator \
        --set driver.enabled=false
    
    echo "✓ GPU Operator installed"
else
    echo "  No NVIDIA GPU detected, skipping GPU Operator"
fi

# 8. Summary
echo ""
echo "=========================================="
echo "✅ Installation Complete!"
echo "=========================================="
echo ""
echo "📊 Installed Components:"
echo "  ✓ Helm $(helm version --short)"
echo "  ✓ ArgoCD (GitOps)"
echo "  ✓ Prometheus Operator (Monitoring)"
echo "  ✓ Grafana (Dashboards)"
echo "  ✓ Vault (Secrets Management)"
echo "  ✓ Secrets Store CSI Driver"
echo "  ✓ OPA Gatekeeper (Policy Enforcement)"
echo ""

echo "🌐 Access URLs:"
echo ""
echo "ArgoCD:"
echo "  URL: http://$(hostname -I | awk '{print $1}'):$(kubectl get svc argocd-server -n argocd -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null || echo 'N/A')"
echo "  Username: admin"
echo "  Password: $(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" 2>/dev/null | base64 -d || echo 'N/A')"
echo ""

echo "Grafana:"
echo "  URL: http://$(hostname -I | awk '{print $1}'):$(kubectl get svc prometheus-grafana -n monitoring -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null || echo 'N/A')"
echo "  Username: admin"
echo "  Password: admin123"
echo ""

echo "Vault:"
echo "  Access: kubectl port-forward svc/vault -n vault 8200:8200"
echo "  Token: root"
echo ""

echo "📋 Next Steps:"
echo ""
echo "1. Create ArgoCD Application:"
echo "   kubectl apply -f pipeline.yml"
echo ""
echo "2. Configure Vault secrets:"
echo "   kubectl exec -it vault-0 -n vault -- vault kv put secret/ml-pipeline/harbor password=Harbor12345"
echo ""
echo "3. Deploy the full pipeline:"
echo "   cd ~/Pipeline && ./deploy.sh"
echo ""
echo "4. Monitor with Grafana:"
echo "   kubectl port-forward svc/prometheus-grafana -n monitoring 3000:80"
echo ""

# Create namespace for ml-prod (needed for SecretProviderClass)
kubectl create namespace ml-prod --dry-run=client -o yaml | kubectl apply -f -

echo "=========================================="
echo "🎉 All operators installed successfully!"
echo "=========================================="

