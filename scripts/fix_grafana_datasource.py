#!/usr/bin/env python3
"""
Fix Grafana Datasource - Add Pushgateway as direct datasource if Prometheus isn't working
Or ensure Prometheus is configured correctly
"""

import os
import sys

# This script checks if we should use Pushgateway directly or fix Prometheus config
print("🔧 Grafana Datasource Fixer")
print("=" * 60)

print("\n💡 The issue: Prometheus isn't accessible or not scraping Pushgateway")
print("\n📋 Solutions:")
print("\n1. Apply Prometheus Config (if you have kubectl access):")
print("   kubectl apply -f credentials/prometheus-config.yaml")
print("   kubectl rollout restart deployment/prometheus -n monitoring")
print("\n2. Add Pushgateway as Direct Datasource in Grafana:")
print("   - Go to Grafana > Connections > Data sources")
print("   - Add new datasource")
print("   - Type: Prometheus")
print("   - URL: http://213.109.162.134:30091")
print("   - Name: Pushgateway")
print("   - Save & Test")
print("\n3. Update Dashboard Queries (temporary fix):")
print("   - Change datasource from 'Prometheus' to 'Pushgateway' in dashboard")
print("   - Or use direct Pushgateway queries")

print("\n4. Ensure Metrics Are Being Pushed:")
print("   ./scripts/refresh_dashboard_metrics.sh my-qaicb-repo")

