#!/bin/bash

# Deploy Comprehensive Grafana Dashboard Script
# This script deploys a much better Grafana dashboard with detailed analytics

set -e

echo "=========================================="
echo "🚀 Deploying Comprehensive Grafana Dashboard"
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
echo "📊 Step 1: Create Dashboard Folder"
echo "=========================================="

# Create dashboard folder
FOLDER_RESPONSE=$(curl -s -X POST "$GRAFANA_URL/api/folders" \
    -H "Content-Type: application/json" \
    -u "$GRAFANA_USER:$GRAFANA_PASSWORD" \
    -d '{"uid":"comprehensive-pipeline","title":"🚀 Comprehensive Pipeline Analytics"}' \
    -w "%{http_code}")

if [[ "$FOLDER_RESPONSE" == *"200"* ]] || [[ "$FOLDER_RESPONSE" == *"409"* ]]; then
    print_status "Dashboard folder created or already exists"
else
    print_warning "Could not create dashboard folder (may already exist)"
fi

echo ""
echo "=========================================="
echo "📈 Step 2: Import Comprehensive Dashboard"
echo "=========================================="

# Import the comprehensive dashboard
DASHBOARD_RESPONSE=$(curl -s -X POST "$GRAFANA_URL/api/dashboards/db" \
    -H "Content-Type: application/json" \
    -u "$GRAFANA_USER:$GRAFANA_PASSWORD" \
    -d @monitoring/comprehensive-pipeline-dashboard.json \
    -w "%{http_code}")

if [[ "$DASHBOARD_RESPONSE" == *"200"* ]]; then
    print_status "Comprehensive dashboard imported successfully!"
else
    print_warning "Dashboard import response: $DASHBOARD_RESPONSE"
    print_warning "Dashboard may already exist or need manual import"
fi

echo ""
echo "=========================================="
echo "🔧 Step 3: Configure Prometheus Data Source"
echo "=========================================="

# Check if Prometheus data source exists
PROMETHEUS_DS=$(curl -s -X GET "$GRAFANA_URL/api/datasources" \
    -u "$GRAFANA_USER:$GRAFANA_PASSWORD" | grep -o '"name":"Prometheus"' || echo "")

if [ -z "$PROMETHEUS_DS" ]; then
    print_status "Adding Prometheus data source..."
    
    curl -s -X POST "$GRAFANA_URL/api/datasources" \
        -H "Content-Type: application/json" \
        -u "$GRAFANA_USER:$GRAFANA_PASSWORD" \
        -d '{
            "name": "Prometheus",
            "type": "prometheus",
            "url": "http://prometheus.monitoring.svc.cluster.local:9090",
            "access": "proxy",
            "basicAuth": false,
            "isDefault": true,
            "jsonData": {
                "timeInterval": "5s"
            }
        }' > /dev/null
    
    print_status "Prometheus data source added"
else
    print_status "Prometheus data source already exists"
fi

echo ""
echo "=========================================="
echo "📊 Step 4: Configure Pushgateway Data Source"
echo "=========================================="

# Check if Pushgateway data source exists
PUSHGATEWAY_DS=$(curl -s -X GET "$GRAFANA_URL/api/datasources" \
    -u "$GRAFANA_USER:$GRAFANA_PASSWORD" | grep -o '"name":"Pushgateway"' || echo "")

if [ -z "$PUSHGATEWAY_DS" ]; then
    print_status "Adding Pushgateway data source..."
    
    curl -s -X POST "$GRAFANA_URL/api/datasources" \
        -H "Content-Type: application/json" \
        -u "$GRAFANA_USER:$GRAFANA_PASSWORD" \
        -d '{
            "name": "Pushgateway",
            "type": "prometheus",
            "url": "http://213.109.162.134:9091",
            "access": "proxy",
            "basicAuth": false,
            "isDefault": false,
            "jsonData": {
                "timeInterval": "5s"
            }
        }' > /dev/null
    
    print_status "Pushgateway data source added"
else
    print_status "Pushgateway data source already exists"
fi

echo ""
echo "=========================================="
echo "🔧 Step 5: Setup Prometheus Pushgateway"
echo "=========================================="

# Create Prometheus Pushgateway deployment
cat > /tmp/pushgateway-deployment.yaml <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: prometheus-pushgateway
  namespace: monitoring
spec:
  replicas: 1
  selector:
    matchLabels:
      app: pushgateway
  template:
    metadata:
      labels:
        app: pushgateway
    spec:
      containers:
      - name: pushgateway
        image: prom/pushgateway:latest
        ports:
        - containerPort: 9091
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "200m"
---
apiVersion: v1
kind: Service
metadata:
  name: prometheus-pushgateway
  namespace: monitoring
spec:
  selector:
    app: pushgateway
  ports:
  - port: 9091
    targetPort: 9091
    nodePort: 30091
  type: NodePort
---
apiVersion: v1
kind: Service
metadata:
  name: prometheus-pushgateway-internal
  namespace: monitoring
spec:
  selector:
    app: pushgateway
  ports:
  - port: 9091
    targetPort: 9091
EOF

if kubectl get nodes &> /dev/null; then
    print_status "Deploying Prometheus Pushgateway..."
    kubectl apply -f /tmp/pushgateway-deployment.yaml || print_warning "Pushgateway deployment may need manual review"
    print_status "Prometheus Pushgateway deployed"
else
    print_warning "kubectl not available - Pushgateway config saved to /tmp/pushgateway-deployment.yaml"
fi

echo ""
echo "=========================================="
echo "✅ Deployment Complete!"
echo "=========================================="
echo ""
echo "📊 Access Your New Dashboard:"
echo "  • URL: $GRAFANA_URL/d/comprehensive-pipeline/comprehensive-pipeline-analytics"
echo "  • Username: $GRAFANA_USER"
echo "  • Password: $GRAFANA_PASSWORD"
echo ""
echo "🔍 Dashboard Features:"
echo "  ✅ Detailed Code Quality Analysis with charts"
echo "  ✅ Security Vulnerabilities by severity and repository"
echo "  ✅ Test Results trending over time"
echo "  ✅ Code Quality breakdown pie charts"
echo "  ✅ Quality metrics trending"
echo "  ✅ Repository scan summary tables"
echo "  ✅ Pipeline performance metrics"
echo "  ✅ Detailed code quality logs"
echo "  ✅ Interactive filters and time ranges"
echo ""
echo "📈 Pushgateway Access:"
echo "  • URL: http://213.109.162.134:30091"
echo "  • For pushing metrics from pipelines"
echo ""
echo "🎯 Next Steps:"
echo "  1. Visit the dashboard URL above"
echo "  2. Run the external repo scan to populate with real data"
echo "  3. The dashboard will show detailed analytics from your scans"
echo ""
echo "=========================================="
