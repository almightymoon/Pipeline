#!/bin/bash

echo "========================================="
echo "Repository Change & Dashboard Update Tool"
echo "========================================="

echo "Current repository in repos-to-scan.yaml:"
echo "----------------------------------------"
grep -A 5 "repositories:" repos-to-scan.yaml | grep -E "(url:|name:|branch:|scan_type:)" | grep -v "^#"

echo ""
echo "To change repository and update dashboard:"
echo "1. Edit repos-to-scan.yaml with your new repository"
echo "2. Run this script: ./change-repo-and-update-dashboard.sh"
echo "3. Dashboard will update automatically!"
echo ""

# Check if repos-to-scan.yaml exists
if [ ! -f "repos-to-scan.yaml" ]; then
    echo "❌ repos-to-scan.yaml not found!"
    exit 1
fi

# Read current repository
REPO_URL=$(grep -A 20 "repositories:" repos-to-scan.yaml | grep "^\s*- url:" | head -1 | sed 's/.*url: //' | tr -d ' ')
REPO_NAME=$(grep -A 20 "repositories:" repos-to-scan.yaml | grep "^\s*name:" | head -1 | sed 's/.*name: //' | tr -d ' ')
REPO_BRANCH=$(grep -A 20 "repositories:" repos-to-scan.yaml | grep "^\s*branch:" | head -1 | sed 's/.*branch: //' | tr -d ' ')
SCAN_TYPE=$(grep -A 20 "repositories:" repos-to-scan.yaml | grep "^\s*scan_type:" | head -1 | sed 's/.*scan_type: //' | tr -d ' ')

echo "📊 Current Repository:"
echo "   Name: $REPO_NAME"
echo "   URL: $REPO_URL"
echo "   Branch: $REPO_BRANCH"
echo "   Scan Type: $SCAN_TYPE"
echo ""

# Update dashboard
echo "🔄 Updating dashboard..."
./update-dashboard-content.sh

echo ""
echo "🎉 Dashboard updated successfully!"
echo ""
echo "📋 Next steps:"
echo "1. Check the dashboard: http://213.109.162.134:30102/d/current-repo/pipeline-dashboard-current-repository"
echo "2. Run pipeline: git add . && git commit -m \"Update repository to $REPO_NAME\" && git push"
echo "3. New Jira issue will be created with $REPO_NAME details"
echo ""
echo "✨ The dashboard now shows data for: $REPO_NAME"
