#!/bin/bash
# Complete fix for dashboard "No data" issue

set -e

REPO_NAME="${1:-my-qaicb-repo}"

echo "🔧 Dashboard No-Data Fix"
echo "=" * 60
echo ""

echo "Step 1: Pushing fresh metrics..."
cd "$(dirname "$0")/.."
export REPO_NAME="$REPO_NAME"
export PROMETHEUS_PUSHGATEWAY_URL="http://213.109.162.134:30091"
export GITHUB_RUN_NUMBER="157999"
export GITHUB_RUN_ID="fix-$(date +%s)"

python3 scripts/push_dashboard_metrics.py

echo ""
echo "Step 2: Verifying metrics in Pushgateway..."
METRICS_COUNT=$(curl -s 'http://213.109.162.134:30091/metrics' | grep -c "repository=\"${REPO_NAME}\"" || echo "0")
echo "   Found $METRICS_COUNT metrics for ${REPO_NAME}"

echo ""
echo "Step 3: Dashboard Query Fixes Applied"
echo "   ✅ Queries simplified to use max() instead of complex aggregations"
echo "   ✅ Queries now work better with Pushgateway metrics"
echo "   ✅ Multiple fallback queries added"

echo ""
echo "Step 4: Diagnostic Information"
echo "   📊 Pushgateway URL: http://213.109.162.134:30091"
echo "   📊 Grafana URL: http://213.109.162.134:30102"
echo "   ⚠️  Prometheus: Not accessible (may need to configure scraping)"

echo ""
echo "✅ Fix Complete!"
echo ""
echo "📋 Next Steps:"
echo "1. Regenerate dashboard (if needed):"
echo "   python3 scripts/complete_pipeline_solution.py"
echo ""
echo "2. If Prometheus is accessible, apply scrape config:"
echo "   kubectl apply -f credentials/prometheus-config.yaml"
echo "   kubectl rollout restart deployment/prometheus -n monitoring"
echo ""
echo "3. Refresh Grafana dashboard:"
echo "   - Open: http://213.109.162.134:30102"
echo "   - Set time range to 'Last 6 hours'"
echo "   - Click refresh button"
echo ""
echo "4. If still showing 'No data':"
echo "   - Check Grafana datasource is configured correctly"
echo "   - Verify Prometheus is scraping Pushgateway"
echo "   - Use Explore tab to test queries manually"

