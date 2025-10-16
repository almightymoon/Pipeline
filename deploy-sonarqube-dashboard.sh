#!/bin/bash
# ===========================================================
# Deploy SonarQube Metrics Dashboard to Grafana
# ===========================================================

echo "📊 Deploying SonarQube Metrics Dashboard to Grafana"
echo "=================================================="
echo ""

GRAFANA_URL="http://213.109.162.134:30102"
GRAFANA_USER="admin"
GRAFANA_PASS="admin123"
DASHBOARD_FILE="monitoring/sonarqube-metrics-dashboard.json"

echo "🔍 Checking Grafana connectivity..."
if curl -s -u "$GRAFANA_USER:$GRAFANA_PASS" "$GRAFANA_URL/api/health" | grep -q "ok"; then
    echo "✅ Grafana is accessible"
else
    echo "❌ Grafana is not accessible"
    exit 1
fi

echo ""
echo "📤 Uploading SonarQube metrics dashboard..."

# Upload dashboard to Grafana
DASHBOARD_RESPONSE=$(curl -s -X POST \
  -H "Content-Type: application/json" \
  -u "$GRAFANA_USER:$GRAFANA_PASS" \
  -d @"$DASHBOARD_FILE" \
  "$GRAFANA_URL/api/dashboards/db")

echo "Dashboard upload response: $DASHBOARD_RESPONSE"

if echo "$DASHBOARD_RESPONSE" | grep -q '"status":"success"'; then
    echo "✅ SonarQube metrics dashboard deployed successfully!"
    
    # Extract dashboard URL
    DASHBOARD_URL=$(echo "$DASHBOARD_RESPONSE" | grep -o '"url":"[^"]*"' | cut -d'"' -f4)
    if [ -n "$DASHBOARD_URL" ]; then
        echo "🌐 Dashboard URL: $GRAFANA_URL$DASHBOARD_URL"
    fi
else
    echo "❌ Failed to deploy dashboard"
    echo "Response: $DASHBOARD_RESPONSE"
fi

echo ""
echo "🔧 Next steps:"
echo "   1. Verify Prometheus is scraping metrics from Pushgateway"
echo "   2. Check that SonarQube metrics are appearing in Prometheus"
echo "   3. View the dashboard at: $GRAFANA_URL/d/sonarqube-metrics-dashboard/sonarqube-metrics-dashboard-my-qaicb-repo"
echo ""
echo "📊 To check Prometheus metrics:"
echo "   curl -s http://213.109.162.134:30090/api/v1/query?query=sonarqube_bugs"
echo ""

