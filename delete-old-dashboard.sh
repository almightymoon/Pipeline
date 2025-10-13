#!/bin/bash

# Delete Old ML Pipeline Dashboard Script
# This script specifically deletes the old "ML Pipeline - All Results" dashboard

set -e

echo "=========================================="
echo "🗑️ Deleting Old ML Pipeline Dashboard"
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
echo "🔍 Step 1: Find Old Dashboard"
echo "=========================================="

# Get all dashboards and find the old one
print_status "Searching for old 'ML Pipeline - All Results' dashboard..."

DASHBOARDS_JSON=$(curl -s -X GET "$GRAFANA_URL/api/search?type=dash-db" \
    -u "$GRAFANA_USER:$GRAFANA_PASSWORD" \
    -H "Content-Type: application/json")

# Look for the old dashboard
OLD_DASHBOARD_UID=$(echo "$DASHBOARDS_JSON" | jq -r '.[] | select(.title | contains("ML Pipeline - All Results")) | .uid' 2>/dev/null || echo "")

if [ ! -z "$OLD_DASHBOARD_UID" ] && [ "$OLD_DASHBOARD_UID" != "null" ]; then
    print_status "Found old dashboard with UID: $OLD_DASHBOARD_UID"
    
    echo ""
    echo "=========================================="
    echo "🗑️ Step 2: Delete Old Dashboard"
    echo "=========================================="
    
    DELETE_RESPONSE=$(curl -s -X DELETE "$GRAFANA_URL/api/dashboards/uid/$OLD_DASHBOARD_UID" \
        -u "$GRAFANA_USER:$GRAFANA_PASSWORD" \
        -w "%{http_code}")
    
    if [[ "$DELETE_RESPONSE" == *"200"* ]]; then
        print_status "✅ Successfully deleted old 'ML Pipeline - All Results' dashboard!"
    else
        print_warning "Failed to delete old dashboard: $DELETE_RESPONSE"
    fi
else
    print_warning "Old 'ML Pipeline - All Results' dashboard not found (may already be deleted)"
fi

echo ""
echo "=========================================="
echo "🔍 Step 3: Check for Ultimate Dashboard"
echo "=========================================="

# Check if ultimate dashboard exists
ULTIMATE_DASHBOARD_UID=$(echo "$DASHBOARDS_JSON" | jq -r '.[] | select(.title | contains("Ultimate Pipeline Intelligence")) | .uid' 2>/dev/null || echo "")

if [ ! -z "$ULTIMATE_DASHBOARD_UID" ] && [ "$ULTIMATE_DASHBOARD_UID" != "null" ]; then
    print_status "✅ Ultimate Pipeline Intelligence dashboard already exists!"
    print_status "Dashboard URL: $GRAFANA_URL/d/$ULTIMATE_DASHBOARD_UID/ultimate-pipeline-intelligence"
else
    print_warning "Ultimate Pipeline Intelligence dashboard not found"
    echo ""
    echo "=========================================="
    echo "📋 MANUAL IMPORT REQUIRED"
    echo "=========================================="
    echo ""
    echo "Please import the ultimate dashboard manually:"
    echo ""
    echo "1. 🌐 Access Grafana:"
    echo "   URL: $GRAFANA_URL"
    echo "   Username: $GRAFANA_USER"
    echo "   Password: $GRAFANA_PASSWORD"
    echo ""
    echo "2. 🚀 Import Ultimate Dashboard:"
    echo "   • Click '+' in left sidebar"
    echo "   • Click 'Import'"
    echo "   • Upload: monitoring/ultimate-pipeline-dashboard.json"
    echo "   • Select 'Prometheus' data source"
    echo "   • Click 'Import'"
    echo ""
    echo "3. ✅ Access Your New Dashboard:"
    echo "   $GRAFANA_URL/d/ultimate-pipeline/ultimate-pipeline-intelligence"
fi

echo ""
echo "=========================================="
echo "✅ Cleanup Complete!"
echo "=========================================="
