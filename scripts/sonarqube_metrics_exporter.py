#!/usr/bin/env python3
"""
SonarQube Metrics Exporter for Prometheus
This script fetches metrics from SonarQube API and exposes them for Prometheus scraping
"""

import os
import json
import requests
import time
from datetime import datetime

def get_sonarqube_metrics():
    """Fetch metrics from SonarQube API"""
    
    # SonarQube configuration
    sonar_url = os.environ.get('SONARQUBE_URL', 'http://213.109.162.134:30100')
    sonar_token = os.environ.get('SONARQUBE_TOKEN', 'sqa_5d9aed525cdd3421964d6475f57a725da8fccdb1')
    project_key = os.environ.get('REPO_NAME', 'my-qaicb-repo')
    
    print(f"🔍 Fetching SonarQube metrics for project: {project_key}")
    print(f"📊 SonarQube URL: {sonar_url}")
    
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
            return []
        
        print("✅ SonarQube authentication successful")
        
        # Get project measures/metrics
        measures_response = requests.get(
            f"{sonar_url}/api/measures/component",
            params={
                'component': project_key,
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
                    prometheus_metric = f'sonarqube_{metric_name}{{project="{project_key}"}} {metric_value}'
                    metrics.append(prometheus_metric)
                    
                    print(f"📈 {metric_name}: {metric_value}")
        
        # Get project issues count by severity
        issues_response = requests.get(
            f"{sonar_url}/api/issues/search",
            params={
                'componentKeys': project_key,
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
                            prometheus_metric = f'sonarqube_issues_by_severity{{project="{project_key}",severity="{severity}"}} {count}'
                            metrics.append(prometheus_metric)
                            print(f"🚨 Issues {severity}: {count}")
        
        # Get project info
        project_response = requests.get(
            f"{sonar_url}/api/projects/search",
            params={'q': project_key},
            auth=(sonar_token, ""),
            timeout=10
        )
        
        if project_response.status_code == 200:
            project_data = project_response.json()
            if 'components' in project_data and project_data['components']:
                project_info = project_data['components'][0]
                last_analysis = project_info.get('lastAnalysisDate', '')
                
                # Add project metadata
                metrics.extend([
                    f'sonarqube_project_last_analysis_timestamp{{project="{project_key}"}} {last_analysis}',
                    f'sonarqube_project_analysis_success{{project="{project_key}"}} 1'
                ])
                print(f"📅 Last analysis: {last_analysis}")
        
    except Exception as e:
        print(f"❌ Error fetching SonarQube metrics: {e}")
        # Add error metric
        metrics.append(f'sonarqube_metrics_fetch_error{{project="{project_key}"}} 1')
    
    return metrics

def push_to_prometheus(metrics):
    """Push metrics to Prometheus Pushgateway"""
    
    # Get Prometheus Pushgateway URL
    pushgateway_url = os.environ.get('PROMETHEUS_PUSHGATEWAY_URL', 'http://213.109.162.134:30091')
    
    # Ensure URL has proper scheme
    if pushgateway_url and not pushgateway_url.startswith(('http://', 'https://')):
        pushgateway_url = 'http://' + pushgateway_url
    
    print(f"📤 Pushing to Prometheus Pushgateway: {pushgateway_url}")
    
    if not metrics:
        print("❌ No metrics to push")
        return
    
    # Prepare metrics payload
    metrics_payload = '\n'.join(metrics) + '\n'
    
    # Determine job and instance
    project_key = os.environ.get('REPO_NAME', 'my-qaicb-repo')
    github_run_id = os.environ.get('GITHUB_RUN_ID', 'unknown')
    
    # Clean project name for use in job name
    clean_project_name = project_key.replace('_', '-').replace(' ', '-').lower()
    job_name = f"sonarqube-metrics-{clean_project_name}"
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
            print(f"✅ Successfully pushed {len(metrics)} SonarQube metrics to Prometheus")
            print(f"📊 View metrics at: {pushgateway_url}/metrics")
        else:
            print(f"❌ Failed to push metrics: HTTP {response.status_code}")
            print(f"Response: {response.text}")
            
    except Exception as e:
        print(f"❌ Error pushing metrics: {e}")

def main():
    """Main function"""
    print("🚀 SonarQube Metrics Exporter for Prometheus")
    print("=" * 50)
    
    # Fetch SonarQube metrics
    metrics = get_sonarqube_metrics()
    
    if metrics:
        print(f"\n📊 Collected {len(metrics)} metrics from SonarQube")
        
        # Push to Prometheus
        push_to_prometheus(metrics)
    else:
        print("❌ No metrics collected from SonarQube")
    
    print("\n✅ SonarQube metrics export completed!")

if __name__ == "__main__":
    main()
