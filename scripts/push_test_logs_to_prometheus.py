#!/usr/bin/env python3
"""
Push test logs to Prometheus as metrics
This allows Grafana to display test log information
"""
import os
import json
import requests
import re

def read_test_logs():
    """Read test logs from file"""
    log_content = ""
    if os.path.exists('/tmp/test-logs.txt'):
        with open('/tmp/test-logs.txt', 'r') as f:
            log_content = f.read()
    return log_content

def extract_test_summary(log_content):
    """Extract test summary from logs"""
    summary = {
        'total': 0,
        'passed': 0,
        'failed': 0,
        'coverage': 0.0,
        'duration': 0.0
    }
    
    # Extract from summary section
    total_match = re.search(r'Total Tests:\s*(\d+)', log_content)
    passed_match = re.search(r'Passed:\s*(\d+)', log_content)
    failed_match = re.search(r'Failed:\s*(\d+)', log_content)
    coverage_match = re.search(r'Coverage:\s*([\d.]+)%?', log_content)
    duration_match = re.search(r'Duration:\s*(\d+)', log_content)
    
    if total_match:
        summary['total'] = int(total_match.group(1))
    if passed_match:
        summary['passed'] = int(passed_match.group(1))
    if failed_match:
        summary['failed'] = int(failed_match.group(1))
    if coverage_match:
        summary['coverage'] = float(coverage_match.group(1))
    if duration_match:
        summary['duration'] = float(duration_match.group(1))
    
    return summary

def push_test_log_metrics():
    """Push test log metrics to Prometheus"""
    repository = os.environ.get('REPO_NAME', 'unknown')
    pushgateway_url = os.environ.get('PROMETHEUS_PUSHGATEWAY_URL', 'http://213.109.162.134:30091')
    
    if not pushgateway_url.startswith(('http://', 'https://')):
        pushgateway_url = 'http://' + pushgateway_url
    
    # Read test logs
    log_content = read_test_logs()
    
    # Extract summary
    summary = extract_test_summary(log_content)
    
    # Count log lines
    log_lines = len(log_content.split('\n')) if log_content else 0
    
    # Prepare metrics
    metrics = []
    
    # Test log metrics
    metrics.append(f'test_logs_total_lines{{repository="{repository}"}} {log_lines}')
    metrics.append(f'test_logs_has_content{{repository="{repository}"}} {1 if log_content else 0}')
    
    # Summary metrics (as backup/verification)
    if summary['total'] > 0:
        metrics.append(f'test_logs_summary_total{{repository="{repository}"}} {summary["total"]}')
        metrics.append(f'test_logs_summary_passed{{repository="{repository}"}} {summary["passed"]}')
        metrics.append(f'test_logs_summary_failed{{repository="{repository}"}} {summary["failed"]}')
        metrics.append(f'test_logs_summary_coverage{{repository="{repository}"}} {summary["coverage"]}')
        metrics.append(f'test_logs_summary_duration{{repository="{repository}"}} {summary["duration"]}')
    
    metrics_text = '\n'.join(metrics) + '\n'
    
    # Push to Prometheus
    github_run_id = os.environ.get('GITHUB_RUN_ID', 'unknown')
    clean_repo_name = repository.replace('_', '-').replace(' ', '-').lower()
    job_name = f"test-logs-{clean_repo_name}"
    instance = f"run-{github_run_id}"
    
    push_url = f"{pushgateway_url}/metrics/job/{job_name}/instance/{instance}"
    
    try:
        response = requests.put(
            push_url,
            data=metrics_text,
            headers={'Content-Type': 'text/plain'},
            timeout=30
        )
        
        if response.status_code == 200:
            print(f"✅ Successfully pushed test log metrics to Prometheus")
            print(f"📊 Log lines: {log_lines}, Summary: Total={summary['total']}, Passed={summary['passed']}, Failed={summary['failed']}")
        else:
            print(f"⚠️ Failed to push test log metrics: HTTP {response.status_code}")
    except Exception as e:
        print(f"⚠️ Error pushing test log metrics: {e}")

if __name__ == "__main__":
    push_test_log_metrics()

