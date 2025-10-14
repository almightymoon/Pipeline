#!/bin/bash

echo "========================================="
echo "Deploying Dynamic Real Data Dashboard"
echo "========================================="

# Grafana API details
GRAFANA_URL="http://213.109.162.134:30102"
GRAFANA_USER="admin"
GRAFANA_PASS="admin123"

# Read current repository from repos-to-scan.yaml
if [ -f "repos-to-scan.yaml" ]; then
    REPO_URL=$(grep -A 20 "repositories:" repos-to-scan.yaml | grep "^\s*- url:" | head -1 | sed 's/.*url: //' | tr -d ' ')
    REPO_NAME=$(grep -A 20 "repositories:" repos-to-scan.yaml | grep "^\s*name:" | head -1 | sed 's/.*name: //' | tr -d ' ')
    REPO_BRANCH=$(grep -A 20 "repositories:" repos-to-scan.yaml | grep "^\s*branch:" | head -1 | sed 's/.*branch: //' | tr -d ' ')
else
    echo "Error: repos-to-scan.yaml not found."
    exit 1
fi

echo "Repository: $REPO_NAME"
echo "URL: $REPO_URL"

# Load the dashboard JSON template
DASHBOARD_JSON=$(cat monitoring/dynamic-real-data-dashboard.json)

# Replace placeholders in the dashboard JSON with current repository info
DASHBOARD_JSON=$(echo "$DASHBOARD_JSON" | sed "s/{{repository}}/$REPO_NAME/g")
DASHBOARD_JSON=$(echo "$DASHBOARD_JSON" | sed "s|{{now}}|$(date)|g")

# Update template variables with current repository
DASHBOARD_JSON=$(echo "$DASHBOARD_JSON" | jq --arg repo_name "$REPO_NAME" --arg repo_url "$REPO_URL" '
    .dashboard.templating.list[0].current.text = $repo_name |
    .dashboard.templating.list[0].current.value = $repo_name |
    .dashboard.templating.list[1].query = $repo_url |
    .dashboard.templating.list[1].current.text = $repo_url
')

# Debug: Check if title is still there
echo "Debug: Dashboard title after processing:"
echo "$DASHBOARD_JSON" | jq '.dashboard.title'

# Prepare the payload for Grafana API using jq to ensure proper JSON structure
PAYLOAD=$(jq -n --argjson dashboard "$DASHBOARD_JSON" '{
  "dashboard": $dashboard,
  "folderId": 0,
  "overwrite": true
}')

# Debug: Check the final payload structure
echo "Debug: Final payload structure:"
echo "$PAYLOAD" | jq '.dashboard.title'

echo "Importing dynamic real data dashboard..."
RESPONSE=$(curl -s -X POST \
  -H "Content-Type: application/json" \
  -u "$GRAFANA_USER:$GRAFANA_PASS" \
  "$GRAFANA_URL/api/dashboards/db" \
  -d "$PAYLOAD")

echo "Response: $RESPONSE"

# Extract UID and URL from the response
DASHBOARD_UID=$(echo "$RESPONSE" | jq -r '.uid')
DASHBOARD_SLUG=$(echo "$RESPONSE" | jq -r '.slug')
DASHBOARD_ID=$(echo "$RESPONSE" | jq -r '.id')

if [ "$DASHBOARD_UID" != "null" ] && [ "$DASHBOARD_SLUG" != "null" ]; then
    DASHBOARD_FINAL_URL="${GRAFANA_URL}/d/${DASHBOARD_UID}/${DASHBOARD_SLUG}"
    echo ""
    echo "========================================="
    echo "Dynamic Dashboard Created Successfully!"
    echo "========================================="
    echo "Dashboard URL: $DASHBOARD_FINAL_URL"
    echo "UID: $DASHBOARD_UID"
    echo ""
    echo "This dashboard will:"
    echo "✅ Pull REAL data from Prometheus metrics"
    echo "✅ Update automatically when repository changes"
    echo "✅ Show actual pipeline run data for: $REPO_NAME"
    echo "✅ Display real security vulnerabilities"
    echo "✅ Show real code quality metrics"
    echo "✅ Display actual test results"
    echo ""
    echo "To get real data, run the pipeline for $REPO_NAME:"
    echo "git add . && git commit -m 'Run pipeline for $REPO_NAME' && git push"
else
    echo ""
    echo "========================================="
    echo "Error: Failed to create dashboard."
    echo "========================================="
    echo "Please check Grafana logs and API response for details."
    echo "Response: $RESPONSE"
    exit 1
fi
