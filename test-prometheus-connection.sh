#!/bin/bash

echo "========================================="
echo "Testing Prometheus Connection"
echo "========================================="

# Test Prometheus server
PROMETHEUS_URL="http://213.109.162.134:30102"
echo "Testing Prometheus server at: $PROMETHEUS_URL"

# Test if Prometheus is accessible
echo ""
echo "1. Testing Prometheus server connectivity..."
curl -s -o /dev/null -w "%{http_code}" "$PROMETHEUS_URL/api/v1/query?query=up" || echo "Failed to connect"

# Test Pushgateway
PUSHGATEWAY_URL="http://213.109.162.134:9091"
echo ""
echo "2. Testing Pushgateway at: $PUSHGATEWAY_URL"
curl -s -o /dev/null -w "%{http_code}" "$PUSHGATEWAY_URL/metrics" || echo "Pushgateway not accessible"

# Test Grafana
GRAFANA_URL="http://213.109.162.134:30102"
echo ""
echo "3. Testing Grafana at: $GRAFANA_URL"
curl -s -o /dev/null -w "%{http_code}" "$GRAFANA_URL/api/health" || echo "Grafana not accessible"

echo ""
echo "========================================="
echo "Testing Complete"
echo "========================================="

# Show what ports are actually exposed
echo ""
echo "Checking what ports are actually exposed on the server..."
sshpass -p "qwert1234" ssh -o StrictHostKeyChecking=no ubuntu@213.109.162.134 "kubectl get services -A | grep -E '(prometheus|grafana|pushgateway)'"
