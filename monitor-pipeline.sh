#!/bin/bash
# ===========================================================
# Pipeline Monitoring Script
# ===========================================================

echo "🔍 PIPELINE MONITORING"
echo "=========================================="
echo ""

# Check latest workflow runs
echo "📊 Latest Workflow Runs:"
gh run list --limit 5
echo ""

# Get the latest run ID
LATEST_RUN=$(gh run list --limit 1 --json databaseId --jq '.[0].databaseId')

if [ -n "$LATEST_RUN" ]; then
    echo "📝 Latest Run Details (ID: $LATEST_RUN):"
    echo "=========================================="
    gh run view $LATEST_RUN
    echo ""
    
    # Check if run is complete
    STATUS=$(gh run view $LATEST_RUN --json status --jq '.status')
    
    if [ "$STATUS" = "completed" ]; then
        echo "✅ Run completed! Fetching logs..."
        echo "=========================================="
        gh run view $LATEST_RUN --log | tail -100
        echo ""
        echo "🔗 Quick Links:"
        echo "   SonarQube: http://213.109.162.134:30100/dashboard?id=my-qaicb-repo"
        echo "   Grafana: http://213.109.162.134:30102"
        echo "   Prometheus: http://213.109.162.134:30090"
    else
        echo "⏳ Run is still $STATUS..."
        echo "   Run 'gh run watch $LATEST_RUN' to follow progress"
        echo "   Or visit: https://github.com/almightymoon/Pipeline/actions/runs/$LATEST_RUN"
    fi
else
    echo "❌ No workflow runs found"
fi

echo ""
echo "=========================================="
echo "💡 Useful Commands:"
echo "   Watch live: gh run watch"
echo "   View logs: gh run view <run-id> --log"
echo "   List runs: gh run list"
echo "   Trigger: gh workflow run 'scan-external-repos.yml'"
echo "=========================================="

