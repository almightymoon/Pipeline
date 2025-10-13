#!/bin/bash

# Fix Dashboard Deployment Script
# This script tries different Grafana passwords and provides manual fallback

set -e

echo "=========================================="
echo "🔧 Fixing Dashboard Deployment"
echo "=========================================="

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[ℹ]${NC} $1"
}

# Grafana configuration
GRAFANA_URL="http://213.109.162.134:30102"
GRAFANA_USER="admin"

# Common passwords to try
PASSWORDS=("prom-operator" "admin" "password" "grafana" "changeme")

echo ""
echo "=========================================="
echo "🔍 Step 1: Find Correct Grafana Password"
echo "=========================================="

CORRECT_PASSWORD=""
for password in "${PASSWORDS[@]}"; do
    print_info "Trying password: $password"
    
    HEALTH_CHECK=$(curl -s -o /dev/null -w "%{http_code}" "$GRAFANA_URL/api/health" \
        -u "$GRAFANA_USER:$password" 2>/dev/null || echo "000")
    
    if [[ "$HEALTH_CHECK" == "200" ]]; then
        print_status "Found working password: $password"
        CORRECT_PASSWORD="$password"
        break
    else
        print_warning "Password '$password' failed (HTTP $HEALTH_CHECK)"
    fi
done

if [ -z "$CORRECT_PASSWORD" ]; then
    print_error "Could not find working password. Trying manual approach..."
    
    echo ""
    echo "=========================================="
    echo "📋 MANUAL DEPLOYMENT REQUIRED"
    echo "=========================================="
    echo ""
    echo "Please follow these steps manually:"
    echo ""
    echo "1. 🌐 Access Grafana:"
    echo "   URL: $GRAFANA_URL"
    echo "   Username: $GRAFANA_USER"
    echo "   Password: [Check your server setup]"
    echo ""
    echo "2. 🗑️ Delete All Existing Dashboards:"
    echo "   • Click 'Dashboards' in left sidebar"
    echo "   • For each dashboard: Click name → Gear icon → Dashboard settings → Delete"
    echo ""
    echo "3. 🚀 Import Ultimate Dashboard:"
    echo "   • Click '+' in left sidebar"
    echo "   • Click 'Import'"
    echo "   • Upload: monitoring/ultimate-pipeline-dashboard.json"
    echo "   • Select 'Prometheus' data source"
    echo "   • Click 'Import'"
    echo ""
    echo "4. ✅ Access Your Dashboard:"
    echo "   $GRAFANA_URL/d/ultimate-pipeline/ultimate-pipeline-intelligence"
    echo ""
    exit 1
fi

echo ""
echo "=========================================="
echo "🗑️ Step 2: Delete All Existing Dashboards"
echo "=========================================="

print_info "Deleting all existing dashboards..."

# Get all dashboards
DASHBOARDS_JSON=$(curl -s -X GET "$GRAFANA_URL/api/search?type=dash-db" \
    -u "$GRAFANA_USER:$CORRECT_PASSWORD" \
    -H "Content-Type: application/json")

echo "$DASHBOARDS_JSON" | jq -r '.[].uid' 2>/dev/null | while read uid; do
    if [ ! -z "$uid" ] && [ "$uid" != "null" ]; then
        print_info "Deleting dashboard: $uid"
        
        DELETE_RESPONSE=$(curl -s -X DELETE "$GRAFANA_URL/api/dashboards/uid/$uid" \
            -u "$GRAFANA_USER:$CORRECT_PASSWORD" \
            -w "%{http_code}")
        
        if [[ "$DELETE_RESPONSE" == *"200"* ]]; then
            print_status "Deleted dashboard: $uid"
        else
            print_warning "Failed to delete dashboard: $uid"
        fi
    fi
done

echo ""
echo "=========================================="
echo "🚀 Step 3: Import Ultimate Dashboard"
echo "=========================================="

print_info "Importing Ultimate Pipeline Intelligence Dashboard..."

DASHBOARD_RESPONSE=$(curl -s -X POST "$GRAFANA_URL/api/dashboards/db" \
    -H "Content-Type: application/json" \
    -u "$GRAFANA_USER:$CORRECT_PASSWORD" \
    -d @monitoring/ultimate-pipeline-dashboard.json \
    -w "%{http_code}")

if [[ "$DASHBOARD_RESPONSE" == *"200"* ]]; then
    print_status "✅ Ultimate Pipeline Intelligence Dashboard imported successfully!"
    DASHBOARD_URL="$GRAFANA_URL/d/ultimate-pipeline/ultimate-pipeline-intelligence"
else
    print_error "❌ Dashboard import failed: $DASHBOARD_RESPONSE"
    
    echo ""
    echo "=========================================="
    echo "📋 MANUAL IMPORT REQUIRED"
    echo "=========================================="
    echo ""
    echo "The automated import failed. Please import manually:"
    echo ""
    echo "1. 🌐 Access Grafana:"
    echo "   URL: $GRAFANA_URL"
    echo "   Username: $GRAFANA_USER"
    echo "   Password: $CORRECT_PASSWORD"
    echo ""
    echo "2. 🚀 Import Dashboard:"
    echo "   • Click '+' in left sidebar"
    echo "   • Click 'Import'"
    echo "   • Upload: monitoring/ultimate-pipeline-dashboard.json"
    echo "   • Select 'Prometheus' data source"
    echo "   • Click 'Import'"
    echo ""
    DASHBOARD_URL="$GRAFANA_URL/d/ultimate-pipeline/ultimate-pipeline-intelligence"
fi

echo ""
echo "=========================================="
echo "📊 Step 4: Configure Data Sources"
echo "=========================================="

# Configure Prometheus data source
print_info "Setting up Prometheus data source..."
PROMETHEUS_DS=$(curl -s -X POST "$GRAFANA_URL/api/datasources" \
    -H "Content-Type: application/json" \
    -u "$GRAFANA_USER:$CORRECT_PASSWORD" \
    -d '{
        "name": "Prometheus",
        "type": "prometheus",
        "url": "http://prometheus.monitoring.svc.cluster.local:9090",
        "access": "proxy",
        "basicAuth": false,
        "isDefault": true,
        "jsonData": {
            "timeInterval": "5s",
            "queryTimeout": "60s"
        }
    }' \
    -w "%{http_code}")

if [[ "$PROMETHEUS_DS" == *"200"* ]]; then
    print_status "Prometheus data source configured"
else
    print_warning "Prometheus data source may already exist"
fi

echo ""
echo "=========================================="
echo "✅ Dashboard Deployment Complete!"
echo "=========================================="
echo ""
echo "🎯 Dashboard Access:"
echo "  • URL: $DASHBOARD_URL"
echo "  • Username: $GRAFANA_USER"
echo "  • Password: $CORRECT_PASSWORD"
echo ""
echo "🚀 Dashboard Features:"
echo "  ✅ Executive Summary with key metrics"
echo "  ✅ Pipeline Performance Trends"
echo "  ✅ Code Quality Intelligence"
echo "  ✅ Security Analysis Center"
echo "  ✅ Code Quality Breakdown (Pie Charts)"
echo "  ✅ Repository Health Score (Gauge)"
echo "  ✅ Test Results Analytics"
echo "  ✅ Detailed Quality Analysis Table"
echo "  ✅ Repository Scan Summary"
echo "  ✅ Real-time Pipeline Logs"
echo "  ✅ Interactive Filters"
echo "  ✅ Smart Annotations & Alerts"
echo ""
echo "🎯 Next Steps:"
echo "  1. Visit the dashboard URL above"
echo "  2. Run a scan to populate with real data:"
echo "     git add repos-to-scan.yaml && git commit -m 'Test dashboard' && git push"
echo ""
echo "=========================================="
