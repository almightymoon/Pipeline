#!/bin/bash

# Clean up all failed pipeline runs
echo "============================================"
echo "Cleaning Up All Failed Pipeline Runs"
echo "============================================"

# Get all failed runs with their database IDs
echo "📋 Getting list of failed runs..."
FAILED_RUNS=$(gh run list --limit 100 --json status,conclusion,number,headBranch,createdAt,workflowName,databaseId | jq -r '.[] | select(.conclusion == "failure") | .databaseId')

if [ -z "$FAILED_RUNS" ]; then
    echo "✅ No failed runs found!"
    exit 0
fi

# Count failed runs
FAILED_COUNT=$(echo "$FAILED_RUNS" | wc -l)
echo "Found $FAILED_COUNT failed runs to delete"

echo ""
echo "⚠️  This will delete $FAILED_COUNT failed runs. Continue? (y/N)"
read -r response

if [[ "$response" =~ ^[Yy]$ ]]; then
    echo "🗑️  Deleting failed runs..."
    
    DELETED_COUNT=0
    for run_id in $FAILED_RUNS; do
        echo "Deleting run ID: $run_id..."
        if gh run delete "$run_id" 2>/dev/null; then
            echo "  ✅ Deleted successfully"
            ((DELETED_COUNT++))
        else
            echo "  ❌ Failed to delete"
        fi
    done
    
    echo ""
    echo "✅ Cleanup completed!"
    echo "📊 Deleted $DELETED_COUNT out of $FAILED_COUNT failed runs"
else
    echo "❌ Cleanup cancelled."
fi

echo "============================================"
