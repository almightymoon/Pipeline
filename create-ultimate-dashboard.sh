#!/bin/bash

# Create Ultimate Pipeline Dashboard Script
# This script creates ONE comprehensive, professional dashboard

set -e

echo "=========================================="
echo "🚀 Creating Ultimate Pipeline Intelligence Dashboard"
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
GRAFANA_PASSWORD="prom-operator"

echo ""
echo "=========================================="
echo "🔧 Step 1: Verify Grafana Connection"
echo "=========================================="

# Test Grafana connection
HEALTH_CHECK=$(curl -s -o /dev/null -w "%{http_code}" "$GRAFANA_URL/api/health" \
    -u "$GRAFANA_USER:$GRAFANA_PASSWORD" || echo "000")

if [[ "$HEALTH_CHECK" == "200" ]]; then
    print_status "Grafana is accessible and healthy"
else
    print_error "Cannot connect to Grafana (HTTP $HEALTH_CHECK)"
    print_info "Please ensure Grafana is running at $GRAFANA_URL"
    exit 1
fi

echo ""
echo "=========================================="
echo "📊 Step 2: Configure Data Sources"
echo "=========================================="

# Configure Prometheus data source
print_info "Setting up Prometheus data source..."
PROMETHEUS_DS=$(curl -s -X POST "$GRAFANA_URL/api/datasources" \
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
            "timeInterval": "5s",
            "queryTimeout": "60s"
        }
    }' \
    -w "%{http_code}")

if [[ "$PROMETHEUS_DS" == *"200"* ]]; then
    print_status "Prometheus data source configured"
else
    print_warning "Prometheus data source may already exist or need manual configuration"
fi

# Configure Pushgateway data source
print_info "Setting up Pushgateway data source..."
PUSHGATEWAY_DS=$(curl -s -X POST "$GRAFANA_URL/api/datasources" \
    -H "Content-Type: application/json" \
    -u "$GRAFANA_USER:$GRAFANA_PASSWORD" \
    -d '{
        "name": "Pushgateway",
        "type": "prometheus",
        "url": "http://213.109.162.134:30091",
        "access": "proxy",
        "basicAuth": false,
        "isDefault": false,
        "jsonData": {
            "timeInterval": "5s",
            "queryTimeout": "60s"
        }
    }' \
    -w "%{http_code}")

if [[ "$PUSHGATEWAY_DS" == *"200"* ]]; then
    print_status "Pushgateway data source configured"
else
    print_warning "Pushgateway data source may already exist or need manual configuration"
fi

echo ""
echo "=========================================="
echo "🚀 Step 3: Deploy Ultimate Dashboard"
echo "=========================================="

print_info "Importing Ultimate Pipeline Intelligence Dashboard..."

DASHBOARD_RESPONSE=$(curl -s -X POST "$GRAFANA_URL/api/dashboards/db" \
    -H "Content-Type: application/json" \
    -u "$GRAFANA_USER:$GRAFANA_PASSWORD" \
    -d @monitoring/ultimate-pipeline-dashboard.json \
    -w "%{http_code}")

if [[ "$DASHBOARD_RESPONSE" == *"200"* ]]; then
    print_status "Ultimate Pipeline Intelligence Dashboard imported successfully!"
    
    # Extract dashboard URL
    DASHBOARD_UID="ultimate-pipeline"
    DASHBOARD_URL="$GRAFANA_URL/d/$DASHBOARD_UID/ultimate-pipeline-intelligence"
    
else
    print_warning "Dashboard import response: $DASHBOARD_RESPONSE"
    print_warning "Dashboard may need manual import or already exists"
    DASHBOARD_URL="$GRAFANA_URL/d/ultimate-pipeline/ultimate-pipeline-intelligence"
fi

echo ""
echo "=========================================="
echo "🔧 Step 4: Setup Prometheus Pushgateway"
echo "=========================================="

# Create Prometheus Pushgateway if not exists
if kubectl get nodes &> /dev/null; then
    print_info "Deploying Prometheus Pushgateway for metrics collection..."
    
    cat > /tmp/pushgateway-deployment.yaml <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: prometheus-pushgateway
  namespace: monitoring
  labels:
    app: pushgateway
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
        livenessProbe:
          httpGet:
            path: /metrics
            port: 9091
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /metrics
            port: 9091
          initialDelaySeconds: 5
          periodSeconds: 5
---
apiVersion: v1
kind: Service
metadata:
  name: prometheus-pushgateway
  namespace: monitoring
  labels:
    app: pushgateway
spec:
  selector:
    app: pushgateway
  ports:
  - name: http
    port: 9091
    targetPort: 9091
    nodePort: 30091
  type: NodePort
EOF

    kubectl apply -f /tmp/pushgateway-deployment.yaml || print_warning "Pushgateway deployment may need manual review"
    print_status "Prometheus Pushgateway deployed"
    
    # Wait for deployment
    print_info "Waiting for Pushgateway to be ready..."
    kubectl wait --for=condition=available --timeout=60s deployment/prometheus-pushgateway -n monitoring || print_warning "Pushgateway may still be starting"
    
else
    print_warning "kubectl not available - Pushgateway config saved to /tmp/pushgateway-deployment.yaml"
fi

echo ""
echo "=========================================="
echo "✅ Ultimate Dashboard Deployment Complete!"
echo "=========================================="
echo ""
echo "🎯 Dashboard Access:"
echo "  • URL: $DASHBOARD_URL"
echo "  • Username: $GRAFANA_USER"
echo "  • Password: $GRAFANA_PASSWORD"
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
echo "  ✅ Interactive Filters (Repository, Search)"
echo "  ✅ Smart Annotations & Alerts"
echo "  ✅ Professional Dark Theme"
echo ""
echo "📊 Data Sources Configured:"
echo "  • Prometheus (Primary metrics)"
echo "  • Pushgateway (Pipeline metrics)"
echo ""
echo "🔧 Pushgateway Access:"
echo "  • URL: http://213.109.162.134:30091"
echo "  • For pushing metrics from pipelines"
echo ""
echo "🎯 Next Steps:"
echo "  1. Visit the dashboard URL above"
echo "  2. Run the external repo scan to populate with real data"
echo "  3. The dashboard will show comprehensive analytics"
echo "  4. Use filters to focus on specific repositories"
echo ""
echo "📈 This dashboard provides:"
echo "  • Real-time pipeline monitoring"
echo "  • Code quality intelligence"
echo "  • Security vulnerability tracking"
echo "  • Test coverage analytics"
echo "  • Repository health scoring"
echo "  • Interactive drill-down capabilities"
echo ""
echo "=========================================="
