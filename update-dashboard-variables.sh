#!/bin/bash

echo "========================================="
echo "Updating Dashboard Template Variables"
echo "========================================="

# Grafana credentials
GRAFANA_URL="http://213.109.162.134:30102"
GRAFANA_USER="admin"
GRAFANA_PASS="admin123"

# Dashboard file
DASHBOARD_FILE="monitoring/real-data-dashboard.json"

echo "Updating dashboard template variables for pfbd-project..."
curl -X POST \
  -H "Content-Type: application/json" \
  -H "Authorization: Basic $(echo -n $GRAFANA_USER:$GRAFANA_PASS | base64)" \
  -d @"$DASHBOARD_FILE" \
  "$GRAFANA_URL/api/dashboards/db"

echo ""
echo "========================================="
echo "Dashboard Variables Updated!"
echo "========================================="
echo "Dashboard now configured for:"
echo "✅ Repository: pfbd-project"
echo "✅ URL: https://github.com/OzJasonGit/PFBD"
echo "✅ Branch: main"
echo "✅ Scan Type: full"
echo ""
echo "Dashboard URL: $GRAFANA_URL/d/9f0568b8-30a1-4306-ae44-f2f05a7c90d2/pipeline-dashboard-real-data"
echo ""
echo "The dashboard should now show data for the PFBD repository instead of tensorflow!"
