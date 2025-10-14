#!/bin/bash

# Complete Pipeline Solution - Creates dashboard and Jira with real data
# This script should be run after the pipeline completes scanning a repository

set -e

echo "============================================"
echo "Complete Pipeline Solution - Real Data"
echo "============================================"

# Navigate to the project directory
cd "$(dirname "$0")"

# Run the complete solution
python3 scripts/complete_pipeline_solution.py

echo ""
echo "✅ Complete pipeline solution finished!"
echo "============================================"
