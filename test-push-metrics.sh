#!/bin/bash

echo "========================================="
echo "Testing Push Metrics to Prometheus"
echo "========================================="

# Set environment variables to match the pipeline
export REPO_NAME="Neuropilot-project"
export REPO_URL="https://github.com/almightymoon/Neuropilot"
export GITHUB_RUN_ID="18497369043"
export GITHUB_RUN_NUMBER="44"
export PROMETHEUS_PUSHGATEWAY_URL="http://213.109.162.134:9091"

echo "Repository: $REPO_NAME"
echo "Run ID: $GITHUB_RUN_ID"
echo "Run Number: $GITHUB_RUN_NUMBER"

# Run the metrics script
echo "Pushing metrics to Prometheus..."
python3 scripts/push_metrics_to_prometheus.py

echo ""
echo "========================================="
echo "Metrics pushed! Check Grafana dashboard:"
echo "http://213.109.162.134:30102/d/47428692-d8b7-4633-8990-23fa4e2b4049/dynamic-pipeline-dashboard-real-data"
echo "========================================="
