#!/bin/bash

# Create unique dashboard for each repository and update Jira with dashboard URL
# This script should be run after the pipeline completes scanning a repository

set -e

echo "============================================"
echo "Creating Repository-Specific Dashboard"
echo "============================================"

# Navigate to the project directory
cd "$(dirname "$0")"

# Run the Python script
python3 scripts/create_repo_dashboard_and_jira.py

echo ""
echo "✅ Dashboard and Jira issue creation complete!"
echo "============================================"

