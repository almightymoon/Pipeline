#!/bin/bash
# ===========================================================
# Automated GitHub Secrets Setup Script
# ===========================================================

set -e

echo "🔐 GitHub Secrets Setup Script"
echo "================================"
echo ""

# Check if GitHub CLI is installed
if ! command -v gh &> /dev/null; then
    echo "❌ GitHub CLI (gh) is not installed"
    echo ""
    echo "Install it with:"
    echo "  macOS:  brew install gh"
    echo "  Linux:  See https://cli.github.com/manual/installation"
    exit 1
fi

# Check if logged in
if ! gh auth status &> /dev/null; then
    echo "❌ Not logged in to GitHub CLI"
    echo ""
    echo "Please run: gh auth login"
    exit 1
fi

echo "✅ GitHub CLI is installed and authenticated"
echo ""

# Ask for repository name
echo "📦 Which repository do you want to configure?"
echo "   (e.g., almightymoon/Pipeline)"
read -p "Repository (owner/repo): " REPO

if [ -z "$REPO" ]; then
    echo "❌ Repository name is required"
    exit 1
fi

echo ""
echo "🔧 Setting up secrets for repository: $REPO"
echo ""

# Set SonarQube secrets
echo "📊 Setting SonarQube secrets..."
gh secret set SONARQUBE_URL --repo "$REPO" --body "http://213.109.162.134:30100"
gh secret set SONARQUBE_TOKEN --repo "$REPO" --body "sqa_5d9aed525cdd3421964d6475f57a725da8fccdb1"
gh secret set SONARQUBE_ORG --repo "$REPO" --body "default-organization"
echo "   ✅ SonarQube configured"

# Set Prometheus secrets
echo "📈 Setting Prometheus secrets..."
gh secret set PROMETHEUS_PUSHGATEWAY_URL --repo "$REPO" --body "http://213.109.162.134:30091"
echo "   ✅ Prometheus configured"

# Set Grafana secrets
echo "📊 Setting Grafana secrets..."
gh secret set GRAFANA_URL --repo "$REPO" --body "http://213.109.162.134:30102"
gh secret set GRAFANA_USERNAME --repo "$REPO" --body "admin"
gh secret set GRAFANA_PASSWORD --repo "$REPO" --body "admin123"
echo "   ✅ Grafana configured"

# Set Jira secrets
echo "📝 Setting Jira secrets..."
read -p "Do you want to configure Jira? (y/n): " SETUP_JIRA
if [ "$SETUP_JIRA" = "y" ] || [ "$SETUP_JIRA" = "Y" ]; then
    read -p "Jira URL (e.g., https://yourcompany.atlassian.net): " JIRA_URL
    read -p "Jira Email: " JIRA_EMAIL
    read -p "Jira API Token: " JIRA_TOKEN
    read -p "Jira Project Key (e.g., KAN): " JIRA_KEY
    
    gh secret set JIRA_URL --repo "$REPO" --body "$JIRA_URL"
    gh secret set JIRA_EMAIL --repo "$REPO" --body "$JIRA_EMAIL"
    gh secret set JIRA_API_TOKEN --repo "$REPO" --body "$JIRA_TOKEN"
    gh secret set JIRA_PROJECT_KEY --repo "$REPO" --body "$JIRA_KEY"
    echo "   ✅ Jira configured"
else
    echo "   ⏭️  Skipping Jira configuration"
fi

# Get Kubernetes config
echo ""
echo "☸️  Getting Kubernetes configuration..."
read -p "Do you want to set KUBECONFIG secret? (y/n): " SETUP_KUBE
if [ "$SETUP_KUBE" = "y" ] || [ "$SETUP_KUBE" = "Y" ]; then
    DEFAULT_VPS_USER=${SSH_USER:-ubuntu}
    DEFAULT_VPS_HOST=${SSH_HOST:-213.109.162.134}
    DEFAULT_SSH_KEY_PATH=${SSH_KEY_PATH:-$HOME/EdDSA-channel-3.pem}

    read -p "SSH username [$DEFAULT_VPS_USER]: " INPUT_VPS_USER
    VPS_USER=${INPUT_VPS_USER:-$DEFAULT_VPS_USER}

    read -p "VPS host [$DEFAULT_VPS_HOST]: " INPUT_VPS_HOST
    VPS_HOST=${INPUT_VPS_HOST:-$DEFAULT_VPS_HOST}

    read -p "Path to SSH private key [$DEFAULT_SSH_KEY_PATH]: " INPUT_SSH_KEY
    SSH_KEY_PATH=${INPUT_SSH_KEY:-$DEFAULT_SSH_KEY_PATH}

    if [ ! -f "$SSH_KEY_PATH" ]; then
        echo "   ❌ SSH key not found at $SSH_KEY_PATH"
    else
        echo "   Connecting to server with key authentication..."
        KUBECONFIG_BASE64=$(ssh -i "$SSH_KEY_PATH" -o StrictHostKeyChecking=no -o IdentitiesOnly=yes "$VPS_USER@$VPS_HOST" 'kubectl config view --raw --minify | base64 -w 0' 2>/dev/null)

        if [ -n "$KUBECONFIG_BASE64" ]; then
            echo "$KUBECONFIG_BASE64" | gh secret set KUBECONFIG --repo "$REPO"
            echo "   ✅ Kubernetes config set"
        else
            echo "   ❌ Failed to get Kubernetes config"
            echo "      Verify the key path, passphrase, and remote permissions."
        fi
    fi
else
    echo "   ⏭️  Skipping Kubernetes configuration"
fi

echo ""
echo "================================================"
echo "✅ GitHub Secrets Setup Complete!"
echo "================================================"
echo ""
echo "📋 Configured secrets:"
echo "   • SONARQUBE_URL"
echo "   • SONARQUBE_TOKEN"
echo "   • SONARQUBE_ORG"
echo "   • PROMETHEUS_PUSHGATEWAY_URL"
echo "   • GRAFANA_URL"
echo "   • GRAFANA_USERNAME"
echo "   • GRAFANA_PASSWORD"
if [ "$SETUP_JIRA" = "y" ] || [ "$SETUP_JIRA" = "Y" ]; then
    echo "   • JIRA_URL"
    echo "   • JIRA_EMAIL"
    echo "   • JIRA_API_TOKEN"
    echo "   • JIRA_PROJECT_KEY"
fi
if [ "$SETUP_KUBE" = "y" ] || [ "$SETUP_KUBE" = "Y" ]; then
    echo "   • KUBECONFIG"
fi
echo ""
echo "🚀 Next Steps:"
echo "   1. Verify secrets: gh secret list --repo $REPO"
echo "   2. Test the pipeline by pushing to your repo"
echo "   3. Monitor results at:"
echo "      - SonarQube: http://213.109.162.134:30100"
echo "      - Grafana:   http://213.109.162.134:30102"
echo "      - Prometheus: http://213.109.162.134:30090"
echo ""

