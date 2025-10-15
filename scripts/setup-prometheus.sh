#!/bin/bash
set -e

echo "========================================="
echo "PROMETHEUS SETUP SCRIPT"
echo "========================================="

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker first."
    exit 1
fi

echo "✅ Docker is running"

# Stop existing Prometheus container if running
echo "🛑 Stopping existing Prometheus container..."
docker stop prometheus 2>/dev/null || true
docker rm prometheus 2>/dev/null || true

# Create Prometheus configuration
echo "📁 Creating Prometheus configuration..."
mkdir -p prometheus-config
cat > prometheus-config/prometheus.yml << EOF
global:
  scrape_interval: 15s
  evaluation_interval: 15s

rule_files:
  # - "first_rules.yml"
  # - "second_rules.yml"

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'pipeline-metrics'
    static_configs:
      - targets: ['localhost:9091']
    scrape_interval: 5s
    metrics_path: /metrics

  - job_name: 'sonarqube'
    static_configs:
      - targets: ['213.109.162.134:30100']
    metrics_path: /api/monitoring/metrics
    scrape_interval: 30s
EOF

echo "✅ Prometheus configuration created"

# Start Prometheus container
echo "🚀 Starting Prometheus container..."
docker run -d \
  --name prometheus \
  -p 30090:9090 \
  -v "$(pwd)/prometheus-config:/etc/prometheus" \
  prom/prometheus:latest \
  --config.file=/etc/prometheus/prometheus.yml \
  --storage.tsdb.path=/prometheus \
  --web.console.libraries=/etc/prometheus/console_libraries \
  --web.console.templates=/etc/prometheus/consoles \
  --web.enable-lifecycle

echo "✅ Prometheus container started"

# Wait for Prometheus to be ready
echo "⏳ Waiting for Prometheus to be ready..."
for i in {1..30}; do
    if curl -s http://localhost:30090/api/v1/query?query=up > /dev/null 2>&1; then
        echo "✅ Prometheus is ready!"
        break
    fi
    echo "⏳ Waiting... ($i/30)"
    sleep 5
done

# Check if Prometheus is accessible
if curl -s http://localhost:30090/api/v1/query?query=up > /dev/null 2>&1; then
    echo "✅ Prometheus is accessible at http://localhost:30090"
    echo "🌐 Access URL: http://213.109.162.134:30090"
else
    echo "❌ Prometheus is not accessible. Check logs with: docker logs prometheus"
    exit 1
fi

echo "========================================="
echo "PROMETHEUS SETUP COMPLETED"
echo "========================================="
echo "🌐 Prometheus URL: http://213.109.162.134:30090"
echo "📊 Query API: http://213.109.162.134:30090/api/v1/query"
echo "📈 Graph: http://213.109.162.134:30090/graph"
echo "========================================="
