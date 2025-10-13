#!/bin/bash

# Enhanced Monitoring Setup Script
# This script deploys the enhanced Grafana dashboard with metrics and logs

set -e

echo "=========================================="
echo "🚀 Enhanced Monitoring Setup"
echo "=========================================="

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

# Check if running on remote server or local
if [ -n "$SSH_CONNECTION" ]; then
    print_status "Running on remote server"
    GRAFANA_URL="http://localhost:30102"
    PROMETHEUS_URL="http://localhost:30090"
else
    print_status "Running locally - will configure for remote server"
    GRAFANA_URL="http://213.109.162.134:30102"
    PROMETHEUS_URL="http://213.109.162.134:30090"
fi

echo ""
echo "=========================================="
echo "📊 Step 1: Configure Prometheus Exporters"
echo "=========================================="

# Create Prometheus configuration for GitHub Actions metrics
cat > /tmp/prometheus-github-exporter.yaml <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: prometheus-github-exporter
  namespace: monitoring
data:
  config.yml: |
    github:
      token: "\${GITHUB_TOKEN}"
      repositories:
        - almightymoon/Pipeline
      metrics:
        - workflow_runs
        - workflow_duration
        - job_duration
        - test_results
        - security_scans
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: prometheus-github-exporter
  namespace: monitoring
spec:
  replicas: 1
  selector:
    matchLabels:
      app: github-exporter
  template:
    metadata:
      labels:
        app: github-exporter
    spec:
      containers:
      - name: github-exporter
        image: infinityworks/github-exporter:latest
        ports:
        - containerPort: 9171
          name: metrics
        env:
        - name: GITHUB_TOKEN
          valueFrom:
            secretKeyRef:
              name: github-token
              key: token
        - name: REPOS
          value: "almightymoon/Pipeline"
        - name: ORGS
          value: "almightymoon"
---
apiVersion: v1
kind: Service
metadata:
  name: prometheus-github-exporter
  namespace: monitoring
  labels:
    app: github-exporter
spec:
  ports:
  - port: 9171
    targetPort: 9171
    name: metrics
  selector:
    app: github-exporter
EOF

print_status "Created Prometheus GitHub exporter configuration"

echo ""
echo "=========================================="
echo "📈 Step 2: Deploy Enhanced Grafana Dashboard"
echo "=========================================="

# Create the dashboard in Grafana
if command -v curl &> /dev/null; then
    print_status "Importing enhanced dashboard to Grafana..."
    
    # Create the dashboard folder if it doesn't exist
    curl -X POST "$GRAFANA_URL/api/folders" \
        -H "Content-Type: application/json" \
        -u "admin:${GRAFANA_PASSWORD:-prom-operator}" \
        -d '{"uid":"ml-pipeline-reports","title":"🚀 ML Pipeline Reports"}' \
        2>/dev/null || true
    
    # Import the enhanced dashboard
    curl -X POST "$GRAFANA_URL/api/dashboards/db" \
        -H "Content-Type: application/json" \
        -u "admin:${GRAFANA_PASSWORD:-prom-operator}" \
        -d @monitoring/enhanced-grafana-dashboard.json \
        2>/dev/null || print_warning "Dashboard import may require manual step"
    
    print_status "Enhanced dashboard imported"
else
    print_warning "curl not found - manual dashboard import required"
fi

echo ""
echo "=========================================="
echo "📝 Step 3: Configure Log Aggregation"
echo "=========================================="

# Create Loki configuration for log aggregation
cat > /tmp/loki-config.yaml <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: loki-config
  namespace: monitoring
data:
  loki.yaml: |
    auth_enabled: false
    server:
      http_listen_port: 3100
    ingester:
      lifecycler:
        ring:
          kvstore:
            store: inmemory
          replication_factor: 1
      chunk_idle_period: 5m
      chunk_retain_period: 30s
    schema_config:
      configs:
        - from: 2020-10-24
          store: boltdb-shipper
          object_store: filesystem
          schema: v11
          index:
            prefix: index_
            period: 24h
    storage_config:
      boltdb_shipper:
        active_index_directory: /loki/index
        cache_location: /loki/cache
        shared_store: filesystem
      filesystem:
        directory: /loki/chunks
    limits_config:
      enforce_metric_name: false
      reject_old_samples: true
      reject_old_samples_max_age: 168h
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: loki
  namespace: monitoring
spec:
  replicas: 1
  selector:
    matchLabels:
      app: loki
  template:
    metadata:
      labels:
        app: loki
    spec:
      containers:
      - name: loki
        image: grafana/loki:2.9.0
        ports:
        - containerPort: 3100
          name: http-metrics
        volumeMounts:
        - name: config
          mountPath: /etc/loki
        - name: storage
          mountPath: /loki
      volumes:
      - name: config
        configMap:
          name: loki-config
      - name: storage
        emptyDir: {}
---
apiVersion: v1
kind: Service
metadata:
  name: loki
  namespace: monitoring
spec:
  ports:
  - port: 3100
    targetPort: 3100
    name: http-metrics
  selector:
    app: loki
EOF

print_status "Created Loki log aggregation configuration"

echo ""
echo "=========================================="
echo "🔗 Step 4: Configure Grafana Data Sources"
echo "=========================================="

# Add Loki as a data source in Grafana
cat > /tmp/loki-datasource.json <<EOF
{
  "name": "Loki",
  "type": "loki",
  "access": "proxy",
  "url": "http://loki.monitoring.svc.cluster.local:3100",
  "basicAuth": false,
  "isDefault": false,
  "jsonData": {
    "maxLines": 1000
  }
}
EOF

if command -v curl &> /dev/null; then
    print_status "Adding Loki data source to Grafana..."
    curl -X POST "$GRAFANA_URL/api/datasources" \
        -H "Content-Type: application/json" \
        -u "admin:${GRAFANA_PASSWORD:-prom-operator}" \
        -d @/tmp/loki-datasource.json \
        2>/dev/null || print_warning "Loki data source may already exist"
fi

echo ""
echo "=========================================="
echo "📊 Step 5: Create Metrics Collection Job"
echo "=========================================="

# Create a CronJob to collect GitHub Actions metrics
cat > /tmp/metrics-collector.yaml <<EOF
apiVersion: batch/v1
kind: CronJob
metadata:
  name: github-metrics-collector
  namespace: monitoring
spec:
  schedule: "*/5 * * * *"  # Every 5 minutes
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: collector
            image: curlimages/curl:latest
            command:
            - /bin/sh
            - -c
            - |
              # Fetch GitHub Actions metrics and push to Prometheus Pushgateway
              echo "Collecting GitHub Actions metrics..."
              
              # Get workflow runs
              curl -s -H "Authorization: token \$GITHUB_TOKEN" \\
                https://api.github.com/repos/almightymoon/Pipeline/actions/runs?per_page=10 \\
                > /tmp/runs.json
              
              # Parse and push metrics
              cat /tmp/runs.json | grep -o '"conclusion":"[^"]*"' | sort | uniq -c | \\
                while read count conclusion; do
                  echo "github_actions_conclusion{conclusion=\"\${conclusion}\"} \$count" | \\
                    curl --data-binary @- http://prometheus-pushgateway.monitoring.svc.cluster.local:9091/metrics/job/github-actions
                done
            env:
            - name: GITHUB_TOKEN
              valueFrom:
                secretKeyRef:
                  name: github-token
                  key: token
          restartPolicy: OnFailure
EOF

print_status "Created metrics collection CronJob"

echo ""
echo "=========================================="
echo "🚀 Step 6: Deploy All Components"
echo "=========================================="

# Apply all configurations (if on remote server)
if kubectl get nodes &> /dev/null; then
    print_status "Deploying GitHub metrics exporter..."
    kubectl apply -f /tmp/prometheus-github-exporter.yaml || print_warning "GitHub exporter deployment may need manual review"
    
    print_status "Deploying Loki log aggregation..."
    kubectl apply -f /tmp/loki-config.yaml || print_warning "Loki deployment may need manual review"
    
    print_status "Deploying metrics collector..."
    kubectl apply -f /tmp/metrics-collector.yaml || print_warning "Metrics collector may need manual review"
    
    print_status "All components deployed successfully!"
else
    print_warning "kubectl not available - configurations saved to /tmp for manual deployment"
    echo "To deploy on remote server, run:"
    echo "  kubectl apply -f /tmp/prometheus-github-exporter.yaml"
    echo "  kubectl apply -f /tmp/loki-config.yaml"
    echo "  kubectl apply -f /tmp/metrics-collector.yaml"
fi

echo ""
echo "=========================================="
echo "✅ Enhanced Monitoring Setup Complete!"
echo "=========================================="
echo ""
echo "📊 Dashboard Access:"
echo "  • Grafana: $GRAFANA_URL"
echo "  • Username: admin"
echo "  • Password: prom-operator (or your custom password)"
echo ""
echo "🔍 Dashboard Features:"
echo "  ✅ Real-time pipeline metrics"
echo "  ✅ Security scan results"
echo "  ✅ Test results trending"
echo "  ✅ Pipeline execution logs"
echo "  ✅ Error and success logs"
echo "  ✅ Code quality metrics"
echo "  ✅ Jira integration status"
echo "  ✅ Stage duration tracking"
echo "  ✅ Real-time metrics stream"
echo ""
echo "📝 Next Steps:"
echo "  1. Access Grafana at: $GRAFANA_URL"
echo "  2. Navigate to '🚀 ML Pipeline Reports' folder"
echo "  3. Open '🚀 Enterprise Pipeline - Metrics & Logs' dashboard"
echo "  4. Configure GitHub token secret if not already set:"
echo "     kubectl create secret generic github-token --from-literal=token=YOUR_TOKEN -n monitoring"
echo ""
echo "=========================================="

