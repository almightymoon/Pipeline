#!/usr/bin/env python3
"""
Debug Prometheus Queries
Test the actual queries used by the dashboard to see why they're returning no data
"""

import requests
import json

REPO_NAME = "my-qaicb-repo"
PROMETHEUS_URL = "http://213.109.162.134:9090"
PUSHGATEWAY_URL = "http://213.109.162.134:30091"

def test_query(query, description):
    """Test a Prometheus query"""
    print(f"\n🔍 Testing: {description}")
    print(f"   Query: {query}")
    
    try:
        # Try Prometheus first
        url = f"{PROMETHEUS_URL}/api/v1/query?query={query}"
        response = requests.get(url, timeout=5)
        
        if response.status_code == 200:
            data = response.json()
            if data.get('status') == 'success':
                results = data.get('data', {}).get('result', [])
                if results:
                    print(f"   ✅ Found {len(results)} result(s):")
                    for r in results[:3]:  # Show first 3
                        print(f"      {r.get('metric')} = {r.get('value', [None, None])[1]}")
                    return True
                else:
                    print(f"   ❌ No results returned")
            else:
                print(f"   ⚠️  Prometheus error: {data.get('error', 'Unknown error')}")
        else:
            print(f"   ⚠️  HTTP {response.status_code}: {response.text[:200]}")
    except requests.exceptions.ConnectionError:
        print(f"   ⚠️  Cannot connect to Prometheus at {PROMETHEUS_URL}")
    except Exception as e:
        print(f"   ⚠️  Error: {e}")
    
    # Check Pushgateway directly
    print(f"   📊 Checking Pushgateway directly...")
    try:
        response = requests.get(f"{PUSHGATEWAY_URL}/metrics", timeout=5)
        if response.status_code == 200:
            metrics_text = response.text
            # Check if our metric exists in pushgateway
            lines = [line for line in metrics_text.split('\n') 
                    if REPO_NAME in line and any(m in line for m in ['pipeline_runs_total', 'code_quality_score', 'tests_coverage_percentage', 'security_vulnerabilities_total', 'external_repo_scan_duration'])]
            if lines:
                print(f"   ✅ Metrics found in Pushgateway ({len(lines)} lines):")
                for line in lines[:3]:
                    print(f"      {line[:100]}")
                return True
            else:
                print(f"   ❌ Metrics not found in Pushgateway")
        else:
            print(f"   ⚠️  Pushgateway returned HTTP {response.status_code}")
    except Exception as e:
        print(f"   ⚠️  Error checking Pushgateway: {e}")
    
    return False

def main():
    print("=" * 70)
    print("🔍 Prometheus Query Debugger")
    print("=" * 70)
    
    # Test queries from dashboard
    queries = [
        (f'pipeline_runs_total{{repository="{REPO_NAME}",status="total"}}', 'Build Number'),
        (f'code_quality_score{{repository="{REPO_NAME}"}}', 'Quality Score'),
        (f'tests_coverage_percentage{{repository="{REPO_NAME}"}}', 'Test Coverage'),
        (f'security_vulnerabilities_total{{repository="{REPO_NAME}"}}', 'Security Vulnerabilities'),
        (f'external_repo_scan_duration_seconds_sum{{repository="{REPO_NAME}"}}', 'Build Duration (sum)'),
        (f'external_repo_scan_duration_seconds_count{{repository="{REPO_NAME}"}}', 'Build Duration (count)'),
    ]
    
    results = {}
    for query, desc in queries:
        results[desc] = test_query(query, desc)
    
    print("\n" + "=" * 70)
    print("📊 Summary")
    print("=" * 70)
    
    for desc, found in results.items():
        status = "✅" if found else "❌"
        print(f"{status} {desc}: {'Found' if found else 'Not Found'}")
    
    # Diagnostic recommendations
    print("\n" + "=" * 70)
    print("💡 Recommendations")
    print("=" * 70)
    
    if not any(results.values()):
        print("❌ No metrics found at all!")
        print("   1. Check if Prometheus is scraping Pushgateway")
        print("   2. Verify Pushgateway has metrics: curl http://213.109.162.134:30091/metrics | grep my-qaicb-repo")
        print("   3. Check Prometheus scrape config includes pushgateway job")
        print("   4. Restart Prometheus: kubectl rollout restart deployment/prometheus -n monitoring")
    elif results.get('Build Number') and not any([results.get('Quality Score'), results.get('Test Coverage')]):
        print("⚠️  Some metrics found, but not all")
        print("   1. Pushgateway has some metrics")
        print("   2. Prometheus may not have scraped all metrics yet")
        print("   3. Dashboard queries may need adjustment")
        print("   4. Try: ./scripts/refresh_dashboard_metrics.sh my-qaicb-repo")

if __name__ == "__main__":
    main()

