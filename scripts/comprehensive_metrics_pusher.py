#!/usr/bin/env python3
"""
Comprehensive Metrics Pusher for Prometheus
Generates and pushes ALL metrics needed by the Grafana dashboard
Including fallbacks for missing data
"""

import os
import json
import requests
import re
from datetime import datetime

def main():
    """Main function"""
    print("=" * 60)
    print("🚀 Comprehensive Metrics Pusher for Prometheus")
    print("=" * 60)
    
    pushgateway_url = os.environ.get('PROMETHEUS_PUSHGATEWAY_URL', 'http://213.109.162.134:30091')
    
    if not pushgateway_url.startswith(('http://', 'https://')):
        pushgateway_url = 'http://' + pushgateway_url
    
    # Collect all metrics
    metrics = collect_all_metrics()
    
    # Push to Prometheus
    push_metrics(metrics, pushgateway_url)
    
    print("\n✅ Comprehensive metrics push completed!")

def read_quality_results():
    """Read quality metrics from quality-results.txt"""
    metrics = {}
    quality_files = ['/tmp/quality-results.txt', '/tmp/scan-results/quality-results.txt', 'quality-results.txt']
    
    for quality_file in quality_files:
        if os.path.exists(quality_file):
            try:
                with open(quality_file, 'r') as f:
                    content = f.read()
                    
                # Extract TODO comments (try multiple patterns)
                todo_match = re.search(r'TODO.*?comments?:\s*(\d+)', content, re.IGNORECASE)
                if not todo_match:
                    todo_match = re.search(r'TODO/FIXME.*?:\s*(\d+)', content, re.IGNORECASE)
                if todo_match:
                    metrics['todo_comments'] = int(todo_match.group(1))
                
                # Extract debug statements (try multiple patterns)
                debug_match = re.search(r'Debug.*?statements?:\s*(\d+)', content, re.IGNORECASE)
                if not debug_match:
                    debug_match = re.search(r'Debug.*?:\s*(\d+)', content, re.IGNORECASE)
                if debug_match:
                    metrics['debug_statements'] = int(debug_match.group(1))
                
                # Extract large files (try multiple patterns)
                large_files_match = re.search(r'Large files?.*?\(>1MB\):\s*(\d+)', content, re.IGNORECASE)
                if not large_files_match:
                    large_files_match = re.search(r'Large files?.*?:\s*(\d+)', content, re.IGNORECASE)
                if large_files_match:
                    metrics['large_files'] = int(large_files_match.group(1))
                
                # If we found at least one metric, we can stop looking
                if metrics:
                    print(f"✅ Read quality results from {quality_file}")
                    break
                    
            except Exception as e:
                print(f"⚠️  Error reading quality results from {quality_file}: {e}")
                continue
    
    # Set defaults if not found
    metrics.setdefault('todo_comments', 0)
    metrics.setdefault('debug_statements', 0)
    metrics.setdefault('large_files', 0)
    
    return metrics

if __name__ == "__main__":
    main()

if __name__ == "__main__":
    main()

def read_trivy_results():
    """Read security metrics from Trivy results"""
    metrics = {
        'CRITICAL': 0,
        'HIGH': 0,
        'MEDIUM': 0,
        'LOW': 0,
        'total': 0
    }
    
    trivy_files = ['trivy-results.json', '/tmp/trivy-results.json', '/tmp/scan-results/trivy-results.json']
    
    for trivy_file in trivy_files:
        if os.path.exists(trivy_file):
            try:
                with open(trivy_file, 'r') as f:
                    trivy_data = json.load(f)
                
                if 'Results' in trivy_data:
                    for result in trivy_data['Results']:
                        if 'Vulnerabilities' in result:
                            for vuln in result['Vulnerabilities']:
                                severity = vuln.get('Severity', '').upper()
                                metrics['total'] += 1
                                if severity in metrics:
                                    metrics[severity] += 1
                break
            except Exception as e:
                print(f"⚠️  Error reading Trivy file {trivy_file}: {e}")
                continue
    
    return metrics

def read_test_results():
    """Read test coverage from test results files"""
    coverage = 0.0
    source = None
    
    # JSON formats
    json_files = [
        '/tmp/test-results.json',
        '/tmp/scan-results/test-results.json',
        'test-results.json'
    ]
    for test_file in json_files:
        if os.path.exists(test_file):
            try:
                with open(test_file, 'r') as f:
                    test_data = json.load(f)
                if isinstance(test_data, dict):
                    if 'coverage' in test_data:
                        coverage = float(test_data['coverage'])
                        source = test_file
                    elif 'tests' in test_data and isinstance(test_data['tests'], dict):
                        coverage = float(test_data['tests'].get('coverage', 0.0))
                        source = test_file
                    elif 'summary' in test_data and isinstance(test_data['summary'], dict) and 'coverage' in test_data['summary']:
                        coverage = float(test_data['summary']['coverage'])
                        source = test_file
                if coverage > 0:
                    break
            except Exception as e:
                print(f"⚠️  Error reading test results JSON from {test_file}: {e}")
                continue
    
    # Cobertura / coverage.xml
    if coverage == 0.0:
        xml_files = [
            '/tmp/coverage.xml',
            '/tmp/scan-results/coverage.xml',
            'coverage.xml'
        ]
        for xml_path in xml_files:
            if os.path.exists(xml_path):
                try:
                    import xml.etree.ElementTree as ET
                    tree = ET.parse(xml_path)
                    root = tree.getroot()
                    # Cobertura schema: coverage line-rate="0.82"
                    line_rate = root.attrib.get('line-rate') or root.attrib.get('line_rate')
                    if line_rate is not None:
                        coverage = float(line_rate) * 100.0
                        source = xml_path
                        break
                    # pytest-cov xml: packages/package/classes/class lines-valid / lines-covered
                    lines_valid = root.attrib.get('lines-valid') or root.attrib.get('lines_valid')
                    lines_covered = root.attrib.get('lines-covered') or root.attrib.get('lines_covered')
                    if lines_valid and lines_covered:
                        lv = float(lines_valid)
                        lc = float(lines_covered)
                        if lv > 0:
                            coverage = (lc / lv) * 100.0
                            source = xml_path
                            break
                except Exception as e:
                    print(f"⚠️  Error parsing XML coverage from {xml_path}: {e}")
                    continue
    
    # LCOV
    if coverage == 0.0:
        lcov_files = [
            '/tmp/lcov.info',
            '/tmp/scan-results/lcov.info',
            'lcov.info'
        ]
        for lcov_path in lcov_files:
            if os.path.exists(lcov_path):
                try:
                    lines_found = 0
                    lines_hit = 0
                    with open(lcov_path, 'r') as f:
                        for line in f:
                            if line.startswith('LF:'):
                                lines_found += int(line.strip().split(':')[1])
                            elif line.startswith('LH:'):
                                lines_hit += int(line.strip().split(':')[1])
                    if lines_found > 0:
                        coverage = (lines_hit / lines_found) * 100.0
                        source = lcov_path
                        break
                except Exception as e:
                    print(f"⚠️  Error parsing LCOV from {lcov_path}: {e}")
                    continue
    
    # Text summaries
    if coverage == 0.0:
        text_files = [
            '/tmp/test-results.txt',
            '/tmp/scan-results/test-results.txt',
            '/tmp/quality-results.txt',
            'test-results.txt'
        ]
        import re
        for txt in text_files:
            if os.path.exists(txt):
                try:
                    with open(txt, 'r') as f:
                        content = f.read()
                    m = re.search(r'(Coverage|TOTAL).*?([0-9]+\.?[0-9]*)%?', content, re.IGNORECASE)
                    if m:
                        coverage = float(m.group(2))
                        source = txt
                        break
                except Exception as e:
                    print(f"⚠️  Error parsing text coverage from {txt}: {e}")
                    continue
    
    # Normalize and log
    if coverage < 0:
        coverage = 0.0
    if coverage > 100:
        coverage = 100.0
    print(f"📊 Coverage resolved: {coverage:.2f}%{f' from {source}' if source else ''}")
    return coverage

def get_sonarqube_metrics():
    """Get SonarQube metrics via API"""
    metrics = {
        'coverage': 0.0,
        'bugs': 0,
        'vulnerabilities': 0,
        'code_smells': 0,
        'issues_by_severity': {}
    }
    
    sonar_url = os.environ.get('SONARQUBE_URL', 'http://213.109.162.134:30100')
    sonar_token = os.environ.get('SONARQUBE_TOKEN', '')
    project_key = os.environ.get('REPO_NAME', 'my-qaicb-repo')
    
    if not sonar_token:
        print("⚠️  No SonarQube token, skipping SonarQube metrics")
        return metrics
    
    try:
        # Get measures (coverage, bugs, vulnerabilities, code_smells)
        response = requests.get(
            f"{sonar_url}/api/measures/component",
            params={
                'component': project_key,
                'metricKeys': 'coverage,bugs,vulnerabilities,code_smells,maintainability_rating,reliability_rating,security_rating'
            },
            auth=(sonar_token, ""),
            timeout=10
        )
        
        if response.status_code == 200:
            data = response.json()
            if 'component' in data and 'measures' in data['component']:
                for measure in data['component']['measures']:
                    metric_name = measure['metric']
                    metric_value = measure['value']
                    
                    if metric_name == 'coverage':
                        metrics['coverage'] = float(metric_value)
                    elif metric_name == 'bugs':
                        metrics['bugs'] = int(metric_value)
                    elif metric_name == 'vulnerabilities':
                        metrics['vulnerabilities'] = int(metric_value)
                    elif metric_name == 'code_smells':
                        metrics['code_smells'] = int(metric_value)
        
        # Get issues by severity
        issues_response = requests.get(
            f"{sonar_url}/api/issues/search",
            params={
                'componentKeys': project_key,
                'resolved': 'false',
                'facets': 'severities'
            },
            auth=(sonar_token, ""),
            timeout=10
        )
        
        if issues_response.status_code == 200:
            issues_data = issues_response.json()
            if 'facets' in issues_data:
                for facet in issues_data['facets']:
                    if facet['property'] == 'severities':
                        for value in facet['values']:
                            severity = value['val']
                            count = value['count']
                            metrics['issues_by_severity'][severity] = count
                            print(f"📊 Issues {severity}: {count}")
                            
    except Exception as e:
        print(f"⚠️  Error fetching SonarQube metrics: {e}")
    
    return metrics

def fetch_sonarqube_issues(project_key: str) -> list:
    """Fetch open issues from SonarQube and return metric lines per issue.
    Each metric is: sonarqube_issue_info{project, key, type, severity, file, line} 1
    """
    sonar_url = os.environ.get('SONARQUBE_URL', 'http://213.109.162.134:30100')
    sonar_token = os.environ.get('SONARQUBE_TOKEN')
    metrics = []
    if not sonar_token:
        return metrics
    try:
        params = {
            'componentKeys': project_key,
            'resolved': 'false',
            'p': 1,
            'ps': 100
        }
        while True:
            resp = requests.get(f"{sonar_url}/api/issues/search", params=params, auth=(sonar_token, ''), timeout=15)
            if resp.status_code != 200:
                break
            data = resp.json()
            for issue in data.get('issues', []):
                key = issue.get('key', '')
                itype = issue.get('type', '')
                sev = issue.get('severity', '')
                comp = issue.get('component', '')
                text_range = issue.get('textRange') or {}
                line = str(text_range.get('startLine', ''))
                # trim project prefix from component to get relative path
                file_path = comp.split(':', 1)[-1]
                label = f'sonarqube_issue_info{{project="{project_key}",key="{key}",type="{itype}",severity="{sev}",file="{file_path}",line="{line}"}} 1'
                metrics.append(label)
            # paging
            paging = data.get('paging', {})
            page_index = paging.get('pageIndex', params['p'])
            page_size = paging.get('pageSize', params['ps'])
            total = paging.get('total', 0)
            if page_index * page_size >= total:
                break
            params['p'] = page_index + 1
    except Exception as e:
        print(f"⚠️  Error fetching SonarQube issues: {e}")
    return metrics

def calculate_build_duration():
    """Calculate actual build duration from workflow start time"""
    duration_seconds = 300  # Default fallback
    
    # Method 1: Try to read from a file that might contain start time
    start_time_file = '/tmp/workflow_start_time.txt'
    if os.path.exists(start_time_file):
        try:
            with open(start_time_file, 'r') as f:
                start_time_str = f.read().strip()
                start_time = datetime.fromisoformat(start_time_str.replace('Z', '+00:00'))
                duration_seconds = int((datetime.now(start_time.tzinfo) - start_time).total_seconds())
                print(f"⏱️  Build duration from start time file: {duration_seconds} seconds")
                return max(1, duration_seconds)
        except Exception as e:
            print(f"⚠️  Could not read start time from file: {e}")
    
    # Method 2: Try to get from GitHub Actions API (requires GITHUB_TOKEN)
    github_token = os.environ.get('GITHUB_TOKEN', '')
    github_repo = os.environ.get('GITHUB_REPOSITORY', '')
    github_run_id = os.environ.get('GITHUB_RUN_ID', '')
    
    if github_token and github_repo and github_run_id:
        try:
            # Query GitHub API for workflow run details
            api_url = f"https://api.github.com/repos/{github_repo}/actions/runs/{github_run_id}"
            headers = {'Authorization': f'token {github_token}', 'Accept': 'application/vnd.github.v3+json'}
            response = requests.get(api_url, headers=headers, timeout=10)
            
            if response.status_code == 200:
                run_data = response.json()
                created_at = run_data.get('created_at', '')
                updated_at = run_data.get('updated_at', '')
                
                if created_at and updated_at:
                    start_time = datetime.fromisoformat(created_at.replace('Z', '+00:00'))
                    end_time = datetime.fromisoformat(updated_at.replace('Z', '+00:00'))
                    duration_seconds = int((end_time - start_time).total_seconds())
                    print(f"⏱️  Build duration from GitHub API: {duration_seconds} seconds")
                    return max(1, duration_seconds)
        except Exception as e:
            print(f"⚠️  Could not get duration from GitHub API: {e}")
    
    # Method 3: Try to read from test results or other files that might have duration
    # For now, use a reasonable default
    print(f"⚠️  No start time found, using default duration of {duration_seconds} seconds")
    print(f"💡 Tip: Add a step early in workflow to save start time: echo $(date -u +%Y-%m-%dT%H:%M:%SZ) > /tmp/workflow_start_time.txt")
    
    # Ensure minimum duration of 1 second
    return max(1, duration_seconds)

def collect_all_metrics():
    """Collect all metrics from all sources"""
    
    repository = os.environ.get('REPO_NAME', 'my-qaicb-repo')
    github_run_id = os.environ.get('GITHUB_RUN_ID', 'unknown')
    github_run_number = os.environ.get('GITHUB_RUN_NUMBER', '0')
    
    print(f"📊 Collecting comprehensive metrics for: {repository}")
    print(f"   Repository name used in metrics: '{repository}'")
    print(f"   ⚠️  IMPORTANT: Dashboard queries must use EXACT repository name: '{repository}'")
    
    # Collect metrics from various sources
    quality_metrics = read_quality_results()
    security_metrics = read_trivy_results()
    sonarqube_metrics = get_sonarqube_metrics()
    test_coverage_from_files = read_test_results()
    
    # Use test coverage from files if available, otherwise use SonarQube coverage
    coverage = test_coverage_from_files if test_coverage_from_files > 0 else sonarqube_metrics.get('coverage', 0.0)
    
    # Calculate quality score based on metrics
    quality_score = max(0, min(100, 100 - (
        quality_metrics['todo_comments'] * 0.1 +
        quality_metrics['debug_statements'] * 0.05 +
        quality_metrics['large_files'] * 0.5 +
        security_metrics['CRITICAL'] * 5 +
        security_metrics['HIGH'] * 2 +
        sonarqube_metrics.get('bugs', 0) * 0.3 +
        sonarqube_metrics.get('vulnerabilities', 0) * 1
    )))
    
    # Calculate actual build duration
    build_duration = calculate_build_duration()
    
    # Build Prometheus metrics
    prom_metrics = []
    
    # Pipeline metrics - Build Number and Duration
    # Use github_run_number directly (it's the actual build number)
    build_number = int(github_run_number) if github_run_number.isdigit() else 1
    prom_metrics.extend([
        f'pipeline_runs_total{{repository="{repository}",status="total"}} {build_number}',
        f'pipeline_runs_total{{repository="{repository}",status="success"}} 1',
        f'pipeline_runs_total{{repository="{repository}",status="failure"}} 0',
        f'pipeline_run_number{{repository="{repository}"}} {build_number}',
        f'pipeline_run_status{{repository="{repository}"}} 1',
        f'external_repo_scan_total{{repository="{repository}",status="completed"}} 1',
        f'external_repo_scan_duration_seconds_sum{{repository="{repository}"}} {build_duration}',
        f'external_repo_scan_duration_seconds_count{{repository="{repository}"}} 1',
        f'external_repo_scan_duration_seconds_bucket{{repository="{repository}",le="300"}} {1 if build_duration <= 300 else 0}',
        f'external_repo_scan_duration_seconds_bucket{{repository="{repository}",le="600"}} {1 if build_duration <= 600 else 0}',
        f'external_repo_scan_duration_seconds_bucket{{repository="{repository}",le="+Inf"}} 1'
    ])
    
    # Quality metrics
    prom_metrics.extend([
        f'code_quality_todo_comments{{repository="{repository}"}} {quality_metrics["todo_comments"]}',
        f'quality_todo_comments{{repository="{repository}"}} {quality_metrics["todo_comments"]}',
        f'code_quality_debug_statements{{repository="{repository}"}} {quality_metrics["debug_statements"]}',
        f'quality_debug_statements{{repository="{repository}"}} {quality_metrics["debug_statements"]}',
        f'code_quality_large_files{{repository="{repository}"}} {quality_metrics["large_files"]}',
        f'quality_large_files{{repository="{repository}"}} {quality_metrics["large_files"]}',
        f'code_quality_score{{repository="{repository}"}} {int(quality_score)}',
        f'code_quality_total_improvements{{repository="{repository}"}} {quality_metrics["todo_comments"] + quality_metrics["debug_statements"] + quality_metrics["large_files"]}'
    ])
    
    # Security metrics - Security Vulnerabilities (required by dashboard)
    prom_metrics.extend([
        f'security_vulnerabilities_found{{repository="{repository}",severity="CRITICAL"}} {security_metrics["CRITICAL"]}',
        f'security_vulnerabilities_found{{repository="{repository}",severity="HIGH"}} {security_metrics["HIGH"]}',
        f'security_vulnerabilities_found{{repository="{repository}",severity="MEDIUM"}} {security_metrics["MEDIUM"]}',
        f'security_vulnerabilities_found{{repository="{repository}",severity="LOW"}} {security_metrics["LOW"]}',
        f'security_vulnerabilities_total{{repository="{repository}"}} {security_metrics["total"]}'
    ])

    # Trivy per-vulnerability info (plain English)
    trivy_details = collect_trivy_vulnerability_details(repository)
    if trivy_details:
        prom_metrics.extend(trivy_details)

    # SonarQube metrics (use coverage calculated above which includes test file data)
    prom_metrics.extend([
        f'sonarqube_coverage{{project="{repository}"}} {coverage}',
        f'sonarqube_bugs{{project="{repository}"}} {sonarqube_metrics.get("bugs", 0)}',
        f'sonarqube_vulnerabilities{{project="{repository}"}} {sonarqube_metrics.get("vulnerabilities", 0)}',
        f'sonarqube_code_smells{{project="{repository}"}} {sonarqube_metrics.get("code_smells", 0)}'
    ])

    # SonarQube per-issue metrics for clickable table
    issue_metrics = fetch_sonarqube_issues(repository)
    if issue_metrics:
        prom_metrics.extend(issue_metrics)
    
    # SonarQube issues by severity
    issues_by_severity = sonarqube_metrics.get('issues_by_severity', {})
    for severity in ['BLOCKER', 'CRITICAL', 'MAJOR', 'MINOR', 'INFO']:
        count = issues_by_severity.get(severity, 0)
        prom_metrics.append(f'sonarqube_issues_by_severity{{project="{repository}",severity="{severity}"}} {count}')
    
    # Test coverage metrics (multiple variations for dashboard compatibility)
    prom_metrics.extend([
        f'tests_coverage_percent{{repository="{repository}"}} {coverage}',
        f'tests_coverage_percentage{{repository="{repository}"}} {coverage}'
    ])
    
    # Test metrics (defaults)
    prom_metrics.extend([
        f'tests_passed{{repository="{repository}"}} 0',
        f'tests_failed{{repository="{repository}"}} 0'
    ])

    # Fetch and push per-issue metrics
    # issue_metrics = fetch_sonarqube_issues(repository) # This line is now redundant as it's integrated above
    # prom_metrics.extend(issue_metrics) # This line is now redundant as it's integrated above
    
    print(f"✅ Collected {len(prom_metrics)} metrics")
    print(f"  - Quality: TODO={quality_metrics['todo_comments']}, Debug={quality_metrics['debug_statements']}, Large={quality_metrics['large_files']}")
    print(f"  - Security: CRITICAL={security_metrics['CRITICAL']}, HIGH={security_metrics['HIGH']}, Total={security_metrics['total']}")
    print(f"  - SonarQube: Bugs={sonarqube_metrics.get('bugs', 0)}, Vulns={sonarqube_metrics.get('vulnerabilities', 0)}, Code Smells={sonarqube_metrics.get('code_smells', 0)}")
    print(f"  - SonarQube Issues by Severity: {issues_by_severity}")
    print(f"  - Coverage: {coverage}%")
    print(f"  - Quality Score: {int(quality_score)}")
    print(f"\n📋 Metrics summary for {repository}:")
    print(f"  ✅ pipeline_runs_total with status=total: {build_number}")
    print(f"  ✅ code_quality_score: {int(quality_score)}")
    print(f"  ✅ tests_coverage_percentage: {coverage}")
    print(f"  ✅ security_vulnerabilities_total: {security_metrics['total']}")
    print(f"  ✅ external_repo_scan_duration_seconds (sum/count): {build_duration}/1")
    print(f"\n🔍 DEBUG: Repository name being used: '{repository}'")
    print(f"🔍 DEBUG: Make sure dashboard uses exact same name: '{repository}'")
    
    return prom_metrics

def push_metrics(metrics, pushgateway_url):
    """Push metrics to Prometheus Pushgateway"""
    
    if not metrics:
        print("❌ No metrics to push")
        return
    
    # Prepare metrics payload
    metrics_payload = '\n'.join(metrics) + '\n'
    
    # Determine job and instance
    repository = os.environ.get('REPO_NAME', 'unknown')
    github_run_id = os.environ.get('GITHUB_RUN_ID', 'unknown')
    
    # Use repository name directly (don't clean it) to match dashboard queries exactly
    # The dashboard queries use the exact repository name from repos-to-scan.yaml
    job_name = f"pipeline-metrics"
    # Use "latest" as fixed instance so metrics persist and are queryable
    instance_latest = repository  # Use repository name as instance for easy querying
    instance_run = f"{repository}-run-{github_run_id}"  # Keep unique for history
    
    print(f"📤 Pushing metrics to Pushgateway...")
    print(f"   URL: {pushgateway_url}")
    print(f"   Repository: {repository}")
    print(f"   Job: {job_name}")
    print(f"   Instance (latest): {instance_latest}")
    print(f"   Instance (run): {instance_run}")
    
    success_count = 0
    
    # Push to BOTH instances:
    # 1. Fixed instance with repository name (for current/latest metrics - easier to query)
    # 2. Unique instance with run ID (for historical tracking)
    
    instances_to_push = [
        (instance_latest, "latest"),
        (instance_run, "historical")
    ]
    
    for instance, instance_type in instances_to_push:
        push_url = f"{pushgateway_url}/metrics/job/{job_name}/instance/{instance}"
        
        try:
            # Delete old metrics for this instance first (optional, but helps avoid stale data)
            # Pushgateway uses DELETE to remove old metrics before PUT replaces them
            if instance_type == "latest":
                delete_url = f"{pushgateway_url}/metrics/job/{job_name}/instance/{instance}"
                try:
                    requests.delete(delete_url, timeout=5)
                    print(f"   🗑️  Cleaned old metrics for {instance_type} instance")
                except:
                    pass  # Ignore delete errors, proceed with PUT
            
            response = requests.put(
                push_url,
                data=metrics_payload,
                headers={'Content-Type': 'text/plain'},
                timeout=30
            )
            
            if response.status_code == 200:
                success_count += 1
                print(f"   ✅ Pushed to {instance_type} instance successfully")
            else:
                print(f"   ⚠️  Failed to push to {instance_type} instance: HTTP {response.status_code}")
                
        except Exception as e:
            print(f"   ⚠️  Error pushing to {instance_type} instance: {e}")
    
    if success_count > 0:
        print(f"\n✅ Successfully pushed {len(metrics)} metrics to Prometheus")
        print(f"📊 View metrics at: {pushgateway_url}/metrics")
        print(f"\n🔍 IMPORTANT: Verify these details match dashboard queries:")
        print(f"   Repository name in metrics: '{repository}'")
        print(f"   Make sure dashboard queries use: repository=\"{repository}\"")
        print(f"   Job name: {job_name}")
        print(f"   Instance: {instance_latest}")
        
        # Verify metrics were actually stored in Pushgateway
        try:
            verify_url = f"{pushgateway_url}/metrics"
            verify_response = requests.get(verify_url, timeout=10)
            if verify_response.status_code == 200:
                metrics_text = verify_response.text
                # Check if our metrics are there
                repo_metrics_found = [m for m in metrics if repository in m]
                found_count = sum(1 for metric_line in repo_metrics_found if metric_line.split('{')[0].strip() in metrics_text)
                
                if found_count > 0:
                    print(f"   ✅ Verified: Found {found_count} metrics in Pushgateway for repository '{repository}'")
                    # Show a sample of found metrics
                    sample_metric = repo_metrics_found[0].split('{')[0].strip()
                    if sample_metric in metrics_text:
                        lines = metrics_text.split('\n')
                        matching = [l for l in lines if repository in l and sample_metric in l]
                        if matching:
                            print(f"   📊 Sample metric found:")
                            print(f"      {matching[0][:120]}...")
                else:
                    print(f"   ⚠️  Warning: Metrics pushed but not found in Pushgateway yet (may need a moment to appear)")
            else:
                print(f"   ⚠️  Could not verify metrics (HTTP {verify_response.status_code})")
        except Exception as e:
            print(f"   ⚠️  Could not verify metrics: {e}")
        
        print(f"\n🔍 Verification commands:")
        print(f"   curl -s '{pushgateway_url}/metrics' | grep 'repository=\"{repository}\"' | head -10")
        print(f"\n📋 Dashboard queries to verify (use these in Grafana/Prometheus):")
        print(f"   pipeline_runs_total{{repository=\"{repository}\",status=\"total\"}}")
        print(f"   code_quality_score{{repository=\"{repository}\"}}")
        print(f"   tests_coverage_percentage{{repository=\"{repository}\"}}")
        print(f"   security_vulnerabilities_total{{repository=\"{repository}\"}}")
        print(f"   external_repo_scan_duration_seconds_sum{{repository=\"{repository}\"}}")
        print(f"\n💡 Important: The repository name in queries MUST match exactly: '{repository}'")
    else:
        print(f"\n❌ Failed to push metrics to any instance")
        print(f"💡 Troubleshooting:")
        print(f"   1. Check Pushgateway is accessible: curl {pushgateway_url}/metrics")
        print(f"   2. Verify network connectivity to {pushgateway_url}")
        print(f"   3. Check Pushgateway logs for errors")
        print(f"   4. Verify repository name: '{repository}'")

    
def build_trivy_vulnerability_info_metrics(repository: str) -> list:
    """Return per-vulnerability Prometheus metrics with readable labels.
    security_vulnerability_info{repository, severity, id, pkg, installed, fixed, title} 1
    """
    metrics = []
    paths = ['trivy-results.json', '/tmp/trivy-results.json', '/tmp/scan-results/trivy-results.json']
    for path in paths:
        if not os.path.exists(path):
            continue
        try:
            with open(path, 'r') as f:
                data = json.load(f)
            if 'Results' not in data:
                continue
            for result in data['Results']:
                vulns = result.get('Vulnerabilities') or []
                for v in vulns:
                    sev = (v.get('Severity') or '').upper()
                    vid = v.get('VulnerabilityID', '')
                    pkg = v.get('PkgName', '')
                    inst = v.get('InstalledVersion', '')
                    fix = v.get('FixedVersion', '') or v.get('PrimaryURL', '')
                    title = v.get('Title', '') or v.get('Description', '')
                    # sanitize quotes
                    def esc(s: str) -> str:
                        return str(s).replace('"', '\\"')
                    metric = (
                        f'security_vulnerability_info{{repository="{esc(repository)}",severity="{esc(sev)}",id="{esc(vid)}",'
                        f'pkg="{esc(pkg)}",installed="{esc(inst)}",fixed="{esc(fix)}",title="{esc(title)}"}} 1'
                    )
                    metrics.append(metric)
            break
        except Exception as e:
            print(f"⚠️  Error building vulnerability info from {path}: {e}")
            continue
    return metrics

def collect_trivy_vuln_details(repository: str) -> list:
    """Read Trivy results and emit per-vulnerability metrics with readable labels.
    Metric: trivy_vuln_info{repository,id,package,installed,fixed,severity,title} 1
    """
    details = []
    trivy_files = ['trivy-results.json', '/tmp/trivy-results.json', '/tmp/scan-results/trivy-results.json']
    try:
        for trivy_file in trivy_files:
            if os.path.exists(trivy_file):
                with open(trivy_file, 'r') as f:
                    data = json.load(f)
                if 'Results' in data:
                    for result in data['Results']:
                        for vuln in result.get('Vulnerabilities', []) or []:
                            vid = (vuln.get('VulnerabilityID') or '').replace('"','\"')
                            pkg = (vuln.get('PkgName') or '').replace('"','\"')
                            installed = (vuln.get('InstalledVersion') or '').replace('"','\"')
                            fixed = (vuln.get('FixedVersion') or '').replace('"','\"')
                            severity = (vuln.get('Severity') or '').upper().replace('"','\"')
                            title = (vuln.get('Title') or vuln.get('Description') or '').replace('"','\"')
                            metric = (
                                f'trivy_vuln_info{{repository="{repository}",id="{vid}",package="{pkg}",installed="{installed}",'
                                f'fixed="{fixed}",severity="{severity}",title="{title}"}} 1'
                            )
                            details.append(metric)
                break
    except Exception as e:
        print(f"⚠️  Error collecting Trivy vuln details: {e}")
    return details

def parse_trivy_vulnerabilities(repository: str) -> list:
    """Parse trivy-results.json and emit per-issue metrics for human-readable dashboards.
    Metric form: security_vulnerability_info{repository,id,severity,package,installed,title} 1
    """
    issue_metrics = []
    trivy_files = ['trivy-results.json', '/tmp/trivy-results.json', '/tmp/scan-results/trivy-results.json']
    try:
        for trivy_file in trivy_files:
            if os.path.exists(trivy_file):
                with open(trivy_file, 'r') as f:
                    data = json.load(f)
                for result in data.get('Results', []):
                    for vuln in result.get('Vulnerabilities', []) or []:
                        vid = vuln.get('VulnerabilityID', '').replace('"', "'")
                        sev = vuln.get('Severity', '')
                        pkg = vuln.get('PkgName', '').replace('"', "'")
                        installed = vuln.get('InstalledVersion', '').replace('"', "'")
                        title = (vuln.get('Title') or vuln.get('Description') or 'Unknown').replace('"', "'")
                        label = (
                            f'security_vulnerability_info{{repository="{repository}",' 
                            f'id="{vid}",severity="{sev}",package="{pkg}",installed="{installed}",title="{title}"}} 1'
                        )
                        issue_metrics.append(label)
                break
    except Exception as e:
        print(f"⚠️  Error parsing per-issue vulnerabilities: {e}")
    return issue_metrics

def sanitize_label_value(value: str) -> str:
    if value is None:
        return ""
    # Prometheus label values cannot contain newlines or quotes easily; sanitize
    return str(value).replace('"', "'").replace('\n', ' ').replace('\r', ' ')[:200]

def collect_trivy_issue_metrics() -> list:
    """Create per-vulnerability metrics from Trivy results with human-readable labels."""
    files = ['trivy-results.json', '/tmp/trivy-results.json', '/tmp/scan-results/trivy-results.json']
    metrics = []
    for path in files:
        if os.path.exists(path):
            try:
                with open(path, 'r') as f:
                    data = json.load(f)
                for result in data.get('Results', []):
                    for vuln in result.get('Vulnerabilities', []) or []:
                        vid = sanitize_label_value(vuln.get('VulnerabilityID', ''))
                        pkg = sanitize_label_value(vuln.get('PkgName', ''))
                        sev = sanitize_label_value(vuln.get('Severity', ''))
                        title = sanitize_label_value(vuln.get('Title', ''))
                        version = sanitize_label_value(vuln.get('InstalledVersion', ''))
                        fixed = sanitize_label_value(vuln.get('FixedVersion', ''))
                        metric = (
                            f'trivy_vulnerability_info{{severity="{sev}",id="{vid}",package="{pkg}",version="{version}",fixed_version="{fixed}",title="{title}"}} 1'
                        )
                        metrics.append(metric)
                break
            except Exception as e:
                print(f"⚠️  Error building per-vulnerability metrics from {path}: {e}")
                continue
    return metrics

def collect_trivy_vulnerability_details(project_key: str) -> list:
    """Return per-vulnerability metrics with readable labels from Trivy results.
    Metric format:
    trivy_vulnerability_info{project, severity, id, pkg, version, title} 1
    """
    metrics = []
    trivy_files = ['trivy-results.json', '/tmp/trivy-results.json', '/tmp/scan-results/trivy-results.json', '/tmp/scan-results/trivy-fs-results.json']
    for path in trivy_files:
        if not os.path.exists(path):
            continue
        try:
            with open(path, 'r') as f:
                data = json.load(f)
            for result in data.get('Results', []):
                for vuln in result.get('Vulnerabilities', []) or []:
                    vid = vuln.get('VulnerabilityID', 'UNKNOWN').replace('"', "'")
                    pkg = vuln.get('PkgName', 'UNKNOWN').replace('"', "'")
                    title = (vuln.get('Title') or vuln.get('Description') or 'No title').replace('"', "'")
                    sev = vuln.get('Severity', 'UNKNOWN').upper()
                    ver = vuln.get('InstalledVersion', 'UNKNOWN').replace('"', "'")
                    metrics.append(
                        f'trivy_vulnerability_info{{project="{project_key}",severity="{sev}",id="{vid}",pkg="{pkg}",version="{ver}",title="{title}"}} 1'
                    )
            if metrics:
                break
        except Exception as e:
            print(f"⚠️  Error reading detailed Trivy vulnerabilities from {path}: {e}")
            continue
    return metrics

