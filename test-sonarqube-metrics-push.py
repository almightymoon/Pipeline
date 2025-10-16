#!/usr/bin/env python3
"""
Test SonarQube Metrics Push with Correct Repository Name
This script tests pushing SonarQube metrics with the correct repository name
"""

import os
import json
import requests
from datetime import datetime

def test_sonarqube_metrics_push():
    """Test pushing SonarQube metrics with correct repository name"""
    
    # Set environment variables for testing
    os.environ['REPO_NAME'] = 'my-qaicb-repo'
    os.environ['GITHUB_RUN_ID'] = 'test-run-12345'
    os.environ['GITHUB_RUN_NUMBER'] = '999'
    os.environ['SONARQUBE_URL'] = 'http://213.109.162.134:30100'
    os.environ['SONARQUBE_TOKEN'] = 'sqa_5d9aed525cdd3421964d6475f57a725da8fccdb1'
    os.environ['PROMETHEUS_PUSHGATEWAY_URL'] = 'http://213.109.162.134:30091'
    
    print("🧪 Testing SonarQube Metrics Push")
    print("=" * 40)
    
    # SonarQube configuration
    sonar_url = os.environ.get('SONARQUBE_URL')
    sonar_token = os.environ.get('SONARQUBE_TOKEN')
    repository = os.environ.get('REPO_NAME')
    pushgateway_url = os.environ.get('PROMETHEUS_PUSHGATEWAY_URL')
    
    print(f"📊 Repository: {repository}")
    print(f"🔗 SonarQube URL: {sonar_url}")
    print(f"📡 Pushgateway URL: {pushgateway_url}")
    
    metrics = []
    
    try:
        # Test authentication
        auth_response = requests.get(
            f"{sonar_url}/api/authentication/validate",
            auth=(sonar_token, ""),
            timeout=10
        )
        
        if auth_response.status_code != 200:
            print(f"❌ Authentication failed: {auth_response.status_code}")
            return
        
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
        
        # Add some test metrics
        metrics.extend([
            f'pipeline_runs_total{{repository="{repository}",status="success"}} 1',
            f'pipeline_run_duration_seconds{{repository="{repository}"}} 300',
            f'pipeline_run_number{{repository="{repository}"}} {os.environ.get("GITHUB_RUN_NUMBER")}',
            f'pipeline_run_status{{repository="{repository}"}} 1'
        ])
        
        print(f"\n📊 Collected {len(metrics)} metrics")
        
        # Push to Prometheus
        push_metrics_to_prometheus(metrics, pushgateway_url, repository)
        
    except Exception as e:
        print(f"❌ Error: {e}")

def push_metrics_to_prometheus(metrics, pushgateway_url, repository):
    """Push metrics to Prometheus Pushgateway"""
    
    if not metrics:
        print("❌ No metrics to push")
        return
    
    # Prepare metrics payload
    metrics_payload = '\n'.join(metrics) + '\n'
    
    # Determine job and instance
    github_run_id = os.environ.get('GITHUB_RUN_ID', 'test-run-12345')
    
    # Clean repository name for use in job name
    clean_repo_name = repository.replace('_', '-').replace(' ', '-').lower()
    job_name = f"external-repo-scan-{clean_repo_name}"
    instance = f"run-{github_run_id}"
    
    print(f"📋 Job name: {job_name}")
    print(f"🆔 Instance: {instance}")
    
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
            print(f"🔍 Query example: sonarqube_bugs{{repository=\"{repository}\"}}")
        else:
            print(f"❌ Failed to push metrics: HTTP {response.status_code}")
            print(f"Response: {response.text}")
            
    except Exception as e:
        print(f"❌ Error pushing metrics: {e}")

if __name__ == "__main__":
    test_sonarqube_metrics_push()
