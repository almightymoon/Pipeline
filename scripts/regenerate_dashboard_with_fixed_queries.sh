#!/bin/bash
# Regenerate dashboard with fixed queries that work with Pushgateway

set -e

REPO_NAME="${1:-my-qaicb-repo}"

echo "🔄 Regenerating dashboard with fixed queries for: $REPO_NAME"
echo ""

cd "$(dirname "$0")/.."

# Regenerate dashboard
python3 scripts/complete_pipeline_solution.py

echo ""
echo "✅ Dashboard regenerated with simplified queries"
echo "📊 The new queries use max() instead of sum() to work better with Pushgateway"
echo ""
echo "Next steps:"
echo "1. Push fresh metrics: ./scripts/refresh_dashboard_metrics.sh $REPO_NAME"
echo "2. The dashboard queries have been simplified to work with Pushgateway directly"
echo "3. Refresh your Grafana dashboard"

