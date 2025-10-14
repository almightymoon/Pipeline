#!/bin/bash

echo "========================================="
echo "Updating Dashboard for Current Repository"
echo "========================================="

# Grafana API details
GRAFANA_URL="http://213.109.162.134:30102"
GRAFANA_USER="admin"
GRAFANA_PASS="admin123"
DASHBOARD_UID="47428692-d8b7-4633-8990-23fa4e2b4049"

# Read current repository from repos-to-scan.yaml
if [ -f "repos-to-scan.yaml" ]; then
    REPO_URL=$(grep -A 20 "repositories:" repos-to-scan.yaml | grep "^\s*- url:" | head -1 | sed 's/.*url: //' | tr -d ' ')
    REPO_NAME=$(grep -A 20 "repositories:" repos-to-scan.yaml | grep "^\s*name:" | head -1 | sed 's/.*name: //' | tr -d ' ')
else
    echo "Error: repos-to-scan.yaml not found."
    exit 1
fi

echo "Repository: $REPO_NAME"
echo "URL: $REPO_URL"

# Get current dashboard
echo "Fetching current dashboard..."
DASHBOARD_JSON=$(curl -s -X GET \
  -H "Content-Type: application/json" \
  -u "$GRAFANA_USER:$GRAFANA_PASS" \
  "$GRAFANA_URL/api/dashboards/uid/$DASHBOARD_UID" | jq '.dashboard')

# Update template variables with current repository
echo "Updating template variables..."
UPDATED_DASHBOARD=$(echo "$DASHBOARD_JSON" | jq --arg repo_name "$REPO_NAME" '
    .templating.list[0].current.text = $repo_name |
    .templating.list[0].current.value = $repo_name
')

# Prepare the payload for Grafana API
PAYLOAD=$(jq -n --argjson dashboard "$UPDATED_DASHBOARD" '{
  "dashboard": $dashboard,
  "folderId": 0,
  "overwrite": true
}')

echo "Updating dashboard template variables..."
RESPONSE=$(curl -s -X POST \
  -H "Content-Type: application/json" \
  -u "$GRAFANA_USER:$GRAFANA_PASS" \
  "$GRAFANA_URL/api/dashboards/db" \
  -d "$PAYLOAD")

echo "Response: $RESPONSE"

# Check if successful
if echo "$RESPONSE" | jq -e '.uid' > /dev/null; then
    echo ""
    echo "========================================="
    echo "Dashboard Updated Successfully!"
    echo "========================================="
    echo "Dashboard now shows data for: $REPO_NAME"
    echo "Dashboard URL: http://213.109.162.134:30102/d/47428692-d8b7-4633-8990-23fa4e2b4049/dynamic-pipeline-dashboard-real-data"
    echo ""
    echo "The dashboard will now pull real data for $REPO_NAME when you run the pipeline!"
else
    echo ""
    echo "========================================="
    echo "Error: Failed to update dashboard."
    echo "========================================="
    echo "Response: $RESPONSE"
    exit 1
fi
