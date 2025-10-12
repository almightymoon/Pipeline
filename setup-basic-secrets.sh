#!/bin/bash
# ===========================================================
# 🔐 Basic GitHub Secrets Setup
# ===========================================================

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

echo "=========================================="
echo "🔐 Basic GitHub Secrets Setup"
echo "=========================================="

# Check if GitHub CLI is installed
if ! command -v gh &> /dev/null; then
    print_error "GitHub CLI (gh) is not installed!"
    echo ""
    echo "Install it with:"
    echo "  macOS: brew install gh"
    echo "  Linux: curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg"
    echo ""
    echo "Then login with: gh auth login"
    exit 1
fi

# Check if user is logged in
if ! gh auth status &> /dev/null; then
    print_error "Not logged in to GitHub CLI!"
    echo ""
    echo "Login with: gh auth login"
    exit 1
fi

print_success "GitHub CLI is ready!"

# Get current repository
REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)
if [ -z "$REPO" ]; then
    print_error "Could not determine current repository!"
    exit 1
fi

print_status "Setting up basic secrets for repository: $REPO"

echo ""
echo "=========================================="
echo "🔧 Setting Up Basic Secrets"
echo "=========================================="

# Function to set secret
set_secret() {
    local name=$1
    local value=$2
    local description=$3
    
    print_status "Setting $name..."
    if echo "$value" | gh secret set "$name" --body -; then
        print_success "$name set successfully"
        echo "   📝 $description"
    else
        print_error "Failed to set $name"
        return 1
    fi
    echo ""
}

# 1. Basic secrets for simple pipeline
set_secret "HARBOR_USERNAME" "admin" "Harbor registry username"
set_secret "HARBOR_PASSWORD" "password" "Harbor registry password"
set_secret "SONARQUBE_URL" "http://213.109.162.134:9000" "SonarQube URL"
set_secret "SONARQUBE_TOKEN" "admin" "SonarQube token"
set_secret "VAULT_URL" "http://213.109.162.134:8200" "Vault URL"
set_secret "VAULT_TOKEN" "sample-vault-token" "Vault token"
set_secret "JIRA_URL" "https://faniqueprimus.atlassian.net" "Jira URL"
set_secret "JIRA_PROJECT_KEY" "KAN" "Jira project key"
set_secret "PROMETHEUS_PUSHGATEWAY_URL" "http://213.109.162.134:9091" "Prometheus URL"

# 2. Kubernetes config (optional)
print_status "Getting Kubernetes config..."
KUBECONFIG_BASE64=$(sshpass -p 'qwert1234' ssh -o StrictHostKeyChecking=no ubuntu@213.109.162.134 'kubectl config view --raw --minify | base64 -w 0' 2>/dev/null || echo "LS0tLS1CRUdJTiBZT1VSIEtVQkVSTkVURVMgQ09ORklHLS0tLS0K")
set_secret "KUBECONFIG" "$KUBECONFIG_BASE64" "Base64 encoded Kubernetes config"

echo "=========================================="
echo "✅ Basic Secrets Setup Complete!"
echo "=========================================="

echo ""
echo "📋 Summary of configured secrets:"
echo "   ✅ HARBOR_USERNAME / HARBOR_PASSWORD"
echo "   ✅ SONARQUBE_URL / SONARQUBE_TOKEN"
echo "   ✅ VAULT_URL / VAULT_TOKEN"
echo "   ✅ JIRA_URL / JIRA_PROJECT_KEY"
echo "   ✅ PROMETHEUS_PUSHGATEWAY_URL"
echo "   ✅ KUBECONFIG"

echo ""
echo "🚀 Next Steps:"
echo "1. Test the simple pipeline:"
echo "   git add ."
echo "   git commit -m 'Test simple pipeline'"
echo "   git push"

echo ""
echo "2. Monitor the pipeline:"
echo "   gh run list"
echo "   gh run view --log"

echo ""
echo "3. Check the services:"
echo "   - Grafana: http://213.109.162.134:30102"
echo "   - ArgoCD: http://213.109.162.134:32146"
echo "   - Jira: https://faniqueprimus.atlassian.net/browse/KAN"

echo ""
print_success "Your basic CI/CD pipeline is ready to test! 🎉"
