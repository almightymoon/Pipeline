#!/bin/bash
# ===========================================================
# Dynamic Dashboard Test Script
# Tests that the dashboard system works with any repository
# ===========================================================

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🧪 Testing Dynamic Dashboard System${NC}"
echo "====================================="

# Test repositories (different types to ensure dynamic behavior)
TEST_REPOS=(
    "https://github.com/tensorflow/tensorflow|tensorflow|main|full"
    "https://github.com/pytorch/pytorch|pytorch|main|full"
    "https://github.com/microsoft/vscode|vscode|main|security"
    "https://github.com/kubernetes/kubernetes|kubernetes|main|full"
    "https://github.com/docker/docker|docker|main|quality"
)

echo -e "${YELLOW}📋 Testing with different repository types...${NC}"

for repo_config in "${TEST_REPOS[@]}"; do
    IFS='|' read -r url name branch scan_type <<< "$repo_config"
    
    echo -e "\n${BLUE}Testing: $name${NC}"
    echo "URL: $url"
    echo "Branch: $branch"
    echo "Scan Type: $scan_type"
    
    # Create test repos-to-scan.yaml
    cat > repos-to-scan-test.yaml << EOF
repositories:
  - url: "$url"
    name: "$name"
    branch: "$branch"
    scan_type: "$scan_type"
EOF
    
    # Test dynamic dashboard creation
    if python3 scripts/create_dynamic_dashboard.py; then
        echo -e "${GREEN}✅ Dynamic dashboard created successfully for $name${NC}"
    else
        echo -e "${RED}❌ Failed to create dynamic dashboard for $name${NC}"
        exit 1
    fi
    
    # Test Jira issue creation
    if python3 scripts/create_jira_issue.py; then
        echo -e "${GREEN}✅ Jira issue created successfully for $name${NC}"
    else
        echo -e "${RED}❌ Failed to create Jira issue for $name${NC}"
        exit 1
    fi
    
    # Test metrics push
    if python3 scripts/push_real_metrics.py; then
        echo -e "${GREEN}✅ Metrics pushed successfully for $name${NC}"
    else
        echo -e "${RED}❌ Failed to push metrics for $name${NC}"
        exit 1
    fi
done

# Test with empty repository list
echo -e "\n${YELLOW}🧪 Testing with empty repository list...${NC}"
cat > repos-to-scan-test.yaml << EOF
repositories: []
EOF

if python3 scripts/create_dynamic_dashboard.py; then
    echo -e "${GREEN}✅ Handled empty repository list gracefully${NC}"
else
    echo -e "${RED}❌ Failed to handle empty repository list${NC}"
    exit 1
fi

# Test with malformed repository config
echo -e "\n${YELLOW}🧪 Testing with malformed repository config...${NC}"
cat > repos-to-scan-test.yaml << EOF
repositories:
  - url: "invalid-url"
    name: "test-repo"
    # Missing branch and scan_type
EOF

if python3 scripts/create_dynamic_dashboard.py; then
    echo -e "${GREEN}✅ Handled malformed config gracefully${NC}"
else
    echo -e "${RED}❌ Failed to handle malformed config${NC}"
    exit 1
fi

# Clean up test files
rm -f repos-to-scan-test.yaml

echo -e "\n${GREEN}🎉 All dynamic dashboard tests passed!${NC}"
echo -e "${BLUE}The system successfully works with any repository configuration.${NC}"

echo -e "\n${YELLOW}📊 Test Summary:${NC}"
echo "✅ Dynamic dashboard creation"
echo "✅ Jira issue creation"
echo "✅ Metrics pushing"
echo "✅ Error handling"
echo "✅ Repository flexibility"

echo -e "\n${GREEN}✅ Dynamic Dashboard System is working correctly!${NC}"
