#!/usr/bin/env python3
"""
Create a unique dashboard for each pipeline run and update Jira with the dashboard URL
"""

import os
import json
import requests
import yaml
import sys
import hashlib
from datetime import datetime

def _format_size(num_bytes: int) -> str:
    """Format bytes to human readable size"""
    units = ['B', 'KB', 'MB', 'GB', 'TB']
    size = float(num_bytes)
    idx = 0
    while size >= 1024 and idx < len(units) - 1:
        size /= 1024.0
        idx += 1
    if idx == 0:
        return f"{int(size)}{units[idx]}"
    return f"{size:.2f}{units[idx]}"

def list_large_files(min_bytes: int = 1_000_000) -> list:
    """Find large files that are part of the actual repository content.
    ONLY uses git-tracked files to ensure we only report files that are actually in the repo.
    Returns list of tuples (relative_path, human_size) sorted by size desc.
    Excludes tool artifacts like sonar-scanner, trivy, etc.
    """
    repo_root = os.path.abspath('external-repo') if os.path.isdir('external-repo') else None
    results: list[tuple[str, int]] = []
    
    # Patterns to exclude tool artifacts and build files
    ignore_patterns = [
        'sonar-scanner',
        'trivy',
        'node_modules',
        '.cache',
        '__pycache__',
        '.pytest_cache',
        '.git',
        '.venv',
        'venv',
        '.idea',
        '.vscode'
    ]
    
    # File extensions to exclude (only tool artifacts)
    ignore_extensions = ['.zip', '.tar.gz', '.deb', '.rpm']
    
    def should_exclude_file(filepath: str, filename: str) -> bool:
        """Check if file should be excluded based on path or name patterns"""
        filepath_lower = filepath.lower()
        filename_lower = filename.lower()
        
        # Check if path or filename contains any ignore patterns
        for pattern in ignore_patterns:
            if pattern in filepath_lower or pattern in filename_lower:
                return True
        
        # Exclude archive files only if they match tool artifact patterns
        for ext in ignore_extensions:
            if filename_lower.endswith(ext):
                # Exclude if it's a tool artifact (sonar-scanner, trivy, etc.)
                if any(tool in filepath_lower for tool in ['sonar-scanner', 'trivy', 'scanner', 'tool']):
                    return True
        
        return False
    
    # ONLY use git-tracked files - this ensures we only count files that are actually in the repo
    if repo_root:
        try:
            import subprocess
            # Use git ls-files to ONLY get tracked files
            completed = subprocess.run(
                ['git', '-C', repo_root, 'ls-files', '-z'],
                check=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.DEVNULL,
                text=False,
            )
            tracked = completed.stdout.split(b'\x00') if completed.stdout else []
            for rel_b in tracked:
                if not rel_b:
                    continue
                rel = rel_b.decode('utf-8', errors='ignore')
                
                # Skip tool artifacts
                if should_exclude_file(rel, os.path.basename(rel)):
                    continue
                
                fpath = os.path.join(repo_root, rel)
                try:
                    if os.path.isfile(fpath):
                        size = os.path.getsize(fpath)
                        if size >= min_bytes:
                            results.append((os.path.join('external-repo', rel), size))
                except Exception:
                    continue
        except Exception as e:
            # If git isn't available or fails, return empty list
            # We should NOT fall back to filesystem scan as it might include untracked files
            print(f"Warning: Could not use git to list tracked files: {e}")
            print("Returning empty list to ensure we only report files actually in the repo")
            return []
    
    results.sort(key=lambda x: x[1], reverse=True)
    return [(p, _format_size(s)) for p, s in results]

def get_large_files_list_for_jira() -> str:
    """Get formatted list of large files for Jira description"""
    try:
        repo_large_files = list_large_files()
        if repo_large_files:
            files_list = "\n".join([f"  • {path} ({size_str})" for path, size_str in repo_large_files])
            return f"• Large Files with Paths:\n{files_list}"
        else:
            return ""
    except Exception as e:
        print(f"Warning: Could not get large files list: {e}")
        return ""

# Grafana Configuration
GRAFANA_URL = "http://213.109.162.134:30102"
# Security: Use environment variables instead of hardcoded credentials
GRAFANA_USER = os.environ.get('GRAFANA_USERNAME', 'admin')
GRAFANA_PASS = os.environ.get('GRAFANA_PASSWORD')
if not GRAFANA_PASS:
    raise ValueError("GRAFANA_PASSWORD environment variable is required")

def read_current_repo():
    """Read the current repository from repos-to-scan.yaml"""
    try:
        with open('repos-to-scan.yaml', 'r') as f:
            data = yaml.safe_load(f)
        
        if data and 'repositories' in data and data['repositories']:
            # Get the first active (non-commented) repository
            for repo in data['repositories']:
                if repo and 'url' in repo and repo['url']:
                    return {
                        'url': repo['url'],
                        'name': repo.get('name', 'unknown'),
                        'branch': repo.get('branch', 'main'),
                        'scan_type': repo.get('scan_type', 'full')
                    }
        
        # Fallback if no active repositories found
        return {
            'url': 'https://github.com/example/repo',
            'name': 'example-repo',
            'branch': 'main',
            'scan_type': 'full'
        }
    except Exception as e:
        print(f"Error reading repos-to-scan.yaml: {e}")
        return {
            'url': 'https://github.com/example/repo',
            'name': 'example-repo',
            'branch': 'main',
            'scan_type': 'full'
        }

def get_repo_metrics_from_pipeline():
    """Get real-time metrics from the current pipeline run"""
    
    # Try to get metrics from environment variables and scan results
    metrics = {
        "pipeline_runs": {"total": 1, "successful": 1, "failed": 0},
        "security": {"critical": 0, "high": 0, "medium": 0, "low": 0, "total": 0},
        "quality": {"todo_comments": 0, "debug_statements": 0, "large_files": 0, "total_improvements": 0, "quality_score": 90},
        "tests": {"passed": 0, "failed": 0, "coverage": 0.0},
        "scan_info": {
            "files_scanned": 0,
            "repository_size": "0M",
            "pipeline_run": os.environ.get('GITHUB_RUN_NUMBER', '#1'),
            "scan_time": datetime.now().strftime('%Y-%m-%d %H:%M:%S UTC')
        },
        "large_files_list": []
    }
    
    # Try to read Trivy results
    try:
        if os.path.exists('/tmp/trivy-results.json'):
            with open('/tmp/trivy-results.json', 'r') as f:
                trivy_data = json.load(f)
                
                if 'Results' in trivy_data:
                    for result in trivy_data['Results']:
                        if 'Vulnerabilities' in result:
                            for vuln in result['Vulnerabilities']:
                                severity = vuln.get('Severity', '').upper()
                                metrics['security']['total'] += 1
                                if severity == 'CRITICAL':
                                    metrics['security']['critical'] += 1
                                elif severity == 'HIGH':
                                    metrics['security']['high'] += 1
                                elif severity == 'MEDIUM':
                                    metrics['security']['medium'] += 1
                                elif severity == 'LOW':
                                    metrics['security']['low'] += 1
    except Exception as e:
        print(f"Warning: Could not read Trivy results: {e}")
    
    # Try to read quality results
    try:
        if os.path.exists('/tmp/quality-results.txt'):
            with open('/tmp/quality-results.txt', 'r') as f:
                content = f.read()
                
            import re
            todo_match = re.search(r'TODO/FIXME comments: (\d+)', content)
            if todo_match:
                metrics['quality']['todo_comments'] = int(todo_match.group(1))
            
            debug_match = re.search(r'Debug statements: (\d+)', content)
            if debug_match:
                metrics['quality']['debug_statements'] = int(debug_match.group(1))
            
            # NOTE: We DON'T read large_files from quality-results.txt anymore
            # We use the actual scan count from list_large_files() instead
            
            total_match = re.search(r'Total suggestions: (\d+)', content)
            if total_match:
                metrics['quality']['total_improvements'] = int(total_match.group(1))
    except Exception as e:
        print(f"Warning: Could not read quality results: {e}")
    
    # IMPORTANT: Get actual large file count from git-tracked files only
    try:
        actual_large_files = list_large_files()
        metrics['quality']['large_files'] = len(actual_large_files)
        print(f"📊 Actual large files count (git-tracked only): {metrics['quality']['large_files']}")
        if metrics['quality']['large_files'] > 0:
            print(f"   Large files found: {[f[0] for f in actual_large_files[:5]]}")
    except Exception as e:
        print(f"⚠️  Error getting actual large files count: {e}")
        metrics['quality']['large_files'] = 0
    
    # Recalculate total_improvements based on actual counts
    metrics['quality']['total_improvements'] = (
        metrics['quality']['todo_comments'] + 
        metrics['quality']['debug_statements'] + 
        metrics['quality']['large_files']
    )
    
    # Calculate quality score
    try:
        total_issues = metrics['quality']['todo_comments'] + metrics['quality']['debug_statements'] + metrics['quality']['large_files']
        if total_issues == 0:
            metrics['quality']['quality_score'] = 95
        elif total_issues < 10:
            metrics['quality']['quality_score'] = 85
        elif total_issues < 50:
            metrics['quality']['quality_score'] = 70
        else:
            metrics['quality']['quality_score'] = 50
    except Exception as e:
        print(f"Warning: Could not calculate quality score: {e}")
    
    # Try to read test results
    try:
        if os.path.exists('/tmp/test-results.txt'):
            with open('/tmp/test-results.txt', 'r') as f:
                content = f.read()
            
            import re
            passed_match = re.search(r'Tests passed: (\d+)', content)
            if passed_match:
                metrics['tests']['passed'] = int(passed_match.group(1))
            
            failed_match = re.search(r'Tests failed: (\d+)', content)
            if failed_match:
                metrics['tests']['failed'] = int(failed_match.group(1))
            
            coverage_match = re.search(r'Coverage: ([\d.]+)%', content)
            if coverage_match:
                metrics['tests']['coverage'] = float(coverage_match.group(1))
    except Exception as e:
        print(f"Warning: Could not read test results: {e}")
    
    # Try to read scan metrics
    try:
        if os.path.exists('/tmp/scan-metrics.txt'):
            with open('/tmp/scan-metrics.txt', 'r') as f:
                content = f.read()
            
            import re
            file_match = re.search(r'Total Files: (\d+)', content)
            if file_match:
                metrics['scan_info']['files_scanned'] = int(file_match.group(1))
            
            size_match = re.search(r'Repository Size: (.+)', content)
            if size_match:
                metrics['scan_info']['repository_size'] = size_match.group(1).strip()
    except Exception as e:
        print(f"Warning: Could not read scan metrics: {e}")
    
    return metrics

def generate_dashboard_uid(repo_name):
    """Generate a unique and consistent UID for each repository"""
    # Create a hash of the repo name for consistency
    hash_object = hashlib.md5(repo_name.encode())
    hash_hex = hash_object.hexdigest()
    
    # Format as UUID-like string (8-4-4-4-12)
    uid = f"{hash_hex[0:8]}-{hash_hex[8:12]}-{hash_hex[12:16]}-{hash_hex[16:20]}-{hash_hex[20:32]}"
    return uid

def create_dashboard_for_repo(repo_info, metrics):
    """Create a unique dashboard for the specific repository"""
    
    repo_name = repo_info['name']
    repo_url = repo_info['url']
    repo_branch = repo_info['branch']
    scan_type = repo_info['scan_type']
    
    # Generate a unique UID for this repository
    dashboard_uid = generate_dashboard_uid(repo_name)
    
    print(f"Creating dashboard for repository: {repo_name}")
    print(f"Dashboard UID: {dashboard_uid}")
    
    # Build the dashboard JSON based on the template
    dashboard_json = {
        "dashboard": {
            "uid": dashboard_uid,
            "title": f"Pipeline Dashboard - {repo_name}",
            "tags": ["pipeline", "real-data", "auto-generated", repo_name],
            "timezone": "browser",
            "refresh": "30s",
            "panels": [
                # Panel 1: Pipeline Status
                {
                    "id": 1,
                    "title": f"Pipeline Status - {repo_name}",
                    "type": "stat",
                    "gridPos": {"h": 6, "w": 8, "x": 0, "y": 0},
                    "targets": [
                        {"expr": f"{metrics['pipeline_runs']['total']}", "legendFormat": "Total Runs", "refId": "A"},
                        {"expr": f"{metrics['pipeline_runs']['successful']}", "legendFormat": "Successful", "refId": "B"},
                        {"expr": f"{metrics['pipeline_runs']['failed']}", "legendFormat": "Failed", "refId": "C"}
                    ],
                    "fieldConfig": {
                        "defaults": {
                            "color": {"mode": "thresholds"},
                            "thresholds": {
                                "steps": [
                                    {"color": "green", "value": None},
                                    {"color": "red", "value": 1}
                                ]
                            },
                            "unit": "short"
                        }
                    }
                },
                # Panel 2: Security Vulnerabilities
                {
                    "id": 2,
                    "title": f"Security Vulnerabilities - {repo_name}",
                    "type": "stat",
                    "gridPos": {"h": 6, "w": 8, "x": 8, "y": 0},
                    "targets": [
                        {"expr": f"{metrics['security']['critical']}", "legendFormat": "Critical", "refId": "A"},
                        {"expr": f"{metrics['security']['high']}", "legendFormat": "High", "refId": "B"},
                        {"expr": f"{metrics['security']['medium']}", "legendFormat": "Medium", "refId": "C"},
                        {"expr": f"{metrics['security']['low']}", "legendFormat": "Low", "refId": "D"}
                    ],
                    "fieldConfig": {
                        "defaults": {
                            "color": {"mode": "thresholds"},
                            "thresholds": {
                                "steps": [
                                    {"color": "green", "value": None},
                                    {"color": "yellow", "value": 1},
                                    {"color": "red", "value": 5}
                                ]
                            },
                            "unit": "short"
                        }
                    }
                },
                # Panel 3: Code Quality
                {
                    "id": 3,
                    "title": f"Code Quality - {repo_name}",
                    "type": "stat",
                    "gridPos": {"h": 6, "w": 8, "x": 16, "y": 0},
                    "targets": [
                        {"expr": f"{metrics['quality']['todo_comments']}", "legendFormat": "TODO/FIXME", "refId": "A"},
                        {"expr": f"{metrics['quality']['debug_statements']}", "legendFormat": "Debug Statements", "refId": "B"},
                        {"expr": f"{metrics['quality']['large_files']}", "legendFormat": "Large Files", "refId": "C"},
                        {"expr": f"{metrics['quality']['quality_score']}", "legendFormat": "Quality Score", "refId": "D"}
                    ],
                    "fieldConfig": {
                        "defaults": {
                            "color": {"mode": "thresholds"},
                            "thresholds": {
                                "steps": [
                                    {"color": "green", "value": 90},
                                    {"color": "yellow", "value": 70},
                                    {"color": "red", "value": None}
                                ]
                            },
                            "unit": "short"
                        }
                    }
                },
                # Panel 4: Test Results
                {
                    "id": 4,
                    "title": f"Test Results - {repo_name}",
                    "type": "stat",
                    "gridPos": {"h": 6, "w": 8, "x": 0, "y": 6},
                    "targets": [
                        {"expr": f"{metrics['tests']['passed']}", "legendFormat": "Tests Passed", "refId": "A"},
                        {"expr": f"{metrics['tests']['failed']}", "legendFormat": "Tests Failed", "refId": "B"},
                        {"expr": f"{metrics['tests']['coverage']}", "legendFormat": "Coverage %", "refId": "C"}
                    ],
                    "fieldConfig": {
                        "defaults": {
                            "color": {"mode": "thresholds"},
                            "thresholds": {
                                "steps": [
                                    {"color": "green", "value": 80},
                                    {"color": "yellow", "value": 50},
                                    {"color": "red", "value": None}
                                ]
                            },
                            "unit": "short"
                        }
                    }
                },
                # Panel 5: Repository Information
                {
                    "id": 5,
                    "title": "Repository Information",
                    "type": "text",
                    "gridPos": {"h": 6, "w": 16, "x": 8, "y": 6},
                    "options": {
                        "mode": "markdown",
                        "content": f"""## 📊 Repository Information - {repo_name}

**Repository:** {repo_name}  
**URL:** [{repo_url}]({repo_url})  
**Branch:** {repo_branch}  
**Scan Type:** {scan_type}  
**Scan Time:** {metrics['scan_info']['scan_time']}  
**Pipeline Run:** #{metrics['scan_info']['pipeline_run']}  
**Files Scanned:** {metrics['scan_info']['files_scanned']}  
**Repository Size:** {metrics['scan_info']['repository_size']}  

**Last Updated:** {datetime.now().strftime('%Y-%m-%d %H:%M:%S UTC')}  
**Dashboard Status:** ✅ Real-time data from pipeline run"""
                    }
                },
                # Panel 6: Security Details
                {
                    "id": 6,
                    "title": "🔒 Detailed Security Vulnerabilities",
                    "type": "text",
                    "gridPos": {"h": 8, "w": 12, "x": 0, "y": 12},
                    "options": {
                        "mode": "markdown",
                        "content": f"""## 🔒 Security Vulnerabilities Analysis

### Critical Vulnerabilities: {metrics['security']['critical']}
{'✅ No critical vulnerabilities found' if metrics['security']['critical'] == 0 else f'🚨 {metrics["security"]["critical"]} critical vulnerabilities found!'}

### High Vulnerabilities: {metrics['security']['high']}
{'✅ No high vulnerabilities found' if metrics['security']['high'] == 0 else f'⚠️ {metrics["security"]["high"]} high vulnerabilities found!'}

### Medium Vulnerabilities: {metrics['security']['medium']}
{'✅ No medium vulnerabilities found' if metrics['security']['medium'] == 0 else f'🟡 {metrics["security"]["medium"]} medium vulnerabilities found!'}

### Low Vulnerabilities: {metrics['security']['low']}
{'✅ No low vulnerabilities found' if metrics['security']['low'] == 0 else f'🔵 {metrics["security"]["low"]} low vulnerabilities found!'}

### Overall Security Status:
**Total Vulnerabilities:** {metrics['security']['total']}  
**Security Grade:** {'🟢 EXCELLENT' if metrics['security']['total'] == 0 else '🟡 NEEDS ATTENTION' if metrics['security']['total'] < 5 else '🔴 CRITICAL'}

{'**✅ Repository is secure - no vulnerabilities detected!**' if metrics['security']['total'] == 0 else f'**⚠️ {metrics["security"]["total"]} vulnerabilities need attention**'}"""
                    }
                },
                # Panel 7: Code Quality Details
                {
                    "id": 7,
                    "title": "📝 Detailed Code Quality Issues",
                    "type": "text",
                    "gridPos": {"h": 8, "w": 12, "x": 12, "y": 12},
                    "options": {
                        "mode": "markdown",
                        "content": f"""## 📝 Code Quality Analysis

### TODO/FIXME Comments: {metrics['quality']['todo_comments']}
{'✅ No TODO/FIXME comments found - code is clean!' if metrics['quality']['todo_comments'] == 0 else f'⚠️ {metrics["quality"]["todo_comments"]} TODO/FIXME comments need attention'}

### Debug Statements: {metrics['quality']['debug_statements']}
{'✅ No debug statements found - production ready!' if metrics['quality']['debug_statements'] == 0 else f'🔧 {metrics["quality"]["debug_statements"]} debug statements should be removed'}

### Large Files (>1MB): {metrics['quality']['large_files']}
{'✅ No large files found - optimized!' if metrics['quality']['large_files'] == 0 else f'📦 {metrics["quality"]["large_files"]} large files need optimization'}

### Quality Score: {metrics['quality']['quality_score']}/100
**Grade:** {'🟢 EXCELLENT' if metrics['quality']['quality_score'] >= 90 else '🟡 GOOD' if metrics['quality']['quality_score'] >= 70 else '🔴 NEEDS IMPROVEMENT'}

### Total Improvements Needed: {metrics['quality']['total_improvements']}
{'✅ No improvements needed - code is excellent!' if metrics['quality']['total_improvements'] == 0 else f'🎯 {metrics["quality"]["total_improvements"]} improvements suggested'}"""
                    }
                },
                # Panel 8: Large Files Details
                {
                    "id": 8,
                    "title": "📦 Large Files Details (Need Optimization)",
                    "type": "text",
                    "gridPos": {"h": 8, "w": 12, "x": 0, "y": 20},
                    "options": {
                        "mode": "markdown",
                        "content": f"""## 📦 Large Files Requiring Optimization

**Total Large Files:** {metrics['quality']['large_files']} files > 1MB

### Optimization Recommendations:
- **ML Models:** Consider using model compression or external storage
- **Datasets:** Use data compression or chunked loading
- **Log Files:** Implement log rotation and cleanup
- **Cache Files:** Consider cleanup policies

**Priority:** {'✅ No optimization needed' if metrics['quality']['large_files'] == 0 else '🟡 LOW' if metrics['quality']['large_files'] < 10 else '🔴 HIGH'} - Performance optimization {'not needed' if metrics['quality']['large_files'] == 0 else 'recommended'}

**Note:** Large files can impact repository performance and clone times."""
                    }
                },
                # Panel 9: Test Results Details
                {
                    "id": 9,
                    "title": "🧪 Detailed Test Results",
                    "type": "text",
                    "gridPos": {"h": 8, "w": 12, "x": 12, "y": 20},
                    "options": {
                        "mode": "markdown",
                        "content": f"""## 🧪 Test Results Analysis

### Tests Passed: {metrics['tests']['passed']}
{'✅ All tests are passing!' if metrics['tests']['failed'] == 0 and metrics['tests']['passed'] > 0 else f'✅ {metrics["tests"]["passed"]} tests passed successfully' if metrics['tests']['passed'] > 0 else '⚠️ No tests found'}

### Tests Failed: {metrics['tests']['failed']}
{'✅ No test failures - excellent!' if metrics['tests']['failed'] == 0 else f'🚨 {metrics["tests"]["failed"]} tests failed and need attention'}

### Test Coverage: {metrics['tests']['coverage']}%
**Coverage Grade:** {'🟢 EXCELLENT' if metrics['tests']['coverage'] >= 90 else '🟡 GOOD' if metrics['tests']['coverage'] >= 70 else '🔴 NEEDS IMPROVEMENT'}

### Test Summary:
- **Total Tests:** {metrics['tests']['passed'] + metrics['tests']['failed']}
- **Success Rate:** {((metrics['tests']['passed'] / max(1, metrics['tests']['passed'] + metrics['tests']['failed'])) * 100):.1f}%
- **Quality:** {'🟢 EXCELLENT' if metrics['tests']['failed'] == 0 and metrics['tests']['coverage'] >= 80 else '🟡 GOOD' if metrics['tests']['failed'] <= 1 else '🔴 NEEDS ATTENTION'}

{'**✅ Test suite is healthy with good coverage!**' if metrics['tests']['failed'] == 0 and metrics['tests']['coverage'] >= 80 else '**⚠️ Test suite needs attention**'}"""
                    }
                }
            ],
            "time": {"from": "now-1h", "to": "now"}
        },
        "overwrite": True
    }
    
    # Deploy to Grafana
    try:
        response = requests.post(
            f"{GRAFANA_URL}/api/dashboards/db",
            headers={'Content-Type': 'application/json'},
            auth=(GRAFANA_USER, GRAFANA_PASS),
            data=json.dumps(dashboard_json),
            timeout=30
        )
        
        if response.status_code == 200:
            result = response.json()
            dashboard_uid = result.get('uid', dashboard_uid)
            dashboard_slug = result.get('slug', repo_name.lower().replace(' ', '-'))
            dashboard_url = f"{GRAFANA_URL}/d/{dashboard_uid}/{dashboard_slug}"
            
            print("=" * 80)
            print("✅ DASHBOARD CREATED SUCCESSFULLY!")
            print("=" * 80)
            print(f"Repository: {repo_name}")
            print(f"Dashboard URL: {dashboard_url}")
            print(f"Dashboard UID: {dashboard_uid}")
            print("")
            print("📊 METRICS SUMMARY:")
            print(f"  Security: {metrics['security']['total']} vulnerabilities")
            print(f"  Quality: {metrics['quality']['total_improvements']} improvements needed")
            print(f"  Tests: {metrics['tests']['passed']} passed, {metrics['tests']['failed']} failed")
            print(f"  Files Scanned: {metrics['scan_info']['files_scanned']}")
            print("=" * 80)
            
            return dashboard_url
        else:
            print(f"❌ Failed to create dashboard: {response.status_code}")
            print(f"Response: {response.text}")
            return None
            
    except Exception as e:
        print(f"❌ Error creating dashboard: {e}")
        return None

def create_jira_issue_with_dashboard(repo_info, dashboard_url, metrics):
    """Create Jira issue with link to the specific dashboard"""
    
    # Get Jira environment variables
    jira_url = os.environ.get('JIRA_URL', '').strip()
    jira_email = os.environ.get('JIRA_EMAIL', '').strip()
    jira_api_token = os.environ.get('JIRA_API_TOKEN', '').strip()
    jira_project_key = os.environ.get('JIRA_PROJECT_KEY', '').strip()
    
    # Validate required fields
    if not all([jira_url, jira_email, jira_api_token, jira_project_key]):
        print("⚠️ Missing Jira credentials - skipping Jira issue creation")
        return None
    
    # Add https:// if scheme is missing
    if not jira_url.startswith(('http://', 'https://')):
        jira_url = 'https://' + jira_url
    
    # Ensure URL ends with /rest/api/2/issue
    if not jira_url.endswith('/rest/api/2/issue'):
        if jira_url.endswith('/'):
            jira_url = jira_url + 'rest/api/2/issue'
        else:
            jira_url = jira_url + '/rest/api/2/issue'
    
    repo_name = repo_info['name']
    repo_url = repo_info['url']
    repo_branch = repo_info['branch']
    scan_type = repo_info['scan_type']
    
    github_run_id = os.environ.get('GITHUB_RUN_ID', 'Unknown')
    github_run_number = os.environ.get('GITHUB_RUN_NUMBER', 'Unknown')
    current_time = datetime.now().strftime("%Y-%m-%d %H:%M:%S UTC")
    
    # Get large files list for Jira
    large_files_section = get_large_files_list_for_jira()
    
    # Create detailed description
    description = f"""
🔍 **EXTERNAL REPOSITORY SCAN REPORT**
----

**Repository Being Scanned:**
• **Name:** {repo_name}
• **URL:** {repo_url}
• **Link:** [{repo_name}]({repo_url})
• **Branch:** {repo_branch}
• **Scan Type:** {scan_type}
• **Scan Time:** {current_time}

**Pipeline Information:**
• Run ID: {github_run_id}
• Run Number: #{github_run_number}
• Workflow: External Repository Security Scan
• Status: ✅ Completed

**📊 DEDICATED DASHBOARD FOR THIS REPOSITORY:**
• 🎯 [View {repo_name} Dashboard]({dashboard_url})
• This dashboard shows real-time metrics specific to {repo_name}

**Links:**
• 🔗 [View Scanned Repository]({repo_url})
• 📊 [Pipeline Dashboard for {repo_name}]({dashboard_url})
• ⚙️ [Pipeline Logs](https://github.com/almightymoon/Pipeline/actions/runs/{github_run_id})

**Security Scan Results:**
• Total Vulnerabilities: {metrics['security']['total']}
• Critical: {metrics['security']['critical']}
• High: {metrics['security']['high']}
• Medium: {metrics['security']['medium']}
• Low: {metrics['security']['low']}
• Status: {'🟢 SECURE' if metrics['security']['total'] == 0 else '🔴 NEEDS ATTENTION'}

**📊 Code Quality Analysis:**
• TODO/FIXME Comments: {metrics['quality']['todo_comments']}
• Debug Statements: {metrics['quality']['debug_statements']}
• Large Files (>1MB): {metrics['quality']['large_files']}
{large_files_section}
• Quality Score: {metrics['quality']['quality_score']}/100
• Total Improvements Needed: {metrics['quality']['total_improvements']}

**🧪 Test Results:**
• Tests Passed: {metrics['tests']['passed']}
• Tests Failed: {metrics['tests']['failed']}
• Test Coverage: {metrics['tests']['coverage']}%
• Success Rate: {((metrics['tests']['passed'] / max(1, metrics['tests']['passed'] + metrics['tests']['failed'])) * 100):.1f}%

**📁 Scan Metrics:**
• Files Scanned: {metrics['scan_info']['files_scanned']}
• Repository Size: {metrics['scan_info']['repository_size']}
• Pipeline Run: #{metrics['scan_info']['pipeline_run']}

**🎯 Priority Actions Required:**
{'• ✅ No critical issues found - repository is in good shape!' if metrics['security']['total'] == 0 and metrics['tests']['failed'] == 0 else ''}
{'• 🚨 Address ' + str(metrics['security']['critical']) + ' critical security vulnerabilities' if metrics['security']['critical'] > 0 else ''}
{'• ⚠️ Fix ' + str(metrics['tests']['failed']) + ' failing tests' if metrics['tests']['failed'] > 0 else ''}
{'• 🔧 Address ' + str(metrics['quality']['total_improvements']) + ' code quality improvements' if metrics['quality']['total_improvements'] > 0 else ''}

**Next Steps:**
1. Review the dedicated dashboard at {dashboard_url}
2. Check security findings in pipeline logs
3. Address any critical vulnerabilities found
4. Implement code quality improvements in {repo_name}
5. Update scanned repository if security issues are discovered

----
*This issue was automatically created by the External Repository Scanner Pipeline*
*Scanned Repository: {repo_name} | URL: {repo_url}*
*Dedicated Dashboard: {dashboard_url}*
"""
    
    # Prepare the payload
    payload = {
        "fields": {
            "project": {
                "key": jira_project_key
            },
            "summary": f"🔍 Pipeline Scan Complete: {repo_name} - {current_time}",
            "description": description,
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
            print("=" * 80)
            print("✅ JIRA ISSUE CREATED SUCCESSFULLY!")
            print("=" * 80)
            print(f"Issue Key: {issue_key}")
            print(f"Repository: {repo_name}")
            print(f"Dashboard Link: {dashboard_url}")
            print("=" * 80)
            return issue_key
        else:
            print(f"❌ Failed to create Jira issue. Status code: {response.status_code}")
            print(f"Response: {response.text}")
            return None
            
    except Exception as e:
        print(f"❌ Error creating Jira issue: {str(e)}")
        return None

def main():
    """Main function to create dashboard and Jira issue"""
    
    print("=" * 80)
    print("CREATING REPOSITORY-SPECIFIC DASHBOARD AND JIRA ISSUE")
    print("=" * 80)
    
    # Step 1: Read current repository configuration
    repo_info = read_current_repo()
    print(f"\n📁 Repository: {repo_info['name']}")
    print(f"🔗 URL: {repo_info['url']}")
    print(f"🌿 Branch: {repo_info['branch']}")
    
    # Step 2: Get real-time metrics from pipeline
    print("\n📊 Collecting metrics from pipeline run...")
    metrics = get_repo_metrics_from_pipeline()
    
    # Step 3: Create unique dashboard for this repository
    print(f"\n🎨 Creating dashboard for {repo_info['name']}...")
    dashboard_url = create_dashboard_for_repo(repo_info, metrics)
    
    if not dashboard_url:
        print("❌ Failed to create dashboard. Exiting.")
        return 1
    
    # Step 4: Create Jira issue with dashboard link
    print(f"\n📋 Creating Jira issue with dashboard link...")
    issue_key = create_jira_issue_with_dashboard(repo_info, dashboard_url, metrics)
    
    if issue_key:
        print("\n✅ ALL TASKS COMPLETED SUCCESSFULLY!")
        print(f"   Dashboard: {dashboard_url}")
        print(f"   Jira Issue: {issue_key}")
    else:
        print("\n⚠️ Dashboard created but Jira issue creation failed or was skipped")
        print(f"   Dashboard: {dashboard_url}")
    
    return 0

if __name__ == "__main__":
    sys.exit(main())

