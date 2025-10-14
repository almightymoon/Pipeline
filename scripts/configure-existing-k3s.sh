#!/bin/bash

#=========================================
# Configure Existing K3s for GitHub Actions
#=========================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

VPS_IP="${VPS_IP:-213.109.162.134}"
VPS_USER="${VPS_USER:-ubuntu}"

echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}  K3s GitHub Actions Configuration${NC}"
echo -e "${BLUE}=========================================${NC}"
echo ""
echo -e "${YELLOW}VPS IP:${NC} $VPS_IP"
echo -e "${YELLOW}User:${NC} $VPS_USER"
echo ""

#=========================================
# Step 1: Create pipeline-apps namespace
#=========================================
echo -e "${GREEN}[1/4] Creating pipeline-apps namespace...${NC}"

ssh ${VPS_USER}@${VPS_IP} << 'ENDSSH'
    # Create namespace if it doesn't exist
    kubectl create namespace pipeline-apps --dry-run=client -o yaml | kubectl apply -f -
    
    # Label the namespace
    kubectl label namespace pipeline-apps environment=production --overwrite
    
    echo "✅ Namespace pipeline-apps ready"
    
    # Show current namespaces
    echo ""
    echo "📁 Available Namespaces:"
    kubectl get namespaces
ENDSSH

#=========================================
# Step 2: Download kubeconfig
#=========================================
echo ""
echo -e "${GREEN}[2/4] Downloading kubeconfig...${NC}"

# Create local .kube directory
mkdir -p ~/.kube

# Download kubeconfig from VPS
scp ${VPS_USER}@${VPS_IP}:/etc/rancher/k3s/k3s.yaml ~/.kube/config-vps

# Update server address (macOS)
if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' "s/127.0.0.1/${VPS_IP}/g" ~/.kube/config-vps
else
    sed -i "s/127.0.0.1/${VPS_IP}/g" ~/.kube/config-vps
fi

echo -e "${GREEN}✅ Kubeconfig downloaded to ~/.kube/config-vps${NC}"

#=========================================
# Step 3: Test connection
#=========================================
echo ""
echo -e "${GREEN}[3/4] Testing cluster connection...${NC}"

export KUBECONFIG=~/.kube/config-vps

echo ""
echo "🔍 Cluster Info:"
kubectl cluster-info

echo ""
echo "🖥️  Nodes:"
kubectl get nodes

echo ""
echo "📦 Namespaces:"
kubectl get namespaces | grep -E "NAME|pipeline|monitoring|ml-production"

echo ""
echo -e "${GREEN}✅ Connection successful!${NC}"

#=========================================
# Step 4: Generate GitHub Secret
#=========================================
echo ""
echo -e "${GREEN}[4/4] Generating GitHub Secret...${NC}"

# Base64 encode the kubeconfig
KUBECONFIG_BASE64=$(cat ~/.kube/config-vps | base64)

# Save to file
echo "$KUBECONFIG_BASE64" > ~/.kube/kubeconfig-base64.txt

echo -e "${GREEN}✅ Secret generated and saved to ~/.kube/kubeconfig-base64.txt${NC}"

#=========================================
# Display Summary
#=========================================
echo ""
echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}  Configuration Complete! 🎉${NC}"
echo -e "${BLUE}=========================================${NC}"
echo ""

echo -e "${YELLOW}📋 Cluster Status:${NC}"
echo -e "  • K3s Version: $(kubectl version --short 2>/dev/null | grep Server | awk '{print $3}')"
echo -e "  • Nodes: $(kubectl get nodes --no-headers | wc -l | tr -d ' ')"
echo -e "  • Namespaces: $(kubectl get namespaces --no-headers | wc -l | tr -d ' ')"
echo -e "  • Pods Running: $(kubectl get pods -A --field-selector=status.phase=Running --no-headers | wc -l | tr -d ' ')"
echo ""

echo -e "${YELLOW}🔗 Important Services:${NC}"
echo -e "  • Grafana: http://${VPS_IP}:30102 (admin/admin123)"
echo -e "  • ArgoCD: http://${VPS_IP}:32146"
echo -e "  • Traefik: http://${VPS_IP}:80"
echo ""

echo -e "${YELLOW}📊 Available Namespaces:${NC}"
kubectl get namespaces | grep -v "NAME" | awk '{printf "  • %s\n", $1}'
echo ""

echo -e "${YELLOW}🚀 Next Steps:${NC}"
echo ""
echo -e "1. ${BLUE}Add KUBECONFIG secret to GitHub:${NC}"
echo -e "   ${GREEN}gh secret set KUBECONFIG < ~/.kube/kubeconfig-base64.txt${NC}"
echo ""
echo -e "2. ${BLUE}Verify the secret was added:${NC}"
echo -e "   ${GREEN}gh secret list${NC}"
echo ""
echo -e "3. ${BLUE}Test deployment with a workflow:${NC}"
echo -e "   ${GREEN}gh workflow run scan-external-repos.yml${NC}"
echo ""
echo -e "4. ${BLUE}Monitor deployments:${NC}"
echo -e "   ${GREEN}kubectl get pods -n pipeline-apps -w${NC}"
echo ""
echo -e "5. ${BLUE}View deployed services:${NC}"
echo -e "   ${GREEN}kubectl get svc -n pipeline-apps${NC}"
echo ""

echo -e "${YELLOW}💡 Quick Commands:${NC}"
echo -e "  ${BLUE}# Use this config locally${NC}"
echo -e "  export KUBECONFIG=~/.kube/config-vps"
echo ""
echo -e "  ${BLUE}# Check cluster${NC}"
echo -e "  kubectl get nodes"
echo ""
echo -e "  ${BLUE}# Watch pipeline deployments${NC}"
echo -e "  kubectl get pods -n pipeline-apps -w"
echo ""
echo -e "  ${BLUE}# View logs${NC}"
echo -e "  kubectl logs -f <pod-name> -n pipeline-apps"
echo ""
echo -e "  ${BLUE}# Delete a deployment${NC}"
echo -e "  kubectl delete deployment <name> -n pipeline-apps"
echo ""

echo -e "${GREEN}=========================================${NC}"
echo -e "${GREEN}  Ready to Deploy! 🚀${NC}"
echo -e "${GREEN}=========================================${NC}"

