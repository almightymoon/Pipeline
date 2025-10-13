#!/bin/bash

echo "========================================="
echo "Deploying Real Data Dashboard"
echo "========================================="

# Grafana credentials
GRAFANA_URL="http://213.109.162.134:30102"
GRAFANA_USER="admin"
GRAFANA_PASS="admin123"

# Dashboard file
DASHBOARD_FILE="monitoring/real-data-dashboard.json"

echo "Deleting old dashboard..."
curl -X DELETE \
  -H "Content-Type: application/json" \
  -H "Authorization: Basic $(echo -n $GRAFANA_USER:$GRAFANA_PASS | base64)" \
  "$GRAFANA_URL/api/dashboards/uid/69bcd2b5-88d9-47e6-84af-c5f2e45f23cc" 2>/dev/null || echo "Old dashboard not found"

echo "Importing real data dashboard..."
curl -X POST \
  -H "Content-Type: application/json" \
  -H "Authorization: Basic $(echo -n $GRAFANA_USER:$GRAFANA_PASS | base64)" \
  -d @"$DASHBOARD_FILE" \
  "$GRAFANA_URL/api/dashboards/db"

echo ""
echo "========================================="
echo "Real Data Dashboard Deployed!"
echo "========================================="
echo "Dashboard URL: $GRAFANA_URL/d/real-data/pipeline-dashboard-real-data"
echo ""
echo "This dashboard now shows:"
echo "✅ Real pipeline run counts from GitHub Actions API"
echo "✅ Actual test results from your pipeline runs"
echo "✅ Live code quality metrics from scans"
echo "✅ Real-time security scan results"
echo "✅ Dynamic repository information"
echo "✅ Pipeline run history timeline"
echo "✅ Recent pipeline runs table"
echo ""
echo "The dashboard will update automatically as your pipelines run!"
