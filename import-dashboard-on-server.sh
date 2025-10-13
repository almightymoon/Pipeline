#!/bin/bash

# Import Dashboard Directly on Server
# This script will SSH into your server and import the dashboard

set -e

echo "=========================================="
echo "🚀 Importing Dashboard on Server"
echo "=========================================="

# Server details
SERVER="ubuntu@213.109.162.134"
SERVER_PASSWORD="qwert1234"

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

echo ""
echo "=========================================="
echo "🔍 Step 1: Get Grafana Admin Password"
echo "=========================================="

print_status "Connecting to server to get Grafana password..."

# SSH into server and get Grafana password
GRAFANA_PASSWORD=$(sshpass -p "$SERVER_PASSWORD" ssh -o StrictHostKeyChecking=no "$SERVER" \
    "kubectl get secret prometheus-grafana -n monitoring -o jsonpath='{.data.admin-password}' | base64 -d" 2>/dev/null || echo "prom-operator")

if [ "$GRAFANA_PASSWORD" = "prom-operator" ]; then
    print_warning "Using default password: prom-operator"
else
    print_status "Found Grafana password: $GRAFANA_PASSWORD"
fi

echo ""
echo "=========================================="
echo "🚀 Step 2: Copy Dashboard to Server"
echo "=========================================="

# Copy dashboard file to server
print_status "Copying dashboard file to server..."
sshpass -p "$SERVER_PASSWORD" scp -o StrictHostKeyChecking=no monitoring/working-dashboard.json "$SERVER:/tmp/"

echo ""
echo "=========================================="
echo "🚀 Step 3: Import Dashboard on Server"
echo "=========================================="

# Import dashboard on server
print_status "Importing dashboard on server..."

sshpass -p "$SERVER_PASSWORD" ssh -o StrictHostKeyChecking=no "$SERVER" << EOF
    # Test Grafana connection
    echo "Testing Grafana connection..."
    curl -s -o /dev/null -w "%{http_code}" "http://localhost:30102/api/health" -u "admin:$GRAFANA_PASSWORD"
    
    # Import dashboard
    echo "Importing dashboard..."
    curl -X POST "http://localhost:30102/api/dashboards/db" \
        -H "Content-Type: application/json" \
        -u "admin:$GRAFANA_PASSWORD" \
        -d @/tmp/working-dashboard.json \
        -w "%{http_code}"
    
    echo ""
    echo "Dashboard import completed!"
EOF

echo ""
echo "=========================================="
echo "✅ Import Complete!"
echo "=========================================="
echo ""
echo "🎯 Check your Grafana dashboard:"
echo "  URL: http://213.109.162.134:30102"
echo "  Username: admin"
echo "  Password: $GRAFANA_PASSWORD"
echo ""
echo "Look for: 🚀 Pipeline Dashboard - FIXED"
echo ""
echo "=========================================="
