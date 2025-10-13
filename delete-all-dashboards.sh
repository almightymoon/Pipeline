#!/bin/bash

# Delete All Grafana Dashboards Script
# This script removes all existing dashboards to start fresh

set -e

echo "=========================================="
echo "🗑️ Deleting All Existing Grafana Dashboards"
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
echo "📊 Step 1: Get All Dashboard UIDs"
echo "=========================================="

# Get all dashboards
DASHBOARDS_JSON=$(curl -s -X GET "$GRAFANA_URL/api/search?type=dash-db" \
    -u "$GRAFANA_USER:$GRAFANA_PASSWORD" \
    -H "Content-Type: application/json")

echo "Found dashboards:"
echo "$DASHBOARDS_JSON" | jq -r '.[] | "• \(.title) (UID: \(.uid))"' 2>/dev/null || echo "No dashboards found or jq not available"

echo ""
echo "=========================================="
echo "🗑️ Step 2: Delete All Dashboards"
echo "=========================================="

# Extract UIDs and delete each dashboard
echo "$DASHBOARDS_JSON" | jq -r '.[].uid' 2>/dev/null | while read uid; do
    if [ ! -z "$uid" ] && [ "$uid" != "null" ]; then
        echo "Deleting dashboard with UID: $uid"
        
        DELETE_RESPONSE=$(curl -s -X DELETE "$GRAFANA_URL/api/dashboards/uid/$uid" \
            -u "$GRAFANA_USER:$GRAFANA_PASSWORD" \
            -w "%{http_code}")
        
        if [[ "$DELETE_RESPONSE" == *"200"* ]]; then
            print_status "Successfully deleted dashboard: $uid"
        else
            print_warning "Failed to delete dashboard: $uid (Response: $DELETE_RESPONSE)"
        fi
    fi
done

echo ""
echo "=========================================="
echo "🗑️ Step 3: Delete All Dashboard Folders"
echo "=========================================="

# Get all folders and delete them
FOLDERS_JSON=$(curl -s -X GET "$GRAFANA_URL/api/folders" \
    -u "$GRAFANA_USER:$GRAFANA_PASSWORD" \
    -H "Content-Type: application/json")

echo "$FOLDERS_JSON" | jq -r '.[].uid' 2>/dev/null | while read folder_uid; do
    if [ ! -z "$folder_uid" ] && [ "$folder_uid" != "null" ]; then
        echo "Deleting folder with UID: $folder_uid"
        
        DELETE_RESPONSE=$(curl -s -X DELETE "$GRAFANA_URL/api/folders/$folder_uid" \
            -u "$GRAFANA_USER:$GRAFANA_PASSWORD" \
            -w "%{http_code}")
        
        if [[ "$DELETE_RESPONSE" == *"200"* ]]; then
            print_status "Successfully deleted folder: $folder_uid"
        else
            print_warning "Failed to delete folder: $folder_uid (Response: $DELETE_RESPONSE)"
        fi
    fi
done

echo ""
echo "=========================================="
echo "✅ Cleanup Complete!"
echo "=========================================="
echo ""
echo "All existing dashboards and folders have been deleted."
echo "Ready to create the new comprehensive dashboard!"
echo ""
echo "Next: Run ./create-ultimate-dashboard.sh"
echo "=========================================="
