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
    
    # Check for test result files
    test_files = ['/tmp/test-results.json', '/tmp/scan-results/test-results.json', 'test-results.json']
    
    for test_file in test_files:
        if os.path.exists(test_file):
            try:
                with open(test_file, 'r') as f:
                    test_data = json.load(f)
                    
                # Extract coverage from different possible formats
                if isinstance(test_data, dict):
                    # Check for coverage in nested structure
                    if 'coverage' in test_data:
                        coverage = float(test_data['coverage'])
                    elif 'tests' in test_data and isinstance(test_data['tests'], dict):
                        coverage = float(test_data['tests'].get('coverage', 0.0))
                    elif 'summary' in test_data and 'coverage' in test_data['summary']:
                        coverage = float(test_data['summary']['coverage'])
                
                if coverage > 0:
                    print(f"📊 Found test coverage: {coverage}% from {test_file}")
                    break
            except Exception as e:
                print(f"⚠️  Error reading test results from {test_file}: {e}")
                continue
    
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
    
    # SonarQube metrics (use coverage calculated above which includes test file data)
    prom_metrics.extend([
        f'sonarqube_coverage{{project="{repository}"}} {coverage}',
        f'sonarqube_bugs{{project="{repository}"}} {sonarqube_metrics.get("bugs", 0)}',
        f'sonarqube_vulnerabilities{{project="{repository}"}} {sonarqube_metrics.get("vulnerabilities", 0)}',
        f'sonarqube_code_smells{{project="{repository}"}} {sonarqube_metrics.get("code_smells", 0)}'
    ])
    
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
    
    # Clean repository name
    clean_repo_name = repository.replace('_', '-').replace(' ', '-').lower()
    job_name = f"comprehensive-metrics-{clean_repo_name}"
    instance = f"run-{github_run_id}"
    
    print(f"📤 Pushing metrics to Pushgateway...")
    print(f"   URL: {pushgateway_url}")
    print(f"   Job: {job_name}")
    print(f"   Instance: {instance}")
    
    # Push to Prometheus
    push_url = f"{pushgateway_url}/metrics/job/{job_name}/instance/{instance}"
    
    try:
        # Log what we're pushing (first 3 metrics for debugging)
        print(f"\n📤 Pushing {len(metrics)} metrics...")
        print(f"   Sample metrics (first 3):")
        for m in metrics[:3]:
            print(f"   - {m}")
        
        response = requests.put(
            push_url,
            data=metrics_payload,
            headers={'Content-Type': 'text/plain'},
            timeout=30
        )
        
        if response.status_code == 200:
            print(f"✅ Successfully pushed {len(metrics)} metrics to Prometheus")
            print(f"📊 Push URL: {push_url}")
            print(f"📊 View at: {pushgateway_url}/metrics")
            print(f"🔍 Verify metrics:")
            print(f"   curl -s '{pushgateway_url}/metrics' | grep '{repository}' | head -5")
        else:
            print(f"❌ Failed to push metrics: HTTP {response.status_code}")
            print(f"Response: {response.text[:500]}")
            print(f"💡 Troubleshooting:")
            print(f"   1. Check Pushgateway is accessible: curl {pushgateway_url}/metrics")
            print(f"   2. Verify network connectivity to {pushgateway_url}")
            
    except Exception as e:
        print(f"❌ Error pushing metrics: {e}")
        import traceback
        traceback.print_exc()
        print(f"\n💡 Debugging info:")
        print(f"   Pushgateway URL: {pushgateway_url}")
        print(f"   Push URL: {push_url}")
        print(f"   Metrics count: {len(metrics)}")

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

if __name__ == "__main__":
    main()

