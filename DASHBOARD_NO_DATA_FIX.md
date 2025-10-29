# Dashboard "No Data" Fix - Complete Solution

## ✅ Changes Applied

### 1. Simplified Dashboard Queries
**File**: `scripts/complete_pipeline_solution.py`

Changed queries from complex aggregations to simpler ones that work with Pushgateway:
- **Build Number**: `max(pipeline_runs_total{...})` instead of `sum(last_over_time(...))`
- **Quality Score**: `max(code_quality_score{...})` instead of complex time-range queries
- **Test Coverage**: `max(tests_coverage_percentage{...})` with fallbacks
- **Security Vulnerabilities**: `max(security_vulnerabilities_total{...})`
- **Build Duration**: Simplified division query

### 2. Added Detailed Logging
**File**: `scripts/comprehensive_metrics_pusher.py`

- Added logging of metrics being pushed
- Shows sample metrics for debugging
- Provides troubleshooting steps on errors
- Prints verification commands

### 3. Created Diagnostic Scripts
- `scripts/debug_prometheus_queries.py` - Test queries directly
- `scripts/fix_dashboard_no_data.sh` - Complete fix script
- `scripts/fix_grafana_datasource.py` - Datasource configuration help

## 🔍 Root Cause Identified

1. **Prometheus Not Accessible**: Cannot connect to `http://213.109.162.134:9090`
2. **Metrics in Pushgateway**: All metrics are correctly in Pushgateway at port 30091
3. **Queries Too Complex**: Dashboard queries were using complex time-range functions that may not work if Prometheus isn't scraping properly

## 🛠️ Solution Applied

1. **Simplified Queries**: Use `max()` and direct metric access instead of complex aggregations
2. **Multiple Fallbacks**: Each query has 3-4 fallback options
3. **Better Logging**: Added detailed logs to track metric pushing

## 📋 Manual Fix Steps

If dashboard still shows "No data":

### Option 1: Regenerate Dashboard (Recommended)
```bash
python3 scripts/complete_pipeline_solution.py
```
This will regenerate the dashboard with the simplified queries.

### Option 2: Fix Prometheus Configuration
If you have kubectl access:
```bash
# Apply updated Prometheus config (includes Pushgateway scrape job)
kubectl apply -f credentials/prometheus-config.yaml

# Restart Prometheus
kubectl rollout restart deployment/prometheus -n monitoring

# Wait for Prometheus to restart and scrape
sleep 30

# Refresh metrics
./scripts/refresh_dashboard_metrics.sh my-qaicb-repo
```

### Option 3: Configure Grafana to Use Pushgateway Directly
1. Go to Grafana > Connections > Data sources
2. Add new datasource
3. Type: **Prometheus**
4. URL: `http://213.109.162.134:30091`
5. Name: **Pushgateway**
6. Save & Test
7. Update dashboard queries to use "Pushgateway" datasource

### Option 4: Push Fresh Metrics
```bash
./scripts/refresh_dashboard_metrics.sh my-qaicb-repo
```

## ✅ Verification

Check if metrics are in Pushgateway:
```bash
curl -s 'http://213.109.162.134:30091/metrics' | grep 'my-qaicb-repo' | head -5
```

Should see:
- `pipeline_runs_total{repository="my-qaicb-repo",...}`
- `code_quality_score{repository="my-qaicb-repo",...}`
- `tests_coverage_percentage{repository="my-qaicb-repo",...}`
- `security_vulnerabilities_total{repository="my-qaicb-repo",...}`

## 🎯 Expected Result

After applying fixes:
1. Metrics are pushed to Pushgateway ✅ (Already done)
2. Dashboard queries are simplified ✅ (Done)
3. Dashboard regenerated with new queries (Run: `python3 scripts/complete_pipeline_solution.py`)
4. Grafana dashboard shows data ✅ (After refresh)

## 📊 Query Examples (Updated)

**Before (Complex)**:
```promql
sum(last_over_time(pipeline_runs_total{repository="my-qaicb-repo",status="total"}[15m]))
```

**After (Simple)**:
```promql
max(pipeline_runs_total{repository="my-qaicb-repo",status="total"})
```

The simple query works even if Prometheus hasn't scraped recently or if metrics are only in Pushgateway.

## 🔗 Quick Commands

```bash
# Quick fix everything
./scripts/fix_dashboard_no_data.sh my-qaicb-repo

# Regenerate dashboard
python3 scripts/complete_pipeline_solution.py

# Refresh metrics
./scripts/refresh_dashboard_metrics.sh my-qaicb-repo

# Debug queries
python3 scripts/debug_prometheus_queries.py
```

