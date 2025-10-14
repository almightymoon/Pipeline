#!/bin/bash

# Clean up failed pipeline runs
# This script will delete all failed workflow runs

echo "============================================"
echo "Cleaning Up Failed Pipeline Runs"
echo "============================================"

# Get all failed runs
echo "📋 Getting list of failed runs..."
FAILED_RUNS=$(gh run list --limit 100 --json status,conclusion,number,headBranch,createdAt,workflowName | jq -r '.[] | select(.conclusion == "failure") | .number')

if [ -z "$FAILED_RUNS" ]; then
    echo "✅ No failed runs found!"
    exit 0
fi

echo "Found failed runs:"
echo "$FAILED_RUNS"

echo ""
echo "⚠️  This will delete all failed runs. Continue? (y/N)"
read -r response

if [[ "$response" =~ ^[Yy]$ ]]; then
    echo "🗑️  Deleting failed runs..."
    
    for run_number in $FAILED_RUNS; do
        echo "Deleting run #$run_number..."
        gh run delete "$run_number" --force
    done
    
    echo "✅ Cleanup completed!"
else
    echo "❌ Cleanup cancelled."
fi

echo "============================================"
