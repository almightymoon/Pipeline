#!/bin/bash

#=========================================
# K3s Kubernetes Cluster Setup Script
# For VPS Deployment
#=========================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# VPS Details
VPS_IP="${VPS_IP:-213.109.162.134}"
VPS_USER="${VPS_USER:-root}"

echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}  K3s Kubernetes Cluster Setup${NC}"
echo -e "${BLUE}=========================================${NC}"
echo ""
echo -e "${YELLOW}VPS IP:${NC} $VPS_IP"
echo -e "${YELLOW}User:${NC} $VPS_USER"
echo ""

#=========================================
# Step 1: System Preparation
#=========================================
echo -e "${GREEN}[1/8] Preparing system...${NC}"

ssh ${VPS_USER}@${VPS_IP} << 'ENDSSH'
    # Update system
    apt-get update
    apt-get upgrade -y
    
    # Install required packages
    apt-get install -y \
        curl \
        wget \
        git \
        ca-certificates \
        gnupg \
        lsb-release \
        apt-transport-https \
        software-properties-common
    
    # Disable swap (required for Kubernetes)
    swapoff -a
    sed -i '/ swap / s/^/#/' /etc/fstab
    
    # Load required kernel modules
    cat <<EOF | tee /etc/modules-load.d/k3s.conf
br_netfilter
overlay
ip_vs
ip_vs_rr
ip_vs_wrr
ip_vs_sh
nf_conntrack
EOF
    
    modprobe br_netfilter
    modprobe overlay
    modprobe ip_vs
    modprobe ip_vs_rr
    modprobe ip_vs_wrr
    modprobe ip_vs_sh
    modprobe nf_conntrack
    
    # Configure sysctl
    cat <<EOF | tee /etc/sysctl.d/k3s.conf
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
net.ipv6.conf.all.forwarding = 1
vm.swappiness = 0
EOF
    
    sysctl --system
    
    echo "✅ System preparation completed"
ENDSSH

#=========================================
# Step 2: Install K3s
#=========================================
echo -e "${GREEN}[2/8] Installing K3s...${NC}"

ssh ${VPS_USER}@${VPS_IP} << 'ENDSSH'
    # Install K3s with custom options
    curl -sfL https://get.k3s.io | sh -s - \
        --write-kubeconfig-mode 644 \
        --disable traefik \
        --node-external-ip ${VPS_IP} \
        --bind-address ${VPS_IP} \
        --advertise-address ${VPS_IP} \
        --tls-san ${VPS_IP} \
        --node-name k3s-master
    
    # Wait for K3s to be ready
    sleep 10
    
    # Check K3s status
    systemctl status k3s --no-pager || true
    
    echo "✅ K3s installation completed"
ENDSSH

#=========================================
# Step 3: Configure kubectl
#=========================================
echo -e "${GREEN}[3/8] Configuring kubectl...${NC}"

ssh ${VPS_USER}@${VPS_IP} << 'ENDSSH'
    # Create kubectl config directory
    mkdir -p ~/.kube
    
    # Copy K3s config to kubectl config
    cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
    
    # Set proper permissions
    chmod 600 ~/.kube/config
    
    # Update server address in config
    sed -i "s/127.0.0.1/${VPS_IP}/g" ~/.kube/config
    
    # Install kubectl (if not present)
    if ! command -v kubectl &> /dev/null; then
        curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
        chmod +x kubectl
        mv kubectl /usr/local/bin/
    fi
    
    # Test kubectl
    kubectl version --client
    kubectl get nodes
    
    echo "✅ kubectl configuration completed"
ENDSSH

#=========================================
# Step 4: Install Helm
#=========================================
echo -e "${GREEN}[4/8] Installing Helm...${NC}"

ssh ${VPS_USER}@${VPS_IP} << 'ENDSSH'
    # Install Helm
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
    
    # Add common Helm repositories
    helm repo add stable https://charts.helm.sh/stable
    helm repo add bitnami https://charts.bitnami.com/bitnami
    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
    helm repo add grafana https://grafana.github.io/helm-charts
    helm repo update
    
    echo "✅ Helm installation completed"
ENDSSH

#=========================================
# Step 5: Create Namespaces
#=========================================
echo -e "${GREEN}[5/8] Creating namespaces...${NC}"

ssh ${VPS_USER}@${VPS_IP} << 'ENDSSH'
    # Create pipeline namespaces
    kubectl create namespace pipeline-apps --dry-run=client -o yaml | kubectl apply -f -
    kubectl create namespace ml-pipeline --dry-run=client -o yaml | kubectl apply -f -
    kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -
    kubectl create namespace ingress-nginx --dry-run=client -o yaml | kubectl apply -f -
    
    # Label namespaces
    kubectl label namespace pipeline-apps environment=production --overwrite
    kubectl label namespace ml-pipeline environment=production --overwrite
    kubectl label namespace monitoring environment=system --overwrite
    
    echo "✅ Namespaces created"
ENDSSH

#=========================================
# Step 6: Install NGINX Ingress Controller
#=========================================
echo -e "${GREEN}[6/8] Installing NGINX Ingress Controller...${NC}"

ssh ${VPS_USER}@${VPS_IP} << 'ENDSSH'
    # Install NGINX Ingress Controller using Helm
    helm upgrade --install ingress-nginx ingress-nginx \
        --repo https://kubernetes.github.io/ingress-nginx \
        --namespace ingress-nginx \
        --create-namespace \
        --set controller.service.type=NodePort \
        --set controller.service.nodePorts.http=30080 \
        --set controller.service.nodePorts.https=30443 \
        --wait
    
    echo "✅ NGINX Ingress Controller installed"
ENDSSH

#=========================================
# Step 7: Install Metrics Server
#=========================================
echo -e "${GREEN}[7/8] Installing Metrics Server...${NC}"

ssh ${VPS_USER}@${VPS_IP} << 'ENDSSH'
    # Install Metrics Server for resource monitoring
    kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
    
    # Patch metrics server to work with K3s
    kubectl patch deployment metrics-server -n kube-system --type='json' \
        -p='[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--kubelet-insecure-tls"}]'
    
    echo "✅ Metrics Server installed"
ENDSSH

#=========================================
# Step 8: Download kubeconfig for GitHub Actions
#=========================================
echo -e "${GREEN}[8/8] Downloading kubeconfig...${NC}"

# Create local .kube directory if it doesn't exist
mkdir -p ~/.kube

# Download kubeconfig from VPS
scp ${VPS_USER}@${VPS_IP}:/etc/rancher/k3s/k3s.yaml ~/.kube/config-vps

# Update server address
sed -i '' "s/127.0.0.1/${VPS_IP}/g" ~/.kube/config-vps

echo -e "${GREEN}✅ Kubeconfig downloaded to ~/.kube/config-vps${NC}"

#=========================================
# Verify Installation
#=========================================
echo ""
echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}  Verifying Installation${NC}"
echo -e "${BLUE}=========================================${NC}"

ssh ${VPS_USER}@${VPS_IP} << 'ENDSSH'
    echo ""
    echo "📊 Cluster Information:"
    kubectl cluster-info
    
    echo ""
    echo "🔍 Node Status:"
    kubectl get nodes -o wide
    
    echo ""
    echo "📦 System Pods:"
    kubectl get pods -A
    
    echo ""
    echo "🌐 Services:"
    kubectl get svc -A
    
    echo ""
    echo "📁 Namespaces:"
    kubectl get namespaces
ENDSSH

#=========================================
# Generate GitHub Secret
#=========================================
echo ""
echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}  GitHub Actions Configuration${NC}"
echo -e "${BLUE}=========================================${NC}"
echo ""

# Base64 encode the kubeconfig
KUBECONFIG_BASE64=$(cat ~/.kube/config-vps | base64)

echo -e "${YELLOW}Add this to your GitHub repository secrets:${NC}"
echo ""
echo -e "${GREEN}Secret Name:${NC} KUBECONFIG"
echo -e "${GREEN}Secret Value:${NC}"
echo "$KUBECONFIG_BASE64"
echo ""

# Save to file for easy reference
echo "$KUBECONFIG_BASE64" > ~/.kube/kubeconfig-base64.txt

echo -e "${GREEN}✅ Also saved to: ~/.kube/kubeconfig-base64.txt${NC}"

#=========================================
# Setup Instructions
#=========================================
echo ""
echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}  Setup Complete! 🎉${NC}"
echo -e "${BLUE}=========================================${NC}"
echo ""
echo -e "${GREEN}✅ K3s cluster is now running on your VPS${NC}"
echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo ""
echo -e "1. Add KUBECONFIG secret to GitHub:"
echo -e "   ${BLUE}gh secret set KUBECONFIG < ~/.kube/kubeconfig-base64.txt${NC}"
echo ""
echo -e "2. Test local connection to cluster:"
echo -e "   ${BLUE}export KUBECONFIG=~/.kube/config-vps${NC}"
echo -e "   ${BLUE}kubectl get nodes${NC}"
echo ""
echo -e "3. Access deployed applications:"
echo -e "   ${BLUE}http://${VPS_IP}:30000-32767${NC} (NodePort range)"
echo ""
echo -e "4. Access Ingress (if configured):"
echo -e "   ${BLUE}http://${VPS_IP}:30080${NC} (HTTP)"
echo -e "   ${BLUE}https://${VPS_IP}:30443${NC} (HTTPS)"
echo ""
echo -e "${YELLOW}Quick Commands:${NC}"
echo -e "  ${BLUE}ssh ${VPS_USER}@${VPS_IP} 'kubectl get pods -A'${NC}"
echo -e "  ${BLUE}ssh ${VPS_USER}@${VPS_IP} 'kubectl get svc -A'${NC}"
echo -e "  ${BLUE}ssh ${VPS_USER}@${VPS_IP} 'kubectl logs -f <pod-name> -n <namespace>'${NC}"
echo ""
echo -e "${GREEN}Happy Kubernetes-ing! 🚀${NC}"

