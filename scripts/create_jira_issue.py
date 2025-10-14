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

def get_scan_status():
    """Get actual scan status from pipeline results"""
    try:
        # Check if we have scan results files
        has_trivy = os.path.exists('/tmp/trivy-results.json')
        has_quality = os.path.exists('/tmp/quality-results.txt')
        has_secrets = os.path.exists('/tmp/secrets-found.txt')
        
        # Determine status based on available data
        if has_trivy or has_quality or has_secrets:
            return "✅ Scan completed with data collected"
        else:
            return "⚠️ Scan completed - no data files found"
    except:
        return "❓ Scan status unknown"

def get_security_issues_summary():
    """Get summary of security issues found"""
    try:
        # Try to get actual scan results from environment variables or files
        repo_name = os.environ.get('REPO_NAME', 'Unknown')
        scan_type = os.environ.get('SCAN_TYPE', 'full')
        
        # Try to read scan results if available
        scan_results = []
        
        # Check for Trivy scan results
        if os.path.exists('/tmp/trivy-results.json'):
            try:
                with open('/tmp/trivy-results.json', 'r') as f:
                    trivy_data = json.load(f)
                    
                    total_vulns = 0
                    critical_vulns = 0
                    high_vulns = 0
                    
                    if 'Results' in trivy_data:
                        for result in trivy_data['Results']:
                            if 'Vulnerabilities' in result:
                                for vuln in result['Vulnerabilities']:
                                    total_vulns += 1
                                    severity = vuln.get('Severity', '').upper()
                                    if severity == 'CRITICAL':
                                        critical_vulns += 1
                                    elif severity == 'HIGH':
                                        high_vulns += 1
                    
                    # Generate dynamic summary based on actual findings
                    if total_vulns > 0:
                        vuln_summary = f"{total_vulns} vulnerabilities found"
                        if critical_vulns > 0:
                            vuln_summary += f" ({critical_vulns} critical"
                        if high_vulns > 0:
                            vuln_summary += f", {high_vulns} high"
                        if critical_vulns > 0 or high_vulns > 0:
                            vuln_summary += ")"
                        scan_results.append(vuln_summary)
                    else:
                        scan_results.append("No vulnerabilities detected")
                        
            except Exception as e:
                scan_results.append(f"Trivy scan completed (parse error: {str(e)[:50]})")
        
        # Check for secret scan results
        if os.path.exists('/tmp/secrets-found.txt'):
            try:
                with open('/tmp/secrets-found.txt', 'r') as f:
                    secrets_content = f.read().strip()
                    
                # Count different types of secrets found
                api_key_count = secrets_content.lower().count('api')
                password_count = secrets_content.lower().count('password')
                token_count = secrets_content.lower().count('token')
                
                if secrets_content and secrets_content != "No secrets found":
                    secret_summary = "Potential secrets detected"
                    if api_key_count > 0:
                        secret_summary += f" ({api_key_count} API keys"
                    if password_count > 0:
                        secret_summary += f", {password_count} passwords"
                    if token_count > 0:
                        secret_summary += f", {token_count} tokens"
                    if api_key_count > 0 or password_count > 0 or token_count > 0:
                        secret_summary += ")"
                    scan_results.append(secret_summary)
                else:
                    scan_results.append("No secrets found")
                    
            except Exception as e:
                scan_results.append(f"Secret scan completed (error: {str(e)[:30]})")
        
        # Check for code quality results
        quality_suggestions = get_quality_suggestions()
        if quality_suggestions:
            scan_results.append(quality_suggestions)
        
        # If no actual results, show that no data is available
        if not scan_results:
            scan_results = ["No scan data available - check pipeline logs for details"]
        
        return " • ".join(scan_results)
            
    except Exception as e:
        return "Analysis completed (check logs for details)"

def get_quality_suggestions():
    """Get code quality suggestions from scan results"""
    try:
        if not os.path.exists('/tmp/quality-results.txt'):
            return None
            
        with open('/tmp/quality-results.txt', 'r') as f:
            content = f.read()
            
        # Parse the quality results
        suggestions = []
        
        # Extract TODO count
        import re
        todo_match = re.search(r'TODO/FIXME comments: (\d+)', content)
        if todo_match:
            todo_count = int(todo_match.group(1))
            if todo_count > 0:
                suggestions.append(f"{todo_count} TODO/FIXME comments to address")
        
        # Extract debug statements count
        debug_match = re.search(r'Debug statements: (\d+)', content)
        if debug_match:
            debug_count = int(debug_match.group(1))
            if debug_count > 0:
                suggestions.append(f"{debug_count} debug statements to remove")
        
        # Extract large files count
        large_match = re.search(r'Large files \(>1MB\): (\d+)', content)
        if large_match:
            large_count = int(large_match.group(1))
            if large_count > 0:
                suggestions.append(f"{large_count} large files to optimize")
        
        # Extract total suggestions
        total_match = re.search(r'Total suggestions: (\d+)', content)
        if total_match:
            total_count = int(total_match.group(1))
            if total_count > 0:
                return f"{total_count} code quality improvements suggested"
        
        # Only return actual data
        if suggestions:
            return " • ".join(suggestions)
        else:
            return None  # Return None if no data available
            
    except Exception as e:
        return None

def get_quality_analysis():
    """Get detailed quality analysis for Jira description"""
    try:
        if not os.path.exists('/tmp/quality-results.txt'):
            return "• Quality analysis not available"
            
        with open('/tmp/quality-results.txt', 'r') as f:
            content = f.read()
            
        analysis_lines = []
        
        # Parse each metric
        import re
        
        # TODO/FIXME comments
        todo_match = re.search(r'TODO/FIXME comments: (\d+)', content)
        if todo_match:
            count = int(todo_match.group(1))
            if count > 0:
                analysis_lines.append(f"• {count} TODO/FIXME comments found (consider addressing)")
            else:
                analysis_lines.append("• No TODO/FIXME comments found ✅")
        
        # Debug statements
        debug_match = re.search(r'Debug statements: (\d+)', content)
        if debug_match:
            count = int(debug_match.group(1))
            if count > 0:
                analysis_lines.append(f"• {count} debug statements found (remove before production)")
            else:
                analysis_lines.append("• No debug statements found ✅")
        
        # Large files
        large_match = re.search(r'Large files \(>1MB\): (\d+)', content)
        if large_match:
            count = int(large_match.group(1))
            if count > 0:
                analysis_lines.append(f"• {count} large files found (consider optimization)")
            else:
                analysis_lines.append("• No large files found ✅")
        
        # Total suggestions
        total_match = re.search(r'Total suggestions: (\d+)', content)
        if total_match:
            total = int(total_match.group(1))
            analysis_lines.append(f"• **Total improvements suggested: {total}**")
        
        if analysis_lines:
            return "\n".join(analysis_lines)
        else:
            return "• No quality analysis data available - check pipeline logs"
            
    except Exception as e:
        return "• Quality analysis error (check logs for details)"

def get_priority_actions():
    """Get priority actions based on quality analysis"""
    try:
        if not os.path.exists('/tmp/quality-results.txt'):
            return "• No priority actions available - check pipeline logs"
            
        with open('/tmp/quality-results.txt', 'r') as f:
            content = f.read()
            
        actions = []
        import re
        
        # Get counts
        todo_count = int(re.search(r'TODO/FIXME comments: (\d+)', content).group(1)) if re.search(r'TODO/FIXME comments: (\d+)', content) else 0
        debug_count = int(re.search(r'Debug statements: (\d+)', content).group(1)) if re.search(r'Debug statements: (\d+)', content) else 0
        large_files = int(re.search(r'Large files \(>1MB\): (\d+)', content).group(1)) if re.search(r'Large files \(>1MB\): (\d+)', content) else 0
        
        # Priority actions based on counts
        if todo_count > 0:
            if todo_count > 200:
                priority = "🔴 HIGH"
                action = f"Address {todo_count} TODO/FIXME comments - critical for code maintainability"
            elif todo_count > 50:
                priority = "🟠 MEDIUM"
                action = f"Review and address {todo_count} TODO/FIXME comments"
            else:
                priority = "🟡 LOW"
                action = f"Consider addressing {todo_count} TODO/FIXME comments"
            actions.append(f"• {priority} | {action}")
            
        if debug_count > 0:
            if debug_count > 300:
                priority = "🔴 HIGH"
                action = f"Remove {debug_count} debug statements before production deployment"
            elif debug_count > 100:
                priority = "🟠 MEDIUM"
                action = f"Clean up {debug_count} debug statements"
            else:
                priority = "🟡 LOW"
                action = f"Review {debug_count} debug statements"
            actions.append(f"• {priority} | {action}")
            
        if large_files > 0:
            if large_files > 10:
                priority = "🟠 MEDIUM"
                action = f"Optimize {large_files} large files for better performance"
            else:
                priority = "🟡 LOW"
                action = f"Consider optimizing {large_files} large files"
            actions.append(f"• {priority} | {action}")
            
        if not actions:
            actions.append("• ✅ No immediate actions required - code quality is good")
            
        return "\n".join(actions)
            
    except Exception as e:
        return "• Priority actions error (check logs for details)"

def get_scan_metrics():
    """Get dynamic scan metrics from the pipeline"""
    try:
        metrics = []
        
        # Check for metrics file
        if os.path.exists('/tmp/scan-metrics.txt'):
            with open('/tmp/scan-metrics.txt', 'r') as f:
                content = f.read()
                
            # Extract metrics
            import re
            file_match = re.search(r'Total Files: (\d+)', content)
            line_match = re.search(r'Total Lines: (\d+)', content)
            size_match = re.search(r'Repository Size: (.+)', content)
            
            if file_match:
                metrics.append(f"Files scanned: {file_match.group(1)}")
            if line_match:
                metrics.append(f"Lines analyzed: {line_match.group(1)}")
            if size_match:
                metrics.append(f"Repository size: {size_match.group(1)}")
        
        # Check for scan duration
        github_run_number = os.environ.get('GITHUB_RUN_NUMBER', '')
        if github_run_number:
            metrics.append(f"Pipeline run: #{github_run_number}")
            
        return " • ".join(metrics) if metrics else "No metrics available"
        
    except Exception as e:
        return f"Metrics error: {str(e)[:30]}"

def create_enhanced_description(base_description):
    """Create enhanced description with scan details"""
    current_time = datetime.now().strftime("%Y-%m-%d %H:%M:%S UTC")
    
    # Get additional environment variables with fallbacks
    repo_url = os.environ.get('REPO_URL', os.environ.get('GITHUB_REPOSITORY_URL', 'Unknown'))
    repo_name = os.environ.get('REPO_NAME', os.environ.get('GITHUB_REPOSITORY', 'Unknown'))
    repo_branch = os.environ.get('REPO_BRANCH', os.environ.get('GITHUB_REF_NAME', 'main'))
    scan_type = os.environ.get('SCAN_TYPE', 'full')
    github_run_id = os.environ.get('GITHUB_RUN_ID', 'Unknown')
    github_run_number = os.environ.get('GITHUB_RUN_NUMBER', 'Unknown')
    
    # Try to get actual repository info from scan summary if available
    if os.path.exists('/tmp/scan-summary.txt'):
        try:
            with open('/tmp/scan-summary.txt', 'r') as f:
                summary_content = f.read()
                # Extract repository name from summary
                import re
                repo_match = re.search(r'Repository: (.+)', summary_content)
                if repo_match:
                    repo_name = repo_match.group(1)
        except:
            pass
    
    # Try to get actual scan results
    vulnerabilities_found = get_scan_status()
    security_issues = get_security_issues_summary()
    
    # Build repository link  
    if repo_url and repo_url != "Unknown":
        repo_link = f"[{repo_name}]({repo_url})"
    else:
        repo_link = repo_name
    
    enhanced_description = f"""
{base_description}

----

🔍 **EXTERNAL REPOSITORY SCAN REPORT**
----

**Repository Being Scanned:**
• **Name:** {repo_name}
• **URL:** {repo_url}
• **Link:** {repo_link}
• **Branch:** {repo_branch}
• **Scan Type:** {scan_type}
• **Scan Time:** {current_time}

**Pipeline Information:**
• Run ID: {github_run_id}
• Run Number: {github_run_number}
• Workflow: External Repository Security Scan

**Links:**
• 🔗 [View Scanned Repository]({repo_url})
• 📊 [Pipeline Dashboard - Complete Details](http://213.109.162.134:30102/d/fdc25d81-4cbc-4a72-ae9d-835c62961bff/pipeline-dashboard-complete-details)
• ⚙️ [Pipeline Logs](https://github.com/almightymoon/Pipeline/actions/runs/{github_run_id})

**Security Scan Results:**
• Status: {vulnerabilities_found}
• Issues Found: {security_issues}
• Scan Completed: ✅

**📊 Code Quality Analysis - Detailed Breakdown:**

{get_quality_analysis()}

**🎯 Priority Actions Required:**
{get_priority_actions()}

**Scan Metrics:**
• {get_scan_metrics()}

**Next Steps:**
1. Review security findings in pipeline logs (link above)
2. Check Pipeline Dashboard - Real Data for detailed metrics
3. Address any critical vulnerabilities found
4. Implement code quality improvements in **{repo_name}**
5. Update scanned repository if security issues are discovered

----
*This issue was automatically created by the External Repository Scanner Pipeline*
*Scanned Repository: {repo_name} | URL: {repo_url}*
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
