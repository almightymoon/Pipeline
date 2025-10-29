#!/bin/bash
# Monitor pipeline and check Grafana dashboard after completion

set -e

REPO_NAME="${1:-my-qaicb-repo}"
GRAFANA_URL="${GRAFANA_URL:-http://213.109.162.134:30102}"
PUSHGATEWAY_URL="${PROMETHEUS_PUSHGATEWAY_URL:-http://213.109.162.134:30091}"

echo "🔍 Pipeline Monitor & Dashboard Checker"
echo "=========================================="
echo ""

# Function to check GitHub Actions status
check_pipeline_status() {
    echo "📊 Checking GitHub Actions pipeline status..."
    curl -s -H "Accept: application/vnd.github+json" \
        "https://api.github.com/repos/almightymoon/Pipeline/actions/runs?per_page=1" 2>/dev/null | \
        python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    if data.get('workflow_runs'):
        run = data['workflow_runs'][0]
        print(f\"✅ Latest workflow: {run['name']}\")
        print(f\"   Status: {run['status']}\")
        print(f\"   Conclusion: {run.get('conclusion', 'running')}\")
        print(f\"   URL: {run['html_url']}\")
        return run['status'] == 'completed' and run.get('conclusion') == 'success'
    else:
        print(\"⚠️  No workflow runs found\")
        return False
except Exception as e:
    print(f\"⚠️  Error checking status: {e}\")
    return False
" || echo "⚠️  Could not check pipeline status"
}

# Function to check metrics in Pushgateway
check_pushgateway_metrics() {
    echo ""
    echo "📈 Checking metrics in Pushgateway..."
    curl -s "${PUSHGATEWAY_URL}/metrics" | grep -E "(pipeline_runs_total|code_quality_score|tests_coverage_percentage|security_vulnerabilities_total|external_repo_scan_duration)" | \
        grep "${REPO_NAME}" | head -5 | \
        while read line; do
            echo "   ✅ $line"
        done || echo "   ⚠️  No metrics found for ${REPO_NAME}"
}

# Function to check Grafana dashboard (basic check)
check_grafana_accessible() {
    echo ""
    echo "📊 Checking Grafana accessibility..."
    if curl -s "${GRAFANA_URL}/api/health" > /dev/null 2>&1; then
        echo "   ✅ Grafana is accessible at ${GRAFANA_URL}"
    else
        echo "   ⚠️  Grafana may not be accessible at ${GRAFANA_URL}"
    fi
}

# Monitor pipeline
echo "⏳ Waiting for pipeline to start..."
sleep 10

MAX_WAIT=600  # 10 minutes
ELAPSED=0
CHECK_INTERVAL=30

while [ $ELAPSED -lt $MAX_WAIT ]; do
    if check_pipeline_status | grep -q "completed.*success"; then
        echo ""
        echo "✅ Pipeline completed successfully!"
        echo ""
        echo "🔍 Checking metrics and dashboard..."
        
        check_pushgateway_metrics
        check_grafana_accessible
        
        echo ""
        echo "📊 Dashboard Check Instructions:"
        echo "1. Open Grafana: ${GRAFANA_URL}"
        echo "2. Navigate to dashboard: ML Pipeline - SonarQube & Quality Metrics Dashboard"
        echo "3. Check these metrics:"
        echo "   - Build Number"
        echo "   - Build Duration"
        echo "   - Quality Score"
        echo "   - Test Coverage"
        echo "   - Security Vulnerabilities"
        echo "4. If metrics show 'No data':"
        echo "   - Check time range (should be 'Last 6 hours' or wider)"
        echo "   - Refresh dashboard"
        echo "   - Wait 30 seconds for Prometheus to scrape"
        
        exit 0
    fi
    
    echo "⏳ Pipeline still running... waiting ${CHECK_INTERVAL}s (${ELAPSED}s elapsed)"
    sleep $CHECK_INTERVAL
    ELAPSED=$((ELAPSED + CHECK_INTERVAL))
done

echo ""
echo "⏰ Monitoring timeout reached. Checking current status..."
check_pipeline_status
check_pushgateway_metrics
check_grafana_accessible

echo ""
echo "💡 To manually check:"
echo "   - GitHub Actions: https://github.com/almightymoon/Pipeline/actions"
echo "   - Grafana Dashboard: ${GRAFANA_URL}"
echo "   - Pushgateway Metrics: ${PUSHGATEWAY_URL}/metrics"

