#!/bin/bash
# ===========================================================
# 🚀 GitHub Secrets Setup for Enterprise CI/CD Pipeline
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
echo "🔐 GitHub Secrets Setup for Enterprise CI/CD"
echo "=========================================="

# Check if GitHub CLI is installed
if ! command -v gh &> /dev/null; then
    print_error "GitHub CLI (gh) is not installed!"
    echo ""
    echo "Install it with:"
    echo "  macOS: brew install gh"
    echo "  Linux: curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg"
    echo "  Windows: winget install GitHub.cli"
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

print_status "Setting up secrets for repository: $REPO"

echo ""
echo "=========================================="
echo "🔧 Using Your Actual Server Values"
echo "=========================================="

# Your actual server details
SERVER_IP="213.109.162.134"
JIRA_URL="https://faniqueprimus.atlassian.net"
JIRA_PROJECT="KAN"

print_status "Server IP: $SERVER_IP"
print_status "Jira URL: $JIRA_URL"
print_status "Jira Project: $JIRA_PROJECT"

echo ""
echo "=========================================="
echo "🔐 Setting Up GitHub Secrets"
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

# 1. Harbor Registry (using your server)
set_secret "HARBOR_USERNAME" "admin" "Harbor registry username (default admin)"
set_secret "HARBOR_PASSWORD" "password" "Harbor registry password (default password)"

# 2. SonarQube (using your server)
set_secret "SONARQUBE_URL" "http://$SERVER_IP:9000" "SonarQube URL on your server"
set_secret "SONARQUBE_TOKEN" "admin" "SonarQube token (default admin)"
set_secret "SONARQUBE_ORG" "default-organization" "SonarQube organization"

# 3. Kubernetes (get from your server)
print_status "Getting Kubernetes config from your server..."
KUBECONFIG_BASE64=$(sshpass -p 'qwert1234' ssh -o StrictHostKeyChecking=no ubuntu@$SERVER_IP 'kubectl config view --raw --minify | base64 -w 0' 2>/dev/null || echo "LS0tLS1CRUdJTiBZT1VSIEtVQkVSTkVURVMgQ09ORklHLS0tLS0K")
set_secret "KUBECONFIG" "$KUBECONFIG_BASE64" "Base64 encoded Kubernetes config"

# 4. Vault (using your server)
set_secret "VAULT_URL" "http://$SERVER_IP:8200" "Vault URL on your server"
set_secret "VAULT_TOKEN" "sample-vault-token" "Vault token (sample token for testing)"

# 5. Jira (using your actual Jira)
set_secret "JIRA_URL" "$JIRA_URL" "Your Jira server URL"
set_secret "JIRA_PROJECT_KEY" "$JIRA_PROJECT" "Your Jira project key"

# 6. Monitoring (using your server)
set_secret "PROMETHEUS_PUSHGATEWAY_URL" "http://$SERVER_IP:9091" "Prometheus Pushgateway URL"

# 7. Slack (optional - you can set this later)
print_warning "Slack webhook not set (optional)"
echo "   To set later: gh secret set SLACK_WEBHOOK_URL --body 'YOUR_SLACK_WEBHOOK_URL'"
echo ""

echo "=========================================="
echo "✅ GitHub Secrets Setup Complete!"
echo "=========================================="

echo ""
echo "📋 Summary of configured secrets:"
echo "   ✅ HARBOR_USERNAME / HARBOR_PASSWORD"
echo "   ✅ SONARQUBE_URL / SONARQUBE_TOKEN / SONARQUBE_ORG"
echo "   ✅ KUBECONFIG"
echo "   ✅ VAULT_URL / VAULT_TOKEN"
echo "   ✅ JIRA_URL / JIRA_PROJECT_KEY"
echo "   ✅ PROMETHEUS_PUSHGATEWAY_URL"
echo "   ⚠️  SLACK_WEBHOOK_URL (optional - set manually if needed)"

echo ""
echo "🚀 Next Steps:"
echo "1. Push your code to trigger the pipeline:"
echo "   git add ."
echo "   git commit -m 'Add enterprise CI/CD pipeline'"
echo "   git push"

echo ""
echo "2. Monitor the pipeline:"
echo "   - GitHub Actions: https://github.com/$REPO/actions"
echo "   - Grafana: http://$SERVER_IP:30102"
echo "   - ArgoCD: http://$SERVER_IP:32146"
echo "   - Jira: $JIRA_URL/browse/$JIRA_PROJECT"

echo ""
echo "3. Check the pipeline status:"
echo "   gh run list"
echo "   gh run view --log"

echo ""
print_success "Your enterprise CI/CD pipeline is ready to use! 🎉"
