#!/bin/bash
# ===========================================================
# Fix SonarQube Token - Update GitHub Secret
# ===========================================================

echo "🔧 Fixing SonarQube Authentication Issue"
echo "========================================="
echo ""

# New working token
NEW_TOKEN="sqa_0e2b69f31a838ecd2a4576b94f5928eecfab37c5"

# Check if GitHub CLI is installed
if ! command -v gh &> /dev/null; then
    echo "❌ GitHub CLI (gh) is not installed"
    echo ""
    echo "Please update the secret manually:"
    echo "1. Go to: https://github.com/almightymoon/Pipeline/settings/secrets/actions"
    echo "2. Click on SONARQUBE_TOKEN"
    echo "3. Update the value to: $NEW_TOKEN"
    exit 1
fi

# Check if logged in
if ! gh auth status &> /dev/null; then
    echo "❌ Not logged in to GitHub CLI"
    echo ""
    echo "Run: gh auth login"
    echo ""
    echo "Or update manually at:"
    echo "https://github.com/almightymoon/Pipeline/settings/secrets/actions"
    exit 1
fi

echo "✅ GitHub CLI is ready"
echo ""

# Ask for repository
read -p "Enter your repository (e.g., almightymoon/Pipeline): " REPO

if [ -z "$REPO" ]; then
    REPO="almightymoon/Pipeline"
    echo "Using default: $REPO"
fi

echo ""
echo "🔄 Updating SONARQUBE_TOKEN secret..."

# Update the secret
if gh secret set SONARQUBE_TOKEN --repo "$REPO" --body "$NEW_TOKEN"; then
    echo ""
    echo "✅ SUCCESS! SonarQube token updated"
    echo ""
    echo "📋 Changes made:"
    echo "   • Fixed: Changed from 'sonar.login' to 'sonar.token'"
    echo "   • Updated: GitHub secret SONARQUBE_TOKEN"
    echo "   • Token: $NEW_TOKEN"
    echo ""
    echo "🚀 Next steps:"
    echo "   1. Commit the workflow changes:"
    echo "      git add .github/workflows/scan-external-repos.yml"
    echo "      git commit -m 'Fix SonarQube authentication (sonar.token)'"
    echo "      git push"
    echo ""
    echo "   2. Trigger a new scan:"
    echo "      • Push a change to repos-to-scan.yaml, or"
    echo "      • Run: gh workflow run 'scan-external-repos.yml'"
    echo ""
    echo "   3. Monitor: gh run watch"
    echo ""
    echo "✅ The project will now appear in SonarQube after successful scan!"
else
    echo ""
    echo "❌ Failed to update secret"
    echo ""
    echo "Please update manually:"
    echo "1. Go to: https://github.com/$REPO/settings/secrets/actions"
    echo "2. Click on SONARQUBE_TOKEN"
    echo "3. Update the value to: $NEW_TOKEN"
fi

