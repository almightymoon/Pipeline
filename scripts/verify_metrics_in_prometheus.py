#!/usr/bin/env python3
"""
Verify that metrics exist in Prometheus for a given repository
This script helps debug "No data" issues in Grafana dashboards
"""

import os
import sys
import requests
import yaml

def read_repo_name():
    """Read repository name from repos-to-scan.yaml"""
    try:
        with open('repos-to-scan.yaml', 'r') as f:
            data = yaml.safe_load(f)
        
        if data and 'repositories' in data and data['repositories']:
            for repo in data['repositories']:
                if repo and 'url' in repo and repo['url']:
                    return repo.get('name', 'unknown')
    except Exception as e:
        print(f"⚠️  Could not read repos-to-scan.yaml: {e}")
    
    return os.environ.get('REPO_NAME', 'unknown')

def check_pushgateway(repository):
    """Check if metrics exist in Pushgateway"""
    pushgateway_url = os.environ.get('PROMETHEUS_PUSHGATEWAY_URL', 'http://213.109.162.134:30091')
    
    print(f"\n🔍 Checking Pushgateway: {pushgateway_url}")
    
    try:
        response = requests.get(f"{pushgateway_url}/metrics", timeout=10)
        if response.status_code == 200:
            metrics_text = response.text
            
            # Check for repository metrics
            repo_metrics = [line for line in metrics_text.split('\n') if repository in line and 'repository=' in line]
            
            if repo_metrics:
                print(f"✅ Found {len(repo_metrics)} metrics in Pushgateway for repository '{repository}'")
                print(f"\nSample metrics:")
                for metric in repo_metrics[:5]:
                    print(f"   {metric[:120]}")
                return True
            else:
                print(f"❌ No metrics found in Pushgateway for repository '{repository}'")
                print(f"\nAvailable repositories in Pushgateway:")
                # Extract unique repository names
                repos = set()
                for line in metrics_text.split('\n'):
                    if 'repository=' in line:
                        try:
                            repo = line.split('repository="')[1].split('"')[0]
                            repos.add(repo)
                        except:
                            pass
                if repos:
                    for r in sorted(repos):
                        print(f"   - {r}")
                    print(f"\n💡 Your repository '{repository}' is not in the list above!")
                return False
        else:
            print(f"❌ Could not access Pushgateway (HTTP {response.status_code})")
            return False
    except Exception as e:
        print(f"❌ Error checking Pushgateway: {e}")
        return False

def check_prometheus(repository):
    """Check if metrics exist in Prometheus (scraped from Pushgateway)"""
    prometheus_url = os.environ.get('PROMETHEUS_URL', 'http://213.109.162.134:30090')
    
    print(f"\n🔍 Checking Prometheus: {prometheus_url}")
    
    # List of metrics to check
    metrics_to_check = [
        f'pipeline_runs_total{{repository="{repository}"}}',
        f'code_quality_score{{repository="{repository}"}}',
        f'tests_coverage_percentage{{repository="{repository}"}}',
        f'security_vulnerabilities_total{{repository="{repository}"}}',
        f'external_repo_scan_duration_seconds_sum{{repository="{repository}"}}',
    ]
    
    found_count = 0
    
    for metric_query in metrics_to_check:
        try:
            query_url = f"{prometheus_url}/api/v1/query"
            params = {'query': metric_query}
            response = requests.get(query_url, params=params, timeout=10)
            
            if response.status_code == 200:
                data = response.json()
                if data.get('status') == 'success' and data.get('data', {}).get('result'):
                    result_count = len(data['data']['result'])
                    if result_count > 0:
                        found_count += 1
                        print(f"   ✅ {metric_query.split('{')[0]}: Found {result_count} result(s)")
                    else:
                        print(f"   ❌ {metric_query.split('{')[0]}: No data")
        except Exception as e:
            print(f"   ⚠️  Error checking {metric_query.split('{')[0]}: {e}")
    
    if found_count == len(metrics_to_check):
        print(f"\n✅ All {len(metrics_to_check)} metrics found in Prometheus!")
        return True
    elif found_count > 0:
        print(f"\n⚠️  Only {found_count}/{len(metrics_to_check)} metrics found in Prometheus")
        return False
    else:
        print(f"\n❌ No metrics found in Prometheus for repository '{repository}'")
        print(f"\n💡 Possible issues:")
        print(f"   1. Prometheus hasn't scraped Pushgateway yet (wait 10-30 seconds)")
        print(f"   2. Repository name mismatch: '{repository}'")
        print(f"   3. Prometheus scrape configuration might be missing Pushgateway job")
        return False

def main():
    repository = read_repo_name()
    
    print("=" * 60)
    print("🔍 PROMETHEUS METRICS VERIFICATION")
    print("=" * 60)
    print(f"\nRepository: {repository}")
    
    # Check Pushgateway
    pushgateway_ok = check_pushgateway(repository)
    
    # Check Prometheus
    prometheus_ok = check_prometheus(repository)
    
    print("\n" + "=" * 60)
    if pushgateway_ok and prometheus_ok:
        print("✅ ALL CHECKS PASSED - Metrics should be visible in Grafana")
        return 0
    elif pushgateway_ok:
        print("⚠️  Metrics in Pushgateway but not yet in Prometheus")
        print("💡 Wait 10-30 seconds for Prometheus to scrape Pushgateway")
        return 1
    else:
        print("❌ ISSUES FOUND - See details above")
        print("\n💡 Solutions:")
        print("   1. Run the pipeline again to push metrics")
        print(f"   2. Verify repository name matches: '{repository}'")
        print("   3. Check Pushgateway is accessible and running")
        return 1

if __name__ == "__main__":
    sys.exit(main())
