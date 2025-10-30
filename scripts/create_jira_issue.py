#!/usr/bin/env python3
"""
Create Jira issue via API with dynamic dashboard creation
"""
import os
import sys
import requests
import json
import yaml
import hashlib
from datetime import datetime

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
        
        return {
            'url': os.environ.get('REPO_URL', 'https://github.com/example/repo'),
            'name': os.environ.get('REPO_NAME', 'example-repo'),
            'branch': os.environ.get('REPO_BRANCH', 'main'),
            'scan_type': 'full'
        }
    except Exception as e:
        print(f"Warning: Could not read repos-to-scan.yaml: {e}")
        return {
            'url': os.environ.get('REPO_URL', 'https://github.com/example/repo'),
            'name': os.environ.get('REPO_NAME', 'example-repo'),
            'branch': os.environ.get('REPO_BRANCH', 'main'),
            'scan_type': 'full'
        }

def generate_dashboard_uid(repo_name):
    """Generate a unique and consistent UID for each repository"""
    hash_object = hashlib.md5(repo_name.encode())
    hash_hex = hash_object.hexdigest()
    uid = f"{hash_hex[0:8]}-{hash_hex[8:12]}-{hash_hex[12:16]}-{hash_hex[16:20]}-{hash_hex[20:32]}"
    return uid

def get_dashboard_url_for_repo(repo_name):
    """Get the dashboard URL for the current repository (and create if needed)"""
    grafana_url = "http://213.109.162.134:30102"
    dashboard_uid = generate_dashboard_uid(repo_name)
    dashboard_slug = repo_name.lower().replace(' ', '-')
    dashboard_url = f"{grafana_url}/d/{dashboard_uid}/pipeline-dashboard-{dashboard_slug}"
    
    # Try to trigger dashboard creation by calling the creation script
    try:
        print(f"📊 Dashboard URL for {repo_name}: {dashboard_url}")
        print(f"💡 Tip: Run './create-repo-dashboard.sh' to create the dashboard with real-time metrics")
    except Exception as e:
        print(f"Note: Dashboard URL generated: {dashboard_url}")
    
    return dashboard_url

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
        
        # Also check current directory for Trivy results
        elif os.path.exists('trivy-results.json'):
            try:
                with open('trivy-results.json', 'r') as f:
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
        # Look for quality results in multiple locations
        quality_files = [
            '/tmp/quality-results.txt',
            '/tmp/scan-results/quality-results.txt',
            'quality-results.txt',
            'scan-results/quality-results.txt'
        ]
        
        quality_file = None
        for qf in quality_files:
            if os.path.exists(qf):
                quality_file = qf
                break
        
        if not quality_file:
            return None
            
        with open(quality_file, 'r') as f:
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

def get_detailed_vulnerability_list():
    """Get detailed list of vulnerabilities found"""
    try:
        vulnerability_details = []
        
        # Check Trivy results - look in multiple locations
        trivy_files = [
            'trivy-results.json',
            'trivy-fs-results.json', 
            '/tmp/trivy-results.json',
            '/tmp/trivy-fs-results.json',
            '/tmp/scan-results/trivy-results.json',
            '/tmp/scan-results/trivy-fs-results.json',
            'scan-results/trivy-results.json',
            'scan-results/trivy-fs-results.json'
        ]
        
        print(f"🔍 Looking for Trivy results in: {trivy_files}")
        
        for trivy_file in trivy_files:
            if os.path.exists(trivy_file):
                print(f"✅ Found Trivy results at: {trivy_file}")
                try:
                    with open(trivy_file, 'r') as f:
                        trivy_data = json.load(f)
                    
                    if 'Results' in trivy_data:
                        for result in trivy_data['Results']:
                            if 'Vulnerabilities' in result:
                                for vuln in result['Vulnerabilities']:
                                    vuln_id = vuln.get('VulnerabilityID', 'Unknown')
                                    pkg_name = vuln.get('PkgName', 'Unknown')
                                    severity = vuln.get('Severity', 'Unknown')
                                    title = vuln.get('Title', 'No title')
                                    
                                    # Format severity with emoji
                                    severity_emoji = {
                                        'CRITICAL': '🔴',
                                        'HIGH': '🟠', 
                                        'MEDIUM': '🟡',
                                        'LOW': '🟢'
                                    }.get(severity.upper(), '⚪')
                                    
                                    vulnerability_details.append(
                                        f"• {severity_emoji} **{severity}** | {vuln_id} in {pkg_name}: {title}"
                                    )
                    
                    if vulnerability_details:
                        result = f"Detailed Vulnerability List:\n*(Data source: {trivy_file})*\n" + "\n".join(vulnerability_details[:10])
                        if len(vulnerability_details) > 10:
                            result += f"\n• ... and {len(vulnerability_details) - 10} more vulnerabilities"
                        return result
                    else:
                        return f"Detailed Vulnerability List:\n*(Data source: {trivy_file})*\n• No vulnerabilities found in scan"
                        
                except Exception as e:
                    return "Detailed Vulnerability List:\n• Could not parse vulnerability details"
        
        # If no Trivy results, check for other security scan results
        if os.path.exists('/tmp/secrets-found.txt'):
            try:
                with open('/tmp/secrets-found.txt', 'r') as f:
                    secrets_content = f.read().strip()
                
                if secrets_content and "No secrets found" not in secrets_content and "Total secrets found: 0" not in secrets_content:
                    # Parse secret detection results
                    lines = secrets_content.split('\n')
                    secret_details = []
                    for line in lines:
                        if 'found:' in line and 'Total' not in line:
                            secret_details.append(f"• {line.strip()}")
                    
                    if secret_details:
                        return f"Detailed Vulnerability List:\n*(Data source: /tmp/secrets-found.txt)*\n" + "\n".join(secret_details)
                    else:
                        return "Detailed Vulnerability List:\n• Potential secrets detected (check pipeline logs for details)"
                else:
                    return "Detailed Vulnerability List:\n• No secrets found"
            except:
                pass
        
        return "Detailed Vulnerability List:\n• No vulnerability scan data available"
        
    except Exception as e:
        return "Detailed Vulnerability List:\n• Error retrieving vulnerability details"

def get_quality_analysis():
    """Get detailed quality analysis for Jira description"""
    try:
        # Check multiple locations for quality results
        quality_files = [
            '/tmp/quality-results.txt',
            '/tmp/scan-results/quality-results.txt',
            'quality-results.txt',
            'scan-results/quality-results.txt'
        ]
        
        print(f"🔍 Looking for quality results in: {quality_files}")
        
        for quality_file in quality_files:
            if os.path.exists(quality_file):
                print(f"✅ Found quality results at: {quality_file}")
                with open(quality_file, 'r') as f:
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
                        analysis_lines.append("• No TODO/FIXME comments found")
                
                # Debug statements
                debug_match = re.search(r'Debug statements: (\d+)', content)
                if debug_match:
                    count = int(debug_match.group(1))
                    if count > 0:
                        analysis_lines.append(f"• {count} debug statements found (remove before production)")
                    else:
                        analysis_lines.append("• No debug statements found")
                
                # Large files
                large_match = re.search(r'Large files \(>1MB\): (\d+)', content)
                repo_large_files = list_large_files()
                repo_large_count = len(repo_large_files)
                if large_match:
                    reported_count = int(large_match.group(1))
                    # Prefer the live repository count; show discrepancy if any
                    if repo_large_count > 0:
                        if repo_large_count != reported_count:
                            analysis_lines.append(
                                f"• {repo_large_count} large files in repository source (quality report indicated {reported_count})"
                            )
                        else:
                            analysis_lines.append(f"• {repo_large_count} large files found (consider optimization)")
                        analysis_lines.append("  Large file examples:")
                        for path, size_str in repo_large_files[:10]:
                            analysis_lines.append(f"  • {path} ({size_str})")
                    else:
                        analysis_lines.append("• No large files found in repository source")
                else:
                    # No large count in quality file; still report repo-detected ones
                    if repo_large_count > 0:
                        analysis_lines.append(f"• {repo_large_count} large files found (consider optimization)")
                        analysis_lines.append("  Large file examples:")
                        for path, size_str in repo_large_files[:10]:
                            analysis_lines.append(f"  • {path} ({size_str})")
                
                # Total suggestions
                total_match = re.search(r'Total suggestions: (\d+)', content)
                if total_match:
                    total = int(total_match.group(1))
                    analysis_lines.append(f"• **Total improvements suggested: {total}**")
                
                if analysis_lines:
                    return f"*(Data source: {quality_file})*\n" + "\n".join(analysis_lines)
                else:
                    return f"*(Data source: {quality_file})*\n• No quality analysis data available - check pipeline logs"
        
        return "• Quality analysis not available (SonarQube server may be unreachable)"
            
    except Exception as e:
        return "• Quality analysis error (check logs for details)"

def list_large_files(min_bytes: int = 1_000_000) -> list:
    """Find large files that are part of the actual repository content.
    Priority: use git-tracked files under ./external-repo. Fall back to a
    cautious filesystem scan with strong exclusions to avoid tool caches.
    Returns list of tuples (relative_path, human_size) sorted by size desc.
    """
    repo_root = os.path.abspath('external-repo') if os.path.isdir('external-repo') else None

    # 1) Prefer git-tracked files (most accurate representation of repo content)
    results: list[tuple[str, int]] = []
    if repo_root:
        try:
            import subprocess
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
                fpath = os.path.join(repo_root, rel)
                try:
                    if os.path.isfile(fpath):
                        size = os.path.getsize(fpath)
                        if size >= min_bytes:
                            results.append((os.path.join('external-repo', rel), size))
                except Exception:
                    continue
        except Exception:
            # fall back to cautious scan below
            pass

    # 2) If git-based detection yielded nothing, do a cautious scan
    if not results:
        roots = [repo_root] if repo_root else [os.getcwd()]
        ignore_dirs = {
            '.git', 'node_modules', '.venv', 'venv', '__pycache__', '.pytest_cache', '.idea', '.vscode', '.cache',
            'sonar-scanner', 'sonar-scanner-4.8.0.2856-linux', 'trivy', 'trivy-db'
        }
        # Do not exclude by extension; if a big artifact is tracked, we should report it.
        ignore_exts = set()
        ignore_name_prefixes = {'vault_',}
        for root in roots:
            if not root:
                continue
            for dirpath, dirnames, filenames in os.walk(root):
                # prune ignored directories in-place
                dirnames[:] = [d for d in dirnames if d not in ignore_dirs]
                for fname in filenames:
                    # extension/name filters to avoid build artifacts and caches
                    low = fname.lower()
                    if any(low.endswith(ext) for ext in ignore_exts) or any(low.startswith(pfx) for pfx in ignore_name_prefixes):
                        continue
                    fpath = os.path.join(dirpath, fname)
                    try:
                        size = os.path.getsize(fpath)
                        if size >= min_bytes:
                            if repo_root:
                                rel = os.path.relpath(fpath, repo_root)
                                disp = os.path.join('external-repo', rel)
                            else:
                                disp = os.path.relpath(fpath, os.getcwd())
                            results.append((disp, size))
                    except Exception:
                        continue

    # sort by size desc and map to human readable size
    results.sort(key=lambda x: x[1], reverse=True)
    return [(p, _format_size(s)) for p, s in results]

def _format_size(num_bytes: int) -> str:
    units = ['B', 'KB', 'MB', 'GB', 'TB']
    size = float(num_bytes)
    idx = 0
    while size >= 1024 and idx < len(units) - 1:
        size /= 1024.0
        idx += 1
    if idx == 0:
        return f"{int(size)}{units[idx]}"
    return f"{size:.2f}{units[idx]}"

def get_priority_actions():
    """Get priority actions based on quality analysis"""
    try:
        # Check multiple locations for quality results
        quality_files = [
            '/tmp/quality-results.txt',
            '/tmp/scan-results/quality-results.txt',
            'quality-results.txt',
            'scan-results/quality-results.txt'
        ]
        
        for quality_file in quality_files:
            if os.path.exists(quality_file):
                with open(quality_file, 'r') as f:
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
                        priority = "HIGH"
                        action = f"Address {todo_count} TODO/FIXME comments - critical for code maintainability"
                    elif todo_count > 50:
                        priority = "MEDIUM"
                        action = f"Review and address {todo_count} TODO/FIXME comments"
                    else:
                        priority = "LOW"
                        action = f"Consider addressing {todo_count} TODO/FIXME comments"
                    actions.append(f"• {priority} | {action}")
                    
                if debug_count > 0:
                    if debug_count > 300:
                        priority = "HIGH"
                        action = f"Remove {debug_count} debug statements before production deployment"
                    elif debug_count > 100:
                        priority = "MEDIUM"
                        action = f"Clean up {debug_count} debug statements"
                    else:
                        priority = "LOW"
                        action = f"Review {debug_count} debug statements"
                    actions.append(f"• {priority} | {action}")
                    
                if large_files > 0:
                    if large_files > 10:
                        priority = "MEDIUM"
                        action = f"Optimize {large_files} large files for better performance"
                    else:
                        priority = "LOW"
                        action = f"Consider optimizing {large_files} large files"
                    actions.append(f"• {priority} | {action}")
                
                if not actions:
                    actions.append("• No immediate actions required - code quality is good")
                    
                return "\n".join(actions)
        
        return "• No priority actions available - check pipeline logs"
            
    except Exception as e:
        return "• Priority actions error (check logs for details)"

def get_scan_metrics():
    """Get dynamic scan metrics from the pipeline"""
    try:
        metrics = []
        
        # Check for metrics file
        metrics_files = ['/tmp/scan-metrics.txt', 'quality-results.txt', '/tmp/quality-results.txt']
        
        for metrics_file in metrics_files:
            if os.path.exists(metrics_file):
                with open(metrics_file, 'r') as f:
                    content = f.read()
                    
                # Extract metrics
                import re
                file_match = re.search(r'Total Files: (\d+)', content)
                line_match = re.search(r'Total Lines: (\d+)', content)
                size_match = re.search(r'Repository Size: (.+)', content)
                
                # Also check for quality results format
                if not file_match:
                    file_match = re.search(r'Files scanned: (\d+)', content)
                if not size_match:
                    size_match = re.search(r'Repository size: (.+)', content)
                
                if file_match:
                    metrics.append(f"Files scanned: {file_match.group(1)}")
                if line_match:
                    metrics.append(f"Lines analyzed: {line_match.group(1)}")
                if size_match:
                    metrics.append(f"Repository size: {size_match.group(1).strip()}")
                
                # Pipeline run
                run_match = re.search(r'Pipeline run: (#\d+)', content)
                if run_match:
                    metrics.append(f"Pipeline run: {run_match.group(1)}")
                
                if metrics:
                    return " • ".join(metrics)
        
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
    
    # Get repository info from repos-to-scan.yaml or environment
    repo_info = read_current_repo()
    repo_name = repo_info['name']
    repo_url = repo_info['url']
    repo_branch = repo_info['branch']
    scan_type = repo_info['scan_type']
    
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
    
    # Get the dynamic dashboard URL for this specific repository
    dashboard_url = get_dashboard_url_for_repo(repo_name)
    
    # Build repository link  
    if repo_url and repo_url != "Unknown":
        repo_link = f"[{repo_name}]({repo_url})"
    else:
        repo_link = repo_name
    
    # Compose repository large files section
    repo_large_files = list_large_files()
    if repo_large_files:
        repo_large_files_section = "\n".join([f"• {path} ({size})" for path, size in repo_large_files[:15]])
        repo_large_header = f"Large Files in Repository (top {min(15, len(repo_large_files))}):\n{repo_large_files_section}"
    else:
        repo_large_header = "No large files found in repository source"

    enhanced_description = f"""
{base_description}

----

🔍 *EXTERNAL REPOSITORY SCAN REPORT*

*Repository Being Scanned:*
• *Name:* {repo_name}
• *URL:* {repo_url}
• *Link:* {repo_link}
• *Branch:* {repo_branch}
• *Scan Type:* {scan_type}
• *Scan Time:* {current_time}

*Pipeline Information:*
• Run ID: {github_run_id}
• Run Number: {github_run_number}
• Workflow: External Repository Security Scan
• Status: ✅ Completed

*📊 DEDICATED DASHBOARD FOR THIS REPOSITORY:*
• 🎯 [View {repo_name} Dashboard]({dashboard_url})
• This dashboard shows real-time metrics specific to {repo_name}

*Links:*
• 🔗 [View Scanned Repository]({repo_url})
• 📊 [Pipeline Dashboard for {repo_name}]({dashboard_url})
• ⚙️ [Pipeline Logs](https://github.com/almightymoon/Pipeline/actions/runs/{github_run_id})

*Security Scan Results:*
• Status: {vulnerabilities_found}
• Issues Found: {security_issues}
• Scan Completed: ✅

{get_detailed_vulnerability_list()}

*📊 Code Quality Analysis - Detailed Breakdown:*

{get_quality_analysis()}

*🎯 Priority Actions Required:*
{get_priority_actions()}

*Scan Metrics:*
• {get_scan_metrics()}

*Repository Large Files (Source Only):*
{repo_large_header}

*Next Steps:*
1. Review the dedicated dashboard at {dashboard_url}
2. Check security findings in pipeline logs
3. Address any critical vulnerabilities found
4. Implement code quality improvements in *{repo_name}*
5. Update scanned repository if security issues are discovered

This issue was automatically created by the External Repository Scanner Pipeline
Scanned Repository: {repo_name} | URL: {repo_url}
Dedicated Dashboard: {dashboard_url}
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
