#!/bin/bash

# Deploy Enhanced Professional SonarQube Dashboard to Grafana
# This script deploys the enhanced dashboard with testing features

set -e

echo "🚀 Deploying Enhanced Professional SonarQube Dashboard to Grafana"
echo "================================================================"
echo ""

# Configuration
GRAFANA_URL="http://213.109.162.134:30102"
GRAFANA_USER="admin"
GRAFANA_PASSWORD="admin123"
DASHBOARD_FILE="monitoring/enhanced-professional-dashboard.json"

# Step 1: Check Grafana connectivity
echo "🔍 Step 1: Checking Grafana connectivity..."
if curl -s -f -u "${GRAFANA_USER}:${GRAFANA_PASSWORD}" "${GRAFANA_URL}/api/health" > /dev/null; then
    echo "✅ Grafana is accessible at ${GRAFANA_URL}"
else
    echo "❌ Cannot connect to Grafana at ${GRAFANA_URL}"
    exit 1
fi

# Step 2: Check dashboard file
echo ""
echo "📁 Step 2: Checking dashboard file..."
if [ -f "$DASHBOARD_FILE" ]; then
    echo "✅ Dashboard file found: $DASHBOARD_FILE"
else
    echo "❌ Dashboard file not found: $DASHBOARD_FILE"
    exit 1
fi

# Step 3: Prepare dashboard payload
echo ""
echo "📦 Step 3: Preparing dashboard payload..."
DASHBOARD_JSON=$(cat "$DASHBOARD_FILE")
DASHBOARD_PAYLOAD=$(jq -n --argjson dashboard "$DASHBOARD_JSON" '{dashboard: $dashboard, folderId: 0, overwrite: true}')
echo "✅ Dashboard payload prepared"

# Step 4: Deploy dashboard to Grafana
echo ""
echo "🚀 Step 4: Deploying enhanced dashboard to Grafana..."
echo ""

RESPONSE=$(curl -s -X POST \
    -H "Content-Type: application/json" \
    -u "${GRAFANA_USER}:${GRAFANA_PASSWORD}" \
    -d "$DASHBOARD_PAYLOAD" \
    "${GRAFANA_URL}/api/dashboards/db")

echo "📋 Response from Grafana:"
echo "$RESPONSE" | jq '.'

# Check if deployment was successful
if echo "$RESPONSE" | jq -e '.status == "success"' > /dev/null; then
    echo ""
    echo "=========================================="
    echo "✅ ENHANCED DASHBOARD DEPLOYED SUCCESSFULLY!"
    echo "=========================================="
    echo ""
    
    DASHBOARD_URL=$(echo "$RESPONSE" | jq -r '.url')
    DASHBOARD_ID=$(echo "$RESPONSE" | jq -r '.id')
    DASHBOARD_UID=$(echo "$RESPONSE" | jq -r '.uid')
    
    echo "📊 Dashboard Details:"
    echo "   • Title: 🚀 ML Pipeline - Enhanced Professional Dashboard"
    echo "   • UID: $DASHBOARD_UID"
    echo "   • ID: $DASHBOARD_ID"
    echo "   • URL: ${GRAFANA_URL}${DASHBOARD_URL}"
    echo ""
    echo "🔗 Quick Links:"
    echo "   • Dashboard: ${GRAFANA_URL}${DASHBOARD_URL}"
    echo "   • Grafana Home: ${GRAFANA_URL}"
    echo "   • SonarQube: http://213.109.162.134:30100"
    echo "   • Prometheus: http://213.109.162.134:30090"
    echo ""
    echo "🎨 NEW FEATURES:"
    echo "   ✅ Detailed Critical Issues List (24-column wide)"
    echo "   ✅ Comprehensive Testing Results section"
    echo "   ✅ Performance metrics panels"
    echo "   ✅ Secret detection results"
    echo "   ✅ Clickable tables with drill-down"
    echo "   ✅ Real-time updates every 30 seconds"
    echo ""
    echo "🎉 Enhanced dashboard deployed with all testing features!"
    
else
    echo ""
    echo "❌ Dashboard deployment failed!"
    echo "Response: $RESPONSE"
    exit 1
fi
