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
        import re as _re
        for txt in text_files:
            if os.path.exists(txt):
                try:
                    with open(txt, 'r') as f:
                        content = f.read()
                    m = _re.search(r'(Coverage|TOTAL).*?([0-9]+\.?[0-9]*)%?', content, _re.IGNORECASE)
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
    
    # Unit test metrics - ALWAYS push, even if 0
    print(f"\n🔍 STEP: Reading unit test metrics...")
    unit_test_metrics = read_unit_test_metrics()
    print(f"📊 Unit test metrics returned: {unit_test_metrics}")
    
    # Ensure we have valid values (handle None or missing keys)
    unit_total = int(unit_test_metrics.get('total', 0) or 0)
    unit_passed = int(unit_test_metrics.get('passed', 0) or 0)
    unit_failed = int(unit_test_metrics.get('failed', 0) or 0)
    unit_coverage = float(unit_test_metrics.get('coverage', 0.0) or 0.0)
    unit_duration = float(unit_test_metrics.get('duration', 0.0) or 0.0)
    
    print(f"📊 Parsed unit test values: Total={unit_total}, Passed={unit_passed}, Failed={unit_failed}, Coverage={unit_coverage}%, Duration={unit_duration}s")
    
    unit_metrics_to_push = [
        f'unit_tests_total{{repository="{repository}"}} {unit_total}',
        f'unit_tests_passed{{repository="{repository}"}} {unit_passed}',
        f'unit_tests_failed{{repository="{repository}"}} {unit_failed}',
        f'unit_tests_coverage_percentage{{repository="{repository}"}} {unit_coverage}',
        f'unit_tests_duration_seconds{{repository="{repository}"}} {unit_duration}'
    ]
    
    print(f"📤 About to add {len(unit_metrics_to_push)} unit test metrics to prom_metrics list...")
    print(f"   Current prom_metrics count: {len(prom_metrics)}")
    
    prom_metrics.extend(unit_metrics_to_push)
    
    print(f"   New prom_metrics count: {len(prom_metrics)}")
    print(f"📊 Unit Test Metrics: Total={unit_total}, Passed={unit_passed}, Failed={unit_failed}, Coverage={unit_coverage}%, Duration={unit_duration}s")
    print(f"📤 Will push unit test metrics:")
    for metric in unit_metrics_to_push:
        print(f"   {metric}")
    print(f"🔍 IMPORTANT: These metrics will be pushed to Pushgateway and should be queryable in Prometheus")
    print(f"   Example query: unit_tests_total{{repository=\"{repository}\"}}")
    
    # CRITICAL: Verify metrics are in the list before pushing
    unit_test_count_in_payload = sum(1 for m in prom_metrics if 'unit_tests' in m)
    print(f"🔍 Verification: Found {unit_test_count_in_payload} unit test metrics in prom_metrics list (should be 5)")
    if unit_test_count_in_payload != 5:
        print(f"   ⚠️  ERROR: Expected 5 unit test metrics but found {unit_test_count_in_payload}!")
        print(f"   Available metrics with 'unit' in name:")
        for m in prom_metrics:
            if 'unit' in m.lower():
                print(f"      {m}")
    
    # Performance test metrics - ALWAYS push, even if 0
    performance_test_metrics = read_performance_test_metrics()
    perf_metrics_to_push = [
        f'performance_tests_total{{repository="{repository}"}} {performance_test_metrics["total"]}',
        f'performance_tests_passed{{repository="{repository}"}} {performance_test_metrics["passed"]}',
        f'performance_tests_failed{{repository="{repository}"}} {performance_test_metrics["failed"]}',
        f'performance_avg_response_time_ms{{repository="{repository}"}} {performance_test_metrics["avg_response_time"]}',
        f'performance_p95_response_time_ms{{repository="{repository}"}} {performance_test_metrics["p95_response_time"]}',
        f'performance_p99_response_time_ms{{repository="{repository}"}} {performance_test_metrics["p99_response_time"]}',
        f'performance_error_rate_percentage{{repository="{repository}"}} {performance_test_metrics["error_rate"]}',
        f'performance_throughput_rps{{repository="{repository}"}} {performance_test_metrics["throughput"]}'
    ]
    prom_metrics.extend(perf_metrics_to_push)
    print(f"📊 Performance Test Metrics: Total={performance_test_metrics['total']}, Passed={performance_test_metrics['passed']}, Failed={performance_test_metrics['failed']}, Avg Response={performance_test_metrics['avg_response_time']}ms, Throughput={performance_test_metrics['throughput']}rps")
    print(f"📤 Will push performance test metrics:")
    for metric in perf_metrics_to_push:
        print(f"   {metric}")
    
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
    
    # Debug: Print sample of metrics being pushed
    print(f"\n📋 Sample of metrics being pushed (first 10 lines):")
    sample_lines = metrics_payload.split('\n')[:10]
    for line in sample_lines:
        if line.strip():
            print(f"   {line}")
    
    # Check specifically for unit test metrics in payload
    unit_test_lines = [m for m in metrics if 'unit_tests' in m]
    if unit_test_lines:
        print(f"\n✅ Found {len(unit_test_lines)} unit test metrics in payload:")
        for line in unit_test_lines:
            print(f"   {line}")
    else:
        print(f"\n⚠️  WARNING: No unit test metrics found in payload!")
        print(f"   Total metrics in payload: {len(metrics)}")
        print(f"   Sample metric names: {[m.split('{')[0] for m in metrics[:5]]}")
        print(f"   🔧 FORCING unit test metrics to be added...")
        
        # Force add unit test metrics if they're missing
        repository = os.environ.get('REPO_NAME', 'unknown')
        unit_test_metrics = read_unit_test_metrics()
        
        unit_total = int(unit_test_metrics.get('total', 0) or 0)
        unit_passed = int(unit_test_metrics.get('passed', 0) or 0)
        unit_failed = int(unit_test_metrics.get('failed', 0) or 0)
        unit_coverage = float(unit_test_metrics.get('coverage', 0.0) or 0.0)
        unit_duration = float(unit_test_metrics.get('duration', 0.0) or 0.0)
        
        forced_unit_metrics = [
            f'unit_tests_total{{repository="{repository}"}} {unit_total}',
            f'unit_tests_passed{{repository="{repository}"}} {unit_passed}',
            f'unit_tests_failed{{repository="{repository}"}} {unit_failed}',
            f'unit_tests_coverage_percentage{{repository="{repository}"}} {unit_coverage}',
            f'unit_tests_duration_seconds{{repository="{repository}"}} {unit_duration}'
        ]
        metrics.extend(forced_unit_metrics)
        print(f"   ✅ Added {len(forced_unit_metrics)} unit test metrics to payload")
        for metric in forced_unit_metrics:
            print(f"      {metric}")
        
        # Also add performance test metrics if missing
        perf_test_lines = [m for m in metrics if 'performance_tests' in m]
        if not perf_test_lines:
            print(f"   🔧 FORCING performance test metrics to be added...")
            performance_test_metrics = read_performance_test_metrics()
            forced_perf_metrics = [
                f'performance_tests_total{{repository="{repository}"}} {performance_test_metrics.get("total", 0)}',
                f'performance_tests_passed{{repository="{repository}"}} {performance_test_metrics.get("passed", 0)}',
                f'performance_tests_failed{{repository="{repository}"}} {performance_test_metrics.get("failed", 0)}',
                f'performance_avg_response_time_ms{{repository="{repository}"}} {performance_test_metrics.get("avg_response_time", 0.0)}',
                f'performance_p95_response_time_ms{{repository="{repository}"}} {performance_test_metrics.get("p95_response_time", 0.0)}',
                f'performance_p99_response_time_ms{{repository="{repository}"}} {performance_test_metrics.get("p99_response_time", 0.0)}',
                f'performance_error_rate_percentage{{repository="{repository}"}} {performance_test_metrics.get("error_rate", 0.0)}',
                f'performance_throughput_rps{{repository="{repository}"}} {performance_test_metrics.get("throughput", 0.0)}'
            ]
            metrics.extend(forced_perf_metrics)
            print(f"   ✅ Added {len(forced_perf_metrics)} performance test metrics to payload")
        
        # Rebuild payload after adding forced metrics
        metrics_payload = '\n'.join(metrics) + '\n'
        print(f"   📊 Payload rebuilt. New size: {len(metrics_payload)} bytes")
        print(f"   📊 Total metrics count: {len(metrics)}")
    
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
    
    # Push only to the fixed "latest" instance to avoid metric inflation across runs.
    # Historical pushes were causing Grafana queries without instance filters to sum over runs.
    instances_to_push = [
        (instance_latest, "latest")
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
            
            print(f"   📤 Pushing to: {push_url}")
            print(f"   📊 Payload size: {len(metrics_payload)} bytes")
            print(f"   📋 Sample payload (first 500 chars):")
            print(f"      {metrics_payload[:500]}...")
            
            response = requests.put(
                push_url,
                data=metrics_payload,
                headers={'Content-Type': 'text/plain'},
                timeout=30
            )
            
            print(f"   📡 Response status: {response.status_code}")
            print(f"   📄 Response text: {response.text[:200]}")
            
            if response.status_code == 200:
                success_count += 1
                print(f"   ✅ Pushed to {instance_type} instance successfully")
                
                # Immediately verify the push worked
                verify_get = requests.get(push_url, timeout=10)
                if verify_get.status_code == 200:
                    verify_content = verify_get.text
                    if 'unit_tests_total' in verify_content:
                        print(f"   ✅ Verified: unit_tests_total found in Pushgateway!")
                        # Extract sample metric
                        lines = verify_content.split('\n')
                        unit_test_lines = [l for l in lines if 'unit_tests' in l][:3]
                        for line in unit_test_lines:
                            print(f"      {line[:100]}...")
                    else:
                        print(f"   ⚠️  Warning: unit_tests_total NOT found in Pushgateway response")
                        print(f"   📄 Available metrics (sample):")
                        sample_lines = [l for l in lines if repository in l][:5]
                        for line in sample_lines:
                            print(f"      {line[:100]}...")
            else:
                print(f"   ⚠️  Failed to push to {instance_type} instance: HTTP {response.status_code}")
                print(f"   📄 Full response: {response.text}")
                
        except Exception as e:
            print(f"   ⚠️  Error pushing to {instance_type} instance: {e}")
            import traceback
            traceback.print_exc()
    
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
            # Check the specific instance endpoint
            instance_verify_url = f"{pushgateway_url}/metrics/job/{job_name}/instance/{instance_latest}"
            verify_response = requests.get(instance_verify_url, timeout=10)
            if verify_response.status_code == 200:
                metrics_text = verify_response.text
                print(f"   📊 Verifying metrics for job={job_name}, instance={instance_latest}")
                
                # Check for unit test metrics specifically
                unit_test_metric_names = [
                    'unit_tests_total',
                    'unit_tests_passed', 
                    'unit_tests_failed',
                    'unit_tests_coverage_percentage',
                    'unit_tests_duration_seconds'
                ]
                
                found_unit_metrics = []
                for metric_name in unit_test_metric_names:
                    if f'{metric_name}{{repository="{repository}"}}' in metrics_text or f'{metric_name}{{repository="{repository}",' in metrics_text:
                        # Extract the line
                        lines = metrics_text.split('\n')
                        matching_lines = [l.strip() for l in lines if metric_name in l and repository in l]
                        if matching_lines:
                            found_unit_metrics.append((metric_name, matching_lines[0]))
                
                if found_unit_metrics:
                    print(f"   ✅ Verified: Found {len(found_unit_metrics)} unit test metrics in Pushgateway:")
                    for metric_name, metric_line in found_unit_metrics:
                        print(f"      {metric_name}: {metric_line[:100]}...")
                else:
                    print(f"   ⚠️  WARNING: Unit test metrics not found in Pushgateway!")
                    print(f"   🔍 Available metrics in Pushgateway (sample):")
                    lines = metrics_text.split('\n')
                    repo_lines = [l.strip() for l in lines if repository in l][:10]
                    for line in repo_lines:
                        print(f"      {line[:100]}...")
                    if not repo_lines:
                        print(f"      ❌ No metrics found for repository '{repository}'")
            else:
                print(f"   ⚠️  Could not verify metrics (HTTP {verify_response.status_code})")
                print(f"   Response: {verify_response.text[:200]}")
        except Exception as e:
            print(f"   ⚠️  Could not verify metrics: {e}")
            import traceback
            traceback.print_exc()
        
        print(f"\n🔍 Verification commands:")
        print(f"   # Check Pushgateway directly:")
        print(f"   curl -s '{pushgateway_url}/metrics/job/{job_name}/instance/{instance_latest}' | grep 'unit_tests' | head -10")
        print(f"   curl -s '{pushgateway_url}/metrics' | grep 'repository=\"{repository}\"' | grep 'unit_tests' | head -10")
        print(f"\n📋 Dashboard queries to verify (use these in Grafana/Prometheus):")
        print(f"   # Try without job label first:")
        print(f"   unit_tests_total{{repository=\"{repository}\"}}")
        print(f"   # Try with job label:")
        print(f"   unit_tests_total{{job=\"pipeline-metrics\",repository=\"{repository}\"}}")
        print(f"   # Combined query (what dashboard uses):")
        print(f"   (max(unit_tests_total{{repository=\"{repository}\"}}) or max(unit_tests_total{{job=\"pipeline-metrics\",repository=\"{repository}\"}}) or vector(0))")
        print(f"\n💡 Important: The repository name in queries MUST match exactly: '{repository}'")
        print(f"💡 Job name: '{job_name}', Instance: '{instance_latest}'")
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

def read_unit_test_metrics():
    """Read unit test metrics from test result files"""
    metrics = {
        'total': 0,
        'passed': 0,
        'failed': 0,
        'coverage': 0.0,
        'duration': 0.0
    }
    
    # Try to read from JSON test results
    test_files = [
        '/tmp/unit-test-results.json',  # Check this first - it's created by workflow
        '/tmp/test-results.json',
        '/tmp/scan-results/test-results.json',
        'test-results.json',
        'unit-test-results.json'
    ]
    
    print(f"🔍 Reading unit test metrics from test result files...")
    for test_file in test_files:
        if os.path.exists(test_file):
            print(f"   ✅ Found test file: {test_file}")
            try:
                with open(test_file, 'r') as f:
                    test_data = json.load(f)
                
                print(f"   📄 File content: {json.dumps(test_data, indent=2)}")
                
                # Handle different JSON structures
                if isinstance(test_data, dict):
                    # Check for unit_tests nested structure (most common)
                    if 'unit_tests' in test_data:
                        unit_tests = test_data['unit_tests']
                        metrics['total'] = unit_tests.get('total', 0)
                        metrics['passed'] = unit_tests.get('passed', 0)
                        metrics['failed'] = unit_tests.get('failed', 0)
                        metrics['coverage'] = float(unit_tests.get('coverage', 0.0))
                        metrics['duration'] = float(unit_tests.get('duration', 0.0))
                        print(f"   ✅ Parsed unit_tests structure: {metrics}")
                    # Check for tests nested structure
                    elif 'tests' in test_data:
                        tests = test_data['tests']
                        if isinstance(tests, dict):
                            if 'unit_tests' in tests:
                                unit_tests = tests['unit_tests']
                                metrics['total'] = unit_tests.get('total', 0)
                                metrics['passed'] = unit_tests.get('passed', 0)
                                metrics['failed'] = unit_tests.get('failed', 0)
                                metrics['coverage'] = float(unit_tests.get('coverage', 0.0))
                                metrics['duration'] = float(unit_tests.get('duration', 0.0))
                                print(f"   ✅ Parsed tests.unit_tests structure: {metrics}")
                            else:
                                metrics['total'] = tests.get('total', tests.get('passed', 0) + tests.get('failed', 0))
                                metrics['passed'] = tests.get('passed', 0)
                                metrics['failed'] = tests.get('failed', 0)
                                metrics['coverage'] = float(tests.get('coverage', 0.0))
                                metrics['duration'] = float(tests.get('duration', 0.0))
                                print(f"   ✅ Parsed tests structure: {metrics}")
                    # Check for direct structure
                    else:
                        metrics['total'] = test_data.get('total', test_data.get('tests_total', 0))
                        metrics['passed'] = test_data.get('passed', test_data.get('tests_passed', 0))
                        metrics['failed'] = test_data.get('failed', test_data.get('tests_failed', 0))
                        metrics['coverage'] = float(test_data.get('coverage', test_data.get('coverage_percentage', 0.0)))
                        metrics['duration'] = float(test_data.get('duration', test_data.get('test_duration', 0.0)))
                        print(f"   ✅ Parsed direct structure: {metrics}")
                
                if metrics['total'] > 0 or metrics['passed'] > 0 or metrics['failed'] > 0:
                    print(f"✅ Successfully read unit test metrics from {test_file}")
                    print(f"   Metrics: Total={metrics['total']}, Passed={metrics['passed']}, Failed={metrics['failed']}, Coverage={metrics['coverage']}%, Duration={metrics['duration']}s")
                    break
                else:
                    print(f"   ⚠️  File exists but metrics are all zero, checking other files...")
            except Exception as e:
                print(f"⚠️  Error reading unit test metrics from {test_file}: {e}")
                import traceback
                traceback.print_exc()
                continue
        else:
            print(f"   ❌ Not found: {test_file}")
    
    # Try to read from text test results
    if metrics['total'] == 0 and metrics['passed'] == 0 and metrics['failed'] == 0:
        print(f"   🔍 No metrics found in JSON files, checking text files...")
        text_files = [
            '/tmp/test-logs.txt',  # Test logs file created by workflow - check this first
            '/tmp/test-results.txt',
            '/tmp/unit-test-results.txt',
            'test-results.txt'
        ]
        
        for text_file in text_files:
            if os.path.exists(text_file):
                print(f"   ✅ Found text file: {text_file}")
                try:
                    with open(text_file, 'r') as f:
                        content = f.read()
                    
                    print(f"   📄 File size: {len(content)} bytes")
                    print(f"   📄 Preview: {content[:500]}...")
                    
                    import re
                    # Parse test results - try multiple patterns
                    total_match = re.search(r'Total Tests?:?\s*(\d+)', content, re.IGNORECASE)
                    if not total_match:
                        total_match = re.search(r'Tests\s+total:?\s*(\d+)', content, re.IGNORECASE)
                    if not total_match:
                        total_match = re.search(r'Total:?\s*(\d+)', content, re.IGNORECASE)
                    
                    passed_match = re.search(r'Passed:?\s*(\d+)', content, re.IGNORECASE)
                    if not passed_match:
                        passed_match = re.search(r'Tests\s+passed:?\s*(\d+)', content, re.IGNORECASE)
                    
                    failed_match = re.search(r'Failed:?\s*(\d+)', content, re.IGNORECASE)
                    if not failed_match:
                        failed_match = re.search(r'Tests\s+failed:?\s*(\d+)', content, re.IGNORECASE)
                    
                    coverage_match = re.search(r'Coverage:?\s*([\d.]+)%?', content, re.IGNORECASE)
                    duration_match = re.search(r'Duration:?\s*(\d+)\s*(s|sec|seconds)', content, re.IGNORECASE)
                    
                    if total_match:
                        metrics['total'] = int(total_match.group(1))
                        print(f"   ✅ Found total: {metrics['total']}")
                    if passed_match:
                        metrics['passed'] = int(passed_match.group(1))
                        print(f"   ✅ Found passed: {metrics['passed']}")
                    if failed_match:
                        metrics['failed'] = int(failed_match.group(1))
                        print(f"   ✅ Found failed: {metrics['failed']}")
                    if coverage_match:
                        metrics['coverage'] = float(coverage_match.group(1))
                        print(f"   ✅ Found coverage: {metrics['coverage']}%")
                    if duration_match:
                        metrics['duration'] = float(duration_match.group(1))
                        print(f"   ✅ Found duration: {metrics['duration']}s")
                    
                    # Calculate total if not found
                    if metrics['total'] == 0 and (metrics['passed'] > 0 or metrics['failed'] > 0):
                        metrics['total'] = metrics['passed'] + metrics['failed']
                        print(f"   ✅ Calculated total from passed+failed: {metrics['total']}")
                    
                    if metrics['total'] > 0:
                        print(f"✅ Successfully read unit test metrics from {text_file}")
                        print(f"   Metrics: Total={metrics['total']}, Passed={metrics['passed']}, Failed={metrics['failed']}, Coverage={metrics['coverage']}%, Duration={metrics['duration']}s")
                        break
                except Exception as e:
                    print(f"⚠️  Error reading unit test metrics from {text_file}: {e}")
                    import traceback
                    traceback.print_exc()
                    continue
    
    # Always ensure we return metrics, even if 0
    if metrics['total'] == 0:
        print(f"⚠️  No unit test metrics found - test files may not exist or tests weren't run")
        print(f"💡 Creating default metrics with 0 values to ensure they appear in Prometheus")
        # Debug: List available files
        print(f"🔍 Debug: Checking for test files...")
        test_files_to_check = [
            '/tmp/test-results.json',
            '/tmp/unit-test-results.json',
            '/tmp/scan-results/test-results.json',
            'test-results.json',
            'unit-test-results.json',
            '/tmp/test-results.txt',
            '/tmp/test-logs.txt'
        ]
        for f in test_files_to_check:
            if os.path.exists(f):
                print(f"   ✅ Found: {f}")
                try:
                    if f.endswith('.json'):
                        with open(f, 'r') as file:
                            content = json.load(file)
                            print(f"      Content preview: {str(content)[:200]}")
                    else:
                        with open(f, 'r') as file:
                            content = file.read()
                            print(f"      Size: {len(content)} bytes, Preview: {content[:200]}")
                except Exception as e:
                    print(f"      Error reading: {e}")
            else:
                print(f"   ❌ Not found: {f}")
    else:
        print(f"✅ Successfully read unit test metrics: Total={metrics['total']}, Passed={metrics['passed']}, Failed={metrics['failed']}, Coverage={metrics['coverage']}%, Duration={metrics['duration']}s")
    
    return metrics

def read_performance_test_metrics():
    """Read performance test metrics from result files"""
    metrics = {
        'total': 0,
        'passed': 0,
        'failed': 0,
        'avg_response_time': 0.0,
        'p95_response_time': 0.0,
        'p99_response_time': 0.0,
        'error_rate': 0.0,
        'throughput': 0.0
    }
    
    # Try to read from JSON performance test results
    perf_files = [
        '/tmp/performance-test-results.json',  # Check this first - it's created by workflow
        '/tmp/perf-results.json',
        '/tmp/scan-results/performance-test-results.json',
        'performance-test-results.json',
        'perf-results.json'
    ]
    
    print(f"🔍 Reading performance test metrics from result files...")
    for perf_file in perf_files:
        if os.path.exists(perf_file):
            print(f"   ✅ Found performance test file: {perf_file}")
            try:
                with open(perf_file, 'r') as f:
                    perf_data = json.load(f)
                
                print(f"   📄 File content: {json.dumps(perf_data, indent=2)}")
                
                # Handle different JSON structures
                if isinstance(perf_data, dict):
                    # Check for performance_tests nested structure (most common)
                    if 'performance_tests' in perf_data:
                        perf_tests = perf_data['performance_tests']
                        metrics['total'] = perf_tests.get('total', 0)
                        metrics['passed'] = perf_tests.get('passed', 0)
                        metrics['failed'] = perf_tests.get('failed', 0)
                        metrics['avg_response_time'] = float(perf_tests.get('avg_response_time', perf_tests.get('avg_response_time_ms', 0.0)))
                        metrics['p95_response_time'] = float(perf_tests.get('p95_response_time', perf_tests.get('p95_response_time_ms', 0.0)))
                        metrics['p99_response_time'] = float(perf_tests.get('p99_response_time', perf_tests.get('p99_response_time_ms', 0.0)))
                        metrics['error_rate'] = float(perf_tests.get('error_rate', perf_tests.get('error_rate_percentage', 0.0)))
                        metrics['throughput'] = float(perf_tests.get('throughput', perf_tests.get('throughput_rps', 0.0)))
                        print(f"   ✅ Parsed performance_tests structure: {metrics}")
                    # Check for direct structure
                    else:
                        metrics['total'] = perf_data.get('total', perf_data.get('tests_total', 0))
                        metrics['passed'] = perf_data.get('passed', perf_data.get('tests_passed', 0))
                        metrics['failed'] = perf_data.get('failed', perf_data.get('tests_failed', 0))
                        metrics['avg_response_time'] = float(perf_data.get('avg_response_time', perf_data.get('avg_response_time_ms', 0.0)))
                        metrics['p95_response_time'] = float(perf_data.get('p95_response_time', perf_data.get('p95_response_time_ms', 0.0)))
                        metrics['p99_response_time'] = float(perf_data.get('p99_response_time', perf_data.get('p99_response_time_ms', 0.0)))
                        metrics['error_rate'] = float(perf_data.get('error_rate', perf_data.get('error_rate_percentage', 0.0)))
                        metrics['throughput'] = float(perf_data.get('throughput', perf_data.get('throughput_rps', 0.0)))
                        print(f"   ✅ Parsed direct structure: {metrics}")
                
                if metrics['total'] > 0 or metrics['avg_response_time'] > 0:
                    print(f"✅ Successfully read performance test metrics from {perf_file}")
                    print(f"   Metrics: Total={metrics['total']}, Passed={metrics['passed']}, Failed={metrics['failed']}, Avg Response={metrics['avg_response_time']}ms, Throughput={metrics['throughput']}rps")
                    break
                else:
                    print(f"   ⚠️  File exists but metrics are all zero")
            except Exception as e:
                print(f"⚠️  Error reading performance test metrics from {perf_file}: {e}")
                import traceback
                traceback.print_exc()
                continue
        else:
            print(f"   ❌ Not found: {perf_file}")
    
    # Try to read from text performance test results
    if metrics['total'] == 0 and metrics['avg_response_time'] == 0:
        text_files = [
            '/tmp/performance-test-results.txt',
            '/tmp/perf-results.txt',
            'performance-test-results.txt'
        ]
        
        for text_file in text_files:
            if os.path.exists(text_file):
                try:
                    with open(text_file, 'r') as f:
                        content = f.read()
                    
                    import re
                    # Parse performance metrics
                    avg_match = re.search(r'Average.*?response.*?time:?\s*([\d.]+)\s*(ms|s)', content, re.IGNORECASE)
                    p95_match = re.search(r'P95.*?response.*?time:?\s*([\d.]+)\s*(ms|s)', content, re.IGNORECASE)
                    p99_match = re.search(r'P99.*?response.*?time:?\s*([\d.]+)\s*(ms|s)', content, re.IGNORECASE)
                    error_match = re.search(r'Error.*?rate:?\s*([\d.]+)%?', content, re.IGNORECASE)
                    throughput_match = re.search(r'Throughput:?\s*([\d.]+)\s*(rps|req/s|requests)', content, re.IGNORECASE)
                    
                    if avg_match:
                        value = float(avg_match.group(1))
                        unit = avg_match.group(2).lower()
                        metrics['avg_response_time'] = value * 1000 if unit == 's' else value
                    if p95_match:
                        value = float(p95_match.group(1))
                        unit = p95_match.group(2).lower()
                        metrics['p95_response_time'] = value * 1000 if unit == 's' else value
                    if p99_match:
                        value = float(p99_match.group(1))
                        unit = p99_match.group(2).lower()
                        metrics['p99_response_time'] = value * 1000 if unit == 's' else value
                    if error_match:
                        metrics['error_rate'] = float(error_match.group(1))
                    if throughput_match:
                        metrics['throughput'] = float(throughput_match.group(1))
                    
                    if metrics['avg_response_time'] > 0:
                        print(f"✅ Read performance test metrics from {text_file}")
                        break
                except Exception as e:
                    print(f"⚠️  Error reading performance test metrics from {text_file}: {e}")
                    continue
    
    # Always ensure we return metrics, even if 0
    if metrics['total'] == 0 and metrics['avg_response_time'] == 0:
        print(f"⚠️  No performance test metrics found - test files may not exist or tests weren't run")
        print(f"💡 Creating default metrics with 0 values to ensure they appear in Prometheus")
    else:
        print(f"✅ Successfully read performance test metrics: Total={metrics['total']}, Avg={metrics['avg_response_time']}ms, P95={metrics['p95_response_time']}ms, P99={metrics['p99_response_time']}ms, Error Rate={metrics['error_rate']}%, Throughput={metrics['throughput']}rps")
    return metrics

if __name__ == "__main__":
    main()

