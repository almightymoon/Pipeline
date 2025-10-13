#!/usr/bin/env python3

import os
import sys
import requests
import json
from datetime import datetime

def create_failure_issue():
    """Create a Jira issue when pipeline fails"""
    
    # Get environment variables
    jira_url = os.getenv('JIRA_URL')
    jira_email = os.getenv('JIRA_EMAIL')
    jira_api_token = os.getenv('JIRA_API_TOKEN')
    jira_project_key = os.getenv('JIRA_PROJECT_KEY')
    
    repo_name = os.getenv('REPO_NAME', 'Unknown Repository')
    repo_url = os.getenv('REPO_URL', 'Unknown URL')
    repo_branch = os.getenv('REPO_BRANCH', 'Unknown Branch')
    github_run_id = os.getenv('GITHUB_RUN_ID', 'Unknown')
    github_run_number = os.getenv('GITHUB_RUN_NUMBER', 'Unknown')
    
    if not all([jira_url, jira_email, jira_api_token, jira_project_key]):
        print("Missing required Jira credentials")
        return 1
    
    # Create the Jira API URL
    api_url = f"{jira_url}/rest/api/3/issue"
    
    # Create issue description
    description = f"""🚨 **PIPELINE FAILURE REPORT**

**Repository Being Scanned:**
• *Name:* {repo_name}
• *URL:* {repo_url}
• *Branch:* {repo_branch}
• *Scan Type:* full

**Pipeline Information:**
• Run ID: {github_run_id}
• Run Number: {github_run_number}
• Workflow: Enhanced External Repository Scanner
• Status: ❌ **FAILED**

**Failure Details:**
• **Error:** Repository checkout failed
• **Cause:** Unable to access repository or branch doesn't exist
• **Time:** {datetime.utcnow().strftime('%Y-%m-%d %H:%M:%S')} UTC

**Possible Causes:**
1. **Repository is private** - Requires authentication
2. **Repository doesn't exist** - Invalid URL or repository deleted
3. **Branch doesn't exist** - Trying to checkout 'master' but branch might be 'main'
4. **Repository access issues** - Network or permission problems

**Links:**
• 🔗 [Repository URL]({repo_url})
• ⚙️ [Pipeline Logs](https://github.com/almightymoon/Pipeline/actions/runs/{github_run_id})
• 📊 [Pipeline Dashboard - Real Data](http://213.109.162.134:30102/d/9f0568b8-30a1-4306-ae44-f2f05a7c90d2/pipeline-dashboard-real-data)

**Immediate Actions Required:**
1. ✅ Verify repository URL is correct and accessible
2. ✅ Check if repository is public or requires authentication
3. ✅ Confirm branch name exists (try 'main' instead of 'master')
4. ✅ Update repos-to-scan.yaml with correct repository details
5. ✅ Re-run pipeline after fixing repository configuration

**Next Steps:**
1. Fix repository configuration in repos-to-scan.yaml
2. Test with a known public repository (e.g., tensorflow/models)
3. Monitor pipeline execution for successful completion
4. Check Grafana dashboard for updated metrics after successful run

This issue was automatically created due to pipeline failure.

----
**Scanned Repository:** {repo_name} | URL: {repo_url}"""

    # Create the issue payload
    payload = {
        "fields": {
            "project": {
                "key": jira_project_key
            },
            "summary": f"🚨 Pipeline Failure: {repo_name} - Repository Checkout Failed",
            "description": {
                "type": "doc",
                "version": 1,
                "content": [
                    {
                        "type": "paragraph",
                        "content": [
                            {
                                "type": "text",
                                "text": description
                            }
                        ]
                    }
                ]
            },
            "issuetype": {
                "name": "Bug"
            },
            "priority": {
                "name": "High"
            },
            "labels": [
                "pipeline-failure",
                "external-repo-scanner",
                "checkout-error",
                repo_name.lower().replace(" ", "-")
            ]
        }
    }
    
    # Make the API call
    try:
        response = requests.post(
            api_url,
            auth=(jira_email, jira_api_token),
            headers={
                'Content-Type': 'application/json',
                'Accept': 'application/json'
            },
            json=payload,
            timeout=30
        )
        
        if response.status_code in [200, 201]:
            issue_data = response.json()
            issue_key = issue_data.get('key', 'Unknown')
            print(f"Successfully created Jira failure issue: {issue_key}")
            return 0
        else:
            print(f"Failed to create Jira failure issue. Status code: {response.status_code}")
            print(f"Response: {response.text}")
            return 1
            
    except Exception as e:
        print(f"Error creating Jira failure issue: {str(e)}")
        return 1

if __name__ == '__main__':
    sys.exit(create_failure_issue())
