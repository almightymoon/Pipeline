#!/bin/bash

# ===========================================================
# Jira Integration Test Script
# ===========================================================
# This script helps you test Jira integration locally
# by setting up the environment variables from GitHub Secrets

echo "============================================"
echo "🔧 Jira Integration Test Setup"
echo "============================================"

# Check if we're in the right directory
if [ ! -f "scripts/complete_pipeline_solution.py" ]; then
    echo "❌ Error: Please run this script from the pipeline root directory"
    echo "   Current directory: $(pwd)"
    echo "   Expected files: scripts/complete_pipeline_solution.py"
    exit 1
fi

echo "📋 Setting up Jira environment variables..."
echo ""
echo "⚠️  IMPORTANT: You need to get these values from your GitHub Secrets:"
echo "   1. Go to your GitHub repository"
echo "   2. Navigate to Settings → Secrets and variables → Actions"
echo "   3. Copy the values for:"
echo "      - JIRA_URL"
echo "      - JIRA_EMAIL" 
echo "      - JIRA_API_TOKEN"
echo "      - JIRA_PROJECT_KEY"
echo ""

# Prompt for Jira credentials
read -p "🔗 Enter JIRA_URL (e.g., your-domain.atlassian.net): " JIRA_URL_INPUT
read -p "📧 Enter JIRA_EMAIL (e.g., your-email@example.com): " JIRA_EMAIL_INPUT
read -p "🔑 Enter JIRA_API_TOKEN: " JIRA_API_TOKEN_INPUT
read -p "📋 Enter JIRA_PROJECT_KEY (e.g., PROJECT): " JIRA_PROJECT_KEY_INPUT

# Validate inputs
if [ -z "$JIRA_URL_INPUT" ] || [ -z "$JIRA_EMAIL_INPUT" ] || [ -z "$JIRA_API_TOKEN_INPUT" ] || [ -z "$JIRA_PROJECT_KEY_INPUT" ]; then
    echo "❌ Error: All fields are required!"
    exit 1
fi

# Set environment variables
export JIRA_URL="$JIRA_URL_INPUT"
export JIRA_EMAIL="$JIRA_EMAIL_INPUT"
export JIRA_API_TOKEN="$JIRA_API_TOKEN_INPUT"
export JIRA_PROJECT_KEY="$JIRA_PROJECT_KEY_INPUT"

echo ""
echo "✅ Environment variables set!"
echo "   JIRA_URL: $JIRA_URL"
echo "   JIRA_EMAIL: $JIRA_EMAIL"
echo "   JIRA_API_TOKEN: ${JIRA_API_TOKEN:0:10}..."
echo "   JIRA_PROJECT_KEY: $JIRA_PROJECT_KEY"
echo ""

# Test Jira connection
echo "🔍 Testing Jira connection..."
python3 -c "
import requests
import os
import sys

jira_url = os.getenv('JIRA_URL')
jira_email = os.getenv('JIRA_EMAIL')
jira_token = os.getenv('JIRA_API_TOKEN')

if not all([jira_url, jira_email, jira_token]):
    print('❌ Missing Jira credentials')
    sys.exit(1)

# Test connection
try:
    response = requests.get(
        f'https://{jira_url}/rest/api/2/myself',
        auth=(jira_email, jira_token),
        timeout=10
    )
    
    if response.status_code == 200:
        user_data = response.json()
        print(f'✅ Jira connection successful!')
        print(f'   User: {user_data.get(\"displayName\", \"Unknown\")}')
        print(f'   Email: {user_data.get(\"emailAddress\", \"Unknown\")}')
        print(f'   Account ID: {user_data.get(\"accountId\", \"Unknown\")}')
    else:
        print(f'❌ Jira connection failed: HTTP {response.status_code}')
        print(f'   Response: {response.text}')
        sys.exit(1)
        
except Exception as e:
    print(f'❌ Jira connection error: {e}')
    sys.exit(1)
"

if [ $? -eq 0 ]; then
    echo ""
    echo "🎯 Running complete pipeline solution with Jira integration..."
    echo "============================================"
    
    # Run the complete pipeline solution
    python3 scripts/complete_pipeline_solution.py
    
    echo ""
    echo "============================================"
    echo "✅ Pipeline solution completed!"
    echo ""
    echo "📊 Check your results:"
    echo "   • Grafana Dashboard: http://213.109.162.134:30102"
    echo "   • Jira Issues: https://$JIRA_URL/jira/software/projects/$JIRA_PROJECT_KEY/boards/1"
    echo ""
else
    echo ""
    echo "❌ Jira connection failed. Please check your credentials."
    echo ""
    echo "🔧 Troubleshooting:"
    echo "   1. Verify JIRA_URL is correct (no https:// prefix)"
    echo "   2. Check JIRA_EMAIL matches your Atlassian account"
    echo "   3. Ensure JIRA_API_TOKEN is valid and not expired"
    echo "   4. Confirm JIRA_PROJECT_KEY exists in your Jira instance"
    echo ""
fi

echo "============================================"
