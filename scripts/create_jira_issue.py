#!/usr/bin/env python3
"""
Create Jira issue via API
"""

import sys
import json
import requests
from requests.auth import HTTPBasicAuth

def create_jira_issue(jira_url, email, api_token, project_key, summary, description):
    """Create a Jira issue"""
    
    url = f"{jira_url}/rest/api/3/issue"
    
    auth = HTTPBasicAuth(email, api_token)
    
    headers = {
        "Accept": "application/json",
        "Content-Type": "application/json"
    }
    
    payload = {
        "fields": {
            "project": {
                "key": project_key
            },
            "summary": summary,
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
                "name": "Task"
            }
        }
    }
    
    try:
        response = requests.post(url, json=payload, headers=headers, auth=auth)
        
        if response.status_code in [200, 201]:
            data = response.json()
            issue_key = data.get('key')
            print(f"Jira issue created: {issue_key}")
            print(f"View at: {jira_url}/browse/{issue_key}")
            return issue_key
        else:
            print(f"Failed to create Jira issue. Status: {response.status_code}")
            print(f"Response: {response.text}")
            return None
            
    except Exception as e:
        print(f"Error creating Jira issue: {e}")
        return None


if __name__ == '__main__':
    import os
    
    jira_url = os.getenv('JIRA_URL')
    email = os.getenv('JIRA_EMAIL')
    api_token = os.getenv('JIRA_API_TOKEN')
    project_key = os.getenv('JIRA_PROJECT_KEY')
    summary = os.getenv('JIRA_SUMMARY', 'Pipeline Run')
    description = os.getenv('JIRA_DESCRIPTION', 'Pipeline completed')
    
    if not all([jira_url, email, api_token, project_key]):
        print("Missing required environment variables")
        sys.exit(1)
    
    issue_key = create_jira_issue(jira_url, email, api_token, project_key, summary, description)
    
    if issue_key:
        sys.exit(0)
    else:
        sys.exit(1)

