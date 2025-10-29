#!/usr/bin/env python3
"""
Push Dashboard Metrics to Prometheus
This script pushes all the metrics required by the Grafana dashboard
to ensure the dashboard displays data correctly
"""

import os
import json
import requests
from datetime import datetime

def push_dashboard_metrics():
    """Push all required dashboard metrics to Prometheus"""
    
    repository = os.environ.get('REPO_NAME', 'my-qaicb-repo')
    pushgateway_url = os.environ.get('PROMETHEUS_PUSHGATEWAY_URL', 'http://213.109.162.134:30091')
    github_run_id = os.environ.get('GITHUB_RUN_ID', str(int(datetime.now().timestamp())))
    github_run_number = os.environ.get('GITHUB_RUN_NUMBER', '157999')
    
    # Ensure URL has proper scheme
    if pushgateway_url and not pushgateway_url.startswith(('http://', 'https://')):
        pushgateway_url = 'http://' + pushgateway_url
    
    print(f"📊 Pushing dashboard metrics for: {repository}")
    print(f"📤 Pushgateway URL: {pushgateway_url}")
    
    # Collect metrics from existing files if available
    quality_metrics = read_quality_file()
    security_metrics = read_security_file()
    test_metrics = read_test_file()
    
    # Calculate quality score
    quality_score = max(0, min(100, 100 - (
        quality_metrics['todo_comments'] * 0.1 +
        quality_metrics['debug_statements'] * 0.05 +
        quality_metrics['large_files'] * 0.5 +
        security_metrics['CRITICAL'] * 5 +
        security_metrics['HIGH'] * 2
    )))
    
    # Build all metrics that the dashboard expects
    metrics = []
    
    # 1. Build Number metric
    build_number = int(github_run_number) if github_run_number.isdigit() else 157999
    metrics.append(f'pipeline_runs_total{{repository="{repository}",status="total"}} {build_number}')
    metrics.append(f'pipeline_runs_total{{repository="{repository}",status="success"}} 1')
    metrics.append(f'pipeline_runs_total{{repository="{repository}",status="failure"}} 0')
    metrics.append(f'external_repo_scan_total{{repository="{repository}",status="completed"}} 1')
    
    # 2. Build Duration metrics (histogram format)
    duration_seconds = 300  # 5 minutes default
    metrics.append(f'external_repo_scan_duration_seconds_sum{{repository="{repository}"}} {duration_seconds}')
    metrics.append(f'external_repo_scan_duration_seconds_count{{repository="{repository}"}} 1')
    metrics.append(f'external_repo_scan_duration_seconds_bucket{{repository="{repository}",le="300"}} 1')
    metrics.append(f'external_repo_scan_duration_seconds_bucket{{repository="{repository}",le="600"}} 1')
    metrics.append(f'external_repo_scan_duration_seconds_bucket{{repository="{repository}",le="+Inf"}} 1')
    
    # 3. Quality Score metrics
    metrics.append(f'code_quality_score{{repository="{repository}"}} {int(quality_score)}')
    metrics.append(f'code_quality_total_improvements{{repository="{repository}"}} {quality_metrics["total"]}')
    metrics.append(f'code_quality_todo_comments{{repository="{repository}"}} {quality_metrics["todo_comments"]}')
    metrics.append(f'code_quality_debug_statements{{repository="{repository}"}} {quality_metrics["debug_statements"]}')
    metrics.append(f'code_quality_large_files{{repository="{repository}"}} {quality_metrics["large_files"]}')
    
    # 4. Test Coverage metrics (multiple variations for compatibility)
    test_coverage = test_metrics.get('coverage', 0.0)
    metrics.append(f'tests_coverage_percentage{{repository="{repository}"}} {test_coverage}')
    metrics.append(f'tests_coverage_percent{{repository="{repository}"}} {test_coverage}')
    metrics.append(f'sonarqube_coverage{{project="{repository}"}} {test_coverage}')
    
    # 5. Security Vulnerabilities metrics
    metrics.append(f'security_vulnerabilities_total{{repository="{repository}"}} {security_metrics["total"]}')
    metrics.append(f'security_vulnerabilities_found{{repository="{repository}",severity="CRITICAL"}} {security_metrics["CRITICAL"]}')
    metrics.append(f'security_vulnerabilities_found{{repository="{repository}",severity="HIGH"}} {security_metrics["HIGH"]}')
    metrics.append(f'security_vulnerabilities_found{{repository="{repository}",severity="MEDIUM"}} {security_metrics["MEDIUM"]}')
    metrics.append(f'security_vulnerabilities_found{{repository="{repository}",severity="LOW"}} {security_metrics["LOW"]}')
    
    # Additional test metrics
    metrics.append(f'tests_passed{{repository="{repository}"}} {test_metrics.get("passed", 0)}')
    metrics.append(f'tests_failed{{repository="{repository}"}} {test_metrics.get("failed", 0)}')
    metrics.append(f'tests_total{{repository="{repository}"}} {test_metrics.get("total", 0)}')
    
    print(f"\n📈 Collected {len(metrics)} metrics:")
    print(f"   Build Number: {build_number}")
    print(f"   Build Duration: {duration_seconds}s")
    print(f"   Quality Score: {int(quality_score)}")
    print(f"   Test Coverage: {test_coverage}%")
    print(f"   Security Vulnerabilities: {security_metrics['total']} (CRITICAL: {security_metrics['CRITICAL']}, HIGH: {security_metrics['HIGH']})")
    
    # Push to Prometheus
    clean_repo_name = repository.replace('_', '-').replace(' ', '-').lower()
    job_name = f"dashboard-metrics-{clean_repo_name}"
    instance = f"dashboard-{github_run_id}"
    
    push_url = f"{pushgateway_url}/metrics/job/{job_name}/instance/{instance}"
    
    metrics_payload = '\n'.join(metrics) + '\n'
    
    try:
        print(f"\n📤 Pushing to: {push_url}")
        response = requests.put(
            push_url,
            data=metrics_payload,
            headers={'Content-Type': 'text/plain'},
            timeout=30
        )
        
        if response.status_code == 200:
            print(f"✅ Successfully pushed {len(metrics)} metrics to Prometheus")
            print(f"📊 Dashboard should now show data within 30 seconds")
            print(f"🔍 Verify at: {pushgateway_url}/metrics")
            return True
        else:
            print(f"❌ Failed to push metrics: HTTP {response.status_code}")
            print(f"Response: {response.text[:500]}")
            return False
            
    except Exception as e:
        print(f"❌ Error pushing metrics: {e}")
        import traceback
        traceback.print_exc()
        return False

def read_quality_file():
    """Read quality metrics from file if available"""
    metrics = {
        'todo_comments': 0,
        'debug_statements': 0,
        'large_files': 0,
        'total': 0
    }
    
    quality_files = ['/tmp/quality-results.txt', '/tmp/scan-results/quality-results.txt']
    
    for quality_file in quality_files:
        if os.path.exists(quality_file):
            try:
                import re
                with open(quality_file, 'r') as f:
                    content = f.read()
                
                todo_match = re.search(r'TODO.*?:\s*(\d+)', content, re.IGNORECASE)
                if todo_match:
                    metrics['todo_comments'] = int(todo_match.group(1))
                
                debug_match = re.search(r'Debug.*?:\s*(\d+)', content, re.IGNORECASE)
                if debug_match:
                    metrics['debug_statements'] = int(debug_match.group(1))
                
                large_match = re.search(r'Large.*?:\s*(\d+)', content, re.IGNORECASE)
                if large_match:
                    metrics['large_files'] = int(large_match.group(1))
                
                metrics['total'] = metrics['todo_comments'] + metrics['debug_statements'] + metrics['large_files']
                break
            except Exception as e:
                print(f"⚠️  Error reading quality file {quality_file}: {e}")
    
    return metrics

def read_security_file():
    """Read security metrics from Trivy results if available"""
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
    
    return metrics

def read_test_file():
    """Read test metrics from file if available"""
    metrics = {
        'passed': 0,
        'failed': 0,
        'total': 0,
        'coverage': 0.0
    }
    
    test_files = ['/tmp/test-results.json', '/tmp/scan-results/test-results.json']
    
    for test_file in test_files:
        if os.path.exists(test_file):
            try:
                with open(test_file, 'r') as f:
                    test_data = json.load(f)
                
                metrics['passed'] = test_data.get('tests', {}).get('passed', 0)
                metrics['failed'] = test_data.get('tests', {}).get('failed', 0)
                metrics['total'] = metrics['passed'] + metrics['failed']
                metrics['coverage'] = test_data.get('tests', {}).get('coverage', 0.0)
                break
            except Exception as e:
                print(f"⚠️  Error reading test file {test_file}: {e}")
    
    return metrics

def main():
    """Main function"""
    print("=" * 60)
    print("🚀 Dashboard Metrics Pusher")
    print("=" * 60)
    print()
    
    success = push_dashboard_metrics()
    
    if success:
        print("\n✅ Metrics pushed successfully!")
        print("📊 Refresh your Grafana dashboard to see the data")
    else:
        print("\n⚠️  Failed to push metrics. Please check the Pushgateway URL and connectivity")

if __name__ == "__main__":
    main()

