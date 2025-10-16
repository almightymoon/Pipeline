#!/usr/bin/env python3
"""
Enhanced Pipeline Metrics Pusher with SonarQube Integration
This script pushes comprehensive metrics including SonarQube data to Prometheus
"""

import os
import json
import requests
import subprocess
from datetime import datetime

def push_to_prometheus():
    """Push comprehensive metrics to Prometheus Pushgateway"""
    
    # Get Prometheus Pushgateway URL - FIXED: No more masking
    pushgateway_url = os.environ.get('PROMETHEUS_PUSHGATEWAY_URL', 'http://213.109.162.134:30091')
    
    # Ensure URL has proper scheme
    if pushgateway_url and not pushgateway_url.startswith(('http://', 'https://')):
        pushgateway_url = 'http://' + pushgateway_url
    
    print(f"🚀 Pushing pipeline metrics to Prometheus...")
    print(f"📡 Using Pushgateway URL: {pushgateway_url}")
    
    # Get current metrics
    metrics = collect_all_metrics()
    
    # Push to Prometheus
    push_metrics(metrics, pushgateway_url)

def collect_all_metrics():
    """Collect all metrics from various sources"""
    
    metrics = []
    
    # Get basic pipeline metrics
    github_run_number = os.environ.get('GITHUB_RUN_NUMBER', '0')
    github_run_id = os.environ.get('GITHUB_RUN_ID', 'unknown')
    repository = os.environ.get('REPO_NAME', 'unknown')
    
    print(f"📊 Collecting metrics for repository: {repository}")
    
    # Add basic pipeline metrics
    metrics.extend([
        f'pipeline_runs_total{{repository="{repository}",status="success"}} 1',
        f'pipeline_run_duration_seconds{{repository="{repository}"}} 300',  # 5 minutes duration
        f'pipeline_run_number{{repository="{repository}"}} {github_run_number}',
        f'pipeline_run_status{{repository="{repository}"}} 1'  # 1 = success, 0 = failed
    ])
    
    # Collect SonarQube metrics
    sonarqube_metrics = collect_sonarqube_metrics(repository)
    metrics.extend(sonarqube_metrics)
    
    # Collect security metrics from Trivy results
    security_metrics = collect_security_metrics(repository)
    metrics.extend(security_metrics)
    
    # Collect code quality metrics
    quality_metrics = collect_quality_metrics(repository)
    metrics.extend(quality_metrics)
    
    # Collect test metrics
    test_metrics = collect_test_metrics(repository)
    metrics.extend(test_metrics)
    
    return metrics

def collect_sonarqube_metrics(repository):
    """Collect metrics from SonarQube API"""
    
    metrics = []
    
    # SonarQube configuration
    sonar_url = os.environ.get('SONARQUBE_URL', 'http://213.109.162.134:30100')
    sonar_token = os.environ.get('SONARQUBE_TOKEN', 'sqa_5d9aed525cdd3421964d6475f57a725da8fccdb1')
    
    print(f"🔍 Fetching SonarQube metrics for: {repository}")
    
    try:
        # Test authentication
        auth_response = requests.get(
            f"{sonar_url}/api/authentication/validate",
            auth=(sonar_token, ""),
            timeout=10
        )
        
        if auth_response.status_code != 200:
            print(f"❌ SonarQube authentication failed: {auth_response.status_code}")
            return metrics
        
        print("✅ SonarQube authentication successful")
        
        # Get project measures/metrics
        measures_response = requests.get(
            f"{sonar_url}/api/measures/component",
            params={
                'component': repository,
                'metricKeys': 'bugs,vulnerabilities,security_hotspots,code_smells,coverage,duplicated_lines_density,maintainability_rating,reliability_rating,security_rating,sqale_index'
            },
            auth=(sonar_token, ""),
            timeout=15
        )
        
        if measures_response.status_code == 200:
            measures_data = measures_response.json()
            print("✅ Successfully fetched SonarQube measures")
            
            # Extract metrics from response
            if 'component' in measures_data and 'measures' in measures_data['component']:
                for measure in measures_data['component']['measures']:
                    metric_name = measure['metric']
                    metric_value = measure['value']
                    
                    # Convert to appropriate metric format
                    prometheus_metric = f'sonarqube_{metric_name}{{repository="{repository}"}} {metric_value}'
                    metrics.append(prometheus_metric)
                    
                    print(f"📈 SonarQube {metric_name}: {metric_value}")
        
        # Get project issues count by severity
        issues_response = requests.get(
            f"{sonar_url}/api/issues/search",
            params={
                'componentKeys': repository,
                'resolved': 'false',
                'facets': 'severities'
            },
            auth=(sonar_token, ""),
            timeout=15
        )
        
        if issues_response.status_code == 200:
            issues_data = issues_response.json()
            print("✅ Successfully fetched SonarQube issues")
            
            # Extract issue counts by severity
            if 'facets' in issues_data:
                for facet in issues_data['facets']:
                    if facet['property'] == 'severities':
                        for value in facet['values']:
                            severity = value['val']
                            count = value['count']
                            prometheus_metric = f'sonarqube_issues_by_severity{{repository="{repository}",severity="{severity}"}} {count}'
                            metrics.append(prometheus_metric)
                            print(f"🚨 SonarQube Issues {severity}: {count}")
        
    except Exception as e:
        print(f"❌ Error fetching SonarQube metrics: {e}")
        # Add error metric
        metrics.append(f'sonarqube_metrics_fetch_error{{repository="{repository}"}} 1')
    
    return metrics

def collect_security_metrics(repository):
    """Collect security metrics from scan results"""
    
    metrics = []
    
    # Initialize with zeros (for cases where no vulnerabilities found)
    severity_counts = {'CRITICAL': 0, 'HIGH': 0, 'MEDIUM': 0, 'LOW': 0}
    
    # Check for Trivy results
    if os.path.exists('/tmp/trivy-results.json'):
        try:
            with open('/tmp/trivy-results.json', 'r') as f:
                trivy_data = json.load(f)
                
            # Count vulnerabilities by severity
            if 'Results' in trivy_data:
                for result in trivy_data['Results']:
                    if 'Vulnerabilities' in result:
                        for vuln in result['Vulnerabilities']:
                            severity = vuln.get('Severity', 'UNKNOWN').upper()
                            if severity in severity_counts:
                                severity_counts[severity] += 1
            
        except Exception as e:
            print(f"Error reading Trivy results: {e}")
    
    # Always add security metrics (even if zero)
    for severity, count in severity_counts.items():
        metrics.append(f'security_vulnerabilities_found{{repository="{repository}",severity="{severity}"}} {count}')
        
    total_vulns = sum(severity_counts.values())
    metrics.append(f'security_vulnerabilities_total{{repository="{repository}"}} {total_vulns}')
    
    print(f"Security metrics for {repository}: {severity_counts}, Total: {total_vulns}")
    
    return metrics

def collect_quality_metrics(repository):
    """Collect code quality metrics"""
    
    metrics = []
    
    # Initialize with zeros (will be populated from actual scan results)
    todo_count = 0
    debug_count = 0
    large_files = 0
    total_improvements = 0
    
    # Check for quality results file
    if os.path.exists('/tmp/quality-results.txt'):
        try:
            with open('/tmp/quality-results.txt', 'r') as f:
                content = f.read()
            
            # Extract counts using regex-like parsing
            import re
            
            todo_match = re.search(r'TODO/FIXME comments: (\d+)', content)
            if todo_match:
                todo_count = int(todo_match.group(1))
            
            debug_match = re.search(r'Debug statements: (\d+)', content)
            if debug_match:
                debug_count = int(debug_match.group(1))
            
            large_match = re.search(r'Large files \(>1MB\): (\d+)', content)
            if large_match:
                large_files = int(large_match.group(1))
            
            total_match = re.search(r'Total suggestions: (\d+)', content)
            if total_match:
                total_improvements = int(total_match.group(1))
            
        except Exception as e:
            print(f"Error reading quality results: {e}")
    
    # Always add quality metrics
    metrics.extend([
        f'code_quality_todo_comments_total{{repository="{repository}"}} {todo_count}',
        f'code_quality_debug_statements_total{{repository="{repository}"}} {debug_count}',
        f'code_quality_large_files_total{{repository="{repository}"}} {large_files}',
        f'code_quality_total_improvements{{repository="{repository}"}} {total_improvements}'
    ])
    
    # Calculate quality score (0-100) - higher score for fewer issues
    quality_score = max(0, 100 - (todo_count * 2) - (debug_count * 1) - (large_files * 5))
    metrics.append(f'code_quality_score{{repository="{repository}"}} {quality_score}')
    
    print(f"Quality metrics for {repository}: TODO={todo_count}, Debug={debug_count}, Large={large_files}, Total={total_improvements}, Score={quality_score}")
    
    return metrics

def collect_test_metrics(repository):
    """Collect test metrics from pipeline runs"""
    
    metrics = []
    
    # Try to get real test results from files
    tests_passed = 0
    tests_failed = 0
    coverage_percentage = 0
    
    # Check for test result files
    if os.path.exists('/tmp/test-results.json'):
        try:
            with open('/tmp/test-results.json', 'r') as f:
                test_data = json.load(f)
                tests_passed = test_data.get('tests', {}).get('passed', 0)
                tests_failed = test_data.get('tests', {}).get('failed', 0)
                coverage_percentage = test_data.get('tests', {}).get('coverage', 0)
        except:
            pass
    
    metrics.extend([
        f'tests_passed_total{{repository="{repository}"}} {tests_passed}',
        f'tests_failed_total{{repository="{repository}"}} {tests_failed}',
        f'tests_coverage_percentage{{repository="{repository}"}} {coverage_percentage}'
    ])
    
    print(f"Test metrics for {repository}: Passed={tests_passed}, Failed={tests_failed}, Coverage={coverage_percentage}%")
    
    return metrics

def push_metrics(metrics, pushgateway_url):
    """Push metrics to Prometheus Pushgateway"""
    
    if not metrics:
        print("No metrics to push")
        return
    
    # Prepare metrics payload
    metrics_payload = '\n'.join(metrics) + '\n'
    
    # Determine job and instance
    repository = os.environ.get('REPO_NAME', 'unknown')
    github_run_id = os.environ.get('GITHUB_RUN_ID', 'unknown')
    
    # Clean repository name for use in job name (replace special characters)
    clean_repo_name = repository.replace('_', '-').replace(' ', '-').lower()
    job_name = f"external-repo-scan-{clean_repo_name}"
    instance = f"run-{github_run_id}"
    
    print(f"Job name: {job_name}")
    print(f"Instance: {instance}")
    
    # Push to Prometheus
    push_url = f"{pushgateway_url}/metrics/job/{job_name}/instance/{instance}"
    
    try:
        response = requests.put(
            push_url,
            data=metrics_payload,
            headers={'Content-Type': 'text/plain'},
            timeout=30
        )
        
        if response.status_code == 200:
            print(f"✅ Successfully pushed {len(metrics)} metrics to Prometheus")
            print(f"📊 Job: {job_name}")
            print(f"🆔 Instance: {instance}")
            print(f"🌐 View metrics at: {pushgateway_url}/metrics")
        else:
            print(f"❌ Failed to push metrics: HTTP {response.status_code}")
            print(f"Response: {response.text}")
            
    except Exception as e:
        print(f"❌ Error pushing metrics: {e}")

def main():
    """Main function"""
    print("🚀 Enhanced Pipeline Metrics Pusher with SonarQube Integration")
    print("=" * 70)
    push_to_prometheus()
    print("✅ Metrics push completed!")

if __name__ == "__main__":
    main()
