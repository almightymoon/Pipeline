#!/usr/bin/env python3
"""
Create Jira issue via API
"""
import os
import sys
import requests
import json
import subprocess
from datetime import datetime

def create_enhanced_description(base_description):
    """Create enhanced description with scan details"""
    current_time = datetime.now().strftime("%Y-%m-%d %H:%M:%S UTC")
    
    # Get additional environment variables
    repo_url = os.environ.get('REPO_URL', 'Unknown')
    repo_name = os.environ.get('REPO_NAME', 'Unknown')
    repo_branch = os.environ.get('REPO_BRANCH', 'main')
    scan_type = os.environ.get('SCAN_TYPE', 'full')
    github_run_id = os.environ.get('GITHUB_RUN_ID', 'Unknown')
    github_run_number = os.environ.get('GITHUB_RUN_NUMBER', 'Unknown')
    
    # Try to get scan results if available
    vulnerabilities_found = "Scanning in progress..."
    security_issues = "Analysis pending..."
    
    enhanced_description = f"""
{base_description}

----

🔍 **SCAN DETAILS**
----

**Repository Information:**
• Repository: {repo_name}
• URL: {repo_url}
• Branch: {repo_branch}
• Scan Type: {scan_type}
• Scan Time: {current_time}

**Pipeline Information:**
• Run ID: {github_run_id}
• Run Number: {github_run_number}
• Workflow: External Repository Security Scan

**Links:**
• 🔗 [View Repository]({repo_url})
• 📊 [Grafana Dashboard](http://213.109.162.134:30102/d/ml-all-results/ml-pipeline-all-results)
• ⚙️ [GitHub Actions Logs](https://github.com/almightymoon/Pipeline/actions/runs/{github_run_id})

**Security Scan Results:**
• Status: {vulnerabilities_found}
• Issues Found: {security_issues}
• Scan Completed: ✅

**Next Steps:**
1. Review security findings in GitHub Actions logs
2. Check Grafana dashboard for detailed metrics
3. Address any critical vulnerabilities found
4. Update repository if issues are discovered

----
*This issue was automatically created by the External Repository Scanner Pipeline*
"""
    return enhanced_description

def create_jira_issue():
    # Get environment variables
    jira_url = os.environ.get('JIRA_URL', '').strip()
    jira_email = os.environ.get('JIRA_EMAIL', '').strip()
    jira_api_token = os.environ.get('JIRA_API_TOKEN', '').strip()
    jira_project_key = os.environ.get('JIRA_PROJECT_KEY', '').strip()
    summary = os.environ.get('JIRA_SUMMARY', 'Pipeline Run')
    description = os.environ.get('JIRA_DESCRIPTION', 'Pipeline completed')
    
    # Create enhanced description
    enhanced_description = create_enhanced_description(description)
    
    # Validate required fields
    if not all([jira_url, jira_email, jira_api_token, jira_project_key]):
        print("Missing required Jira configuration:")
        print(f"  JIRA_URL: {'set' if jira_url else 'NOT SET'}")
        print(f"  JIRA_EMAIL: {'set' if jira_email else 'NOT SET'}")
        print(f"  JIRA_API_TOKEN: {'set' if jira_api_token else 'NOT SET'}")
        print(f"  JIRA_PROJECT_KEY: {'set' if jira_project_key else 'NOT SET'}")
        return 1
    
    # Add https:// if scheme is missing
    if not jira_url.startswith(('http://', 'https://')):
        jira_url = 'https://' + jira_url
    
    # Ensure URL ends with /rest/api/2/issue
    if not jira_url.endswith('/rest/api/2/issue'):
        if jira_url.endswith('/'):
            jira_url = jira_url + 'rest/api/2/issue'
        else:
            jira_url = jira_url + '/rest/api/2/issue'
    
    print(f"Creating Jira issue in project {jira_project_key}")
    
    # Prepare the payload
    payload = {
        "fields": {
            "project": {
                "key": jira_project_key
            },
            "summary": summary,
            "description": enhanced_description,
            "issuetype": {
                "name": "Task"
            }
        }
    }
    
    # Make the API call
    try:
        response = requests.post(
            jira_url,
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
            print(f"Successfully created Jira issue: {issue_key}")
            return 0
        else:
            print(f"Failed to create Jira issue. Status code: {response.status_code}")
            print(f"Response: {response.text}")
            return 1
            
    except Exception as e:
        print(f"Error creating Jira issue: {str(e)}")
        return 1

if __name__ == '__main__':
    sys.exit(create_jira_issue())
