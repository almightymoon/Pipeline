#!/bin/bash
# Quick script to refresh dashboard metrics
# Usage: ./scripts/refresh_dashboard_metrics.sh [repo-name]

set -e

REPO_NAME="${1:-my-qaicb-repo}"
PUSHGATEWAY_URL="${PROMETHEUS_PUSHGATEWAY_URL:-http://213.109.162.134:30091}"

echo "🔄 Refreshing dashboard metrics for: $REPO_NAME"
echo "📤 Pushgateway: $PUSHGATEWAY_URL"
echo ""

export REPO_NAME="$REPO_NAME"
export PROMETHEUS_PUSHGATEWAY_URL="$PUSHGATEWAY_URL"
export GITHUB_RUN_NUMBER="${GITHUB_RUN_NUMBER:-157999}"
export GITHUB_RUN_ID="refresh-$(date +%s)"

python3 scripts/push_dashboard_metrics.py

echo ""
echo "✅ Metrics refreshed! Check your Grafana dashboard in ~30 seconds"

