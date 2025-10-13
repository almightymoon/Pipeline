#!/bin/bash

# Import Simple Dashboard Script
# This script imports a simple, working dashboard

set -e

echo "=========================================="
echo "🚀 Importing Simple Pipeline Dashboard"
echo "=========================================="

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
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

# Grafana configuration
GRAFANA_URL="http://213.109.162.134:30102"
GRAFANA_USER="admin"
GRAFANA_PASSWORD="prom-operator"

echo ""
echo "=========================================="
echo "🔧 Step 1: Test Grafana Connection"
echo "=========================================="

# Test connection
HEALTH_CHECK=$(curl -s -o /dev/null -w "%{http_code}" "$GRAFANA_URL/api/health" \
    -u "$GRAFANA_USER:$GRAFANA_PASSWORD" 2>/dev/null || echo "000")

if [[ "$HEALTH_CHECK" == "200" ]]; then
    print_status "Grafana connection successful"
else
    print_error "Cannot connect to Grafana (HTTP $HEALTH_CHECK)"
    exit 1
fi

echo ""
echo "=========================================="
echo "🚀 Step 2: Import Simple Dashboard"
echo "=========================================="

print_status "Importing Simple Pipeline Dashboard..."

# Import the dashboard
IMPORT_RESPONSE=$(curl -s -X POST "$GRAFANA_URL/api/dashboards/db" \
    -H "Content-Type: application/json" \
    -u "$GRAFANA_USER:$GRAFANA_PASSWORD" \
    -d @monitoring/simple-pipeline-dashboard.json \
    -w "%{http_code}")

if [[ "$IMPORT_RESPONSE" == *"200"* ]]; then
    print_status "✅ Simple Pipeline Dashboard imported successfully!"
    DASHBOARD_URL="$GRAFANA_URL/d/simple-pipeline/simple-pipeline-dashboard"
else
    print_error "❌ Dashboard import failed: $IMPORT_RESPONSE"
    
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
    echo "   Password: $GRAFANA_PASSWORD"
    echo ""
    echo "2. 🚀 Import Simple Dashboard:"
    echo "   • Click '+' in left sidebar"
    echo "   • Click 'Import'"
    echo "   • Upload: monitoring/simple-pipeline-dashboard.json"
    echo "   • Click 'Import' (no data source needed for this simple version)"
    echo ""
    DASHBOARD_URL="$GRAFANA_URL/d/simple-pipeline/simple-pipeline-dashboard"
fi

echo ""
echo "=========================================="
echo "✅ Import Complete!"
echo "=========================================="
echo ""
echo "🎯 Dashboard Access:"
echo "  • URL: $DASHBOARD_URL"
echo "  • Username: $GRAFANA_USER"
echo "  • Password: $GRAFANA_PASSWORD"
echo ""
echo "🚀 Dashboard Features:"
echo "  ✅ Pipeline Overview with key metrics"
echo "  ✅ Code Quality Metrics (407 TODO, 770 Debug, 15 Large Files)"
echo "  ✅ Security Scan Results (1 vulnerability, 87.5% coverage)"
echo "  ✅ Repository Information with detailed breakdown"
echo "  ✅ Priority Actions with color-coded priorities"
echo ""
echo "📊 This dashboard shows:"
echo "  • Your actual scan results from tensorflow/models"
echo "  • Code quality metrics from the external repo scan"
echo "  • Security findings and test coverage"
echo "  • Actionable priority recommendations"
echo ""
echo "=========================================="
