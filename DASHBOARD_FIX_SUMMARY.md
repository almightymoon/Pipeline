# Dashboard Metrics Fix Summary

## Problem
The Grafana dashboard was showing "No data" for:
- Build Number
- Build Duration  
- Quality Score
- Test Coverage
- Security Vulnerabilities

## Root Causes Identified

1. **Prometheus not scraping Pushgateway**: The Prometheus configuration was missing a scrape job for the Pushgateway service
2. **Dashboard queries too restrictive**: The queries weren't using time-range functions to handle stale metrics from Pushgateway
3. **Metrics aggregation issues**: Multiple instances/jobs causing query mismatches

## Solutions Implemented

### 1. Added Pushgateway Scrape Configuration
**File**: `credentials/prometheus-config.yaml`

Added a new scrape job:
```yaml
- job_name: 'pushgateway'
  honor_labels: true
  static_configs:
  - targets:
    - '213.109.162.134:30091'
```

**Action Required**: Update Prometheus configuration in Kubernetes:
```bash
kubectl apply -f credentials/prometheus-config.yaml
kubectl rollout restart deployment/prometheus -n monitoring
```

### 2. Improved Dashboard Queries
**File**: `scripts/complete_pipeline_solution.py`

Updated all panel queries to use `last_over_time()` function which:
- Handles stale metrics better
- Works with Pushgateway push pattern
- Aggregates across multiple instances

**Example improvements**:
- Build Number: Uses `sum(last_over_time(...[15m]))` instead of just `sum()`
- Quality Score: Uses `max(last_over_time(...[15m]))` for latest value
- All metrics: Added fallback queries for better reliability

### 3. Created Helper Scripts

**`scripts/push_dashboard_metrics.py`**: Pushes all required dashboard metrics
**`scripts/refresh_dashboard_metrics.sh`**: Quick refresh script
**`scripts/update_dashboard_queries.py`**: Regenerates dashboard with new queries

## Next Steps

### Option 1: Update Prometheus Config (Recommended)
```bash
# Apply updated Prometheus config
kubectl apply -f credentials/prometheus-config.yaml

# Restart Prometheus to load new config
kubectl rollout restart deployment/prometheus -n monitoring

# Wait for Prometheus to start scraping Pushgateway
sleep 30

# Push fresh metrics
./scripts/refresh_dashboard_metrics.sh my-qaicb-repo
```

### Option 2: Regenerate Dashboard (Alternative)
```bash
# Regenerate dashboard with improved queries
python3 scripts/update_dashboard_queries.py

# Push fresh metrics
./scripts/refresh_dashboard_metrics.sh my-qaicb-repo
```

### Option 3: Quick Test
```bash
# Just push fresh metrics (if Prometheus is already scraping)
./scripts/refresh_dashboard_metrics.sh my-qaicb-repo

# Then refresh Grafana dashboard (F5 or refresh button)
```

## Verification

1. **Check metrics in Pushgateway**:
   ```bash
   curl -s 'http://213.109.162.134:30091/metrics' | grep 'my-qaicb-repo'
   ```

2. **Check Prometheus is scraping** (if Prometheus UI accessible):
   - Go to Status > Targets
   - Look for `pushgateway` job
   - Should show as "UP"

3. **Check dashboard in Grafana**:
   - Refresh the dashboard (F5)
   - Check time range is "Last 6 hours" or wider
   - Metrics should appear within 30 seconds

## Metric Names Reference

The dashboard queries these metrics:
- `pipeline_runs_total{repository="my-qaicb-repo",status="total"}` - Build Number
- `external_repo_scan_duration_seconds_sum/count` - Build Duration
- `code_quality_score{repository="my-qaicb-repo"}` - Quality Score  
- `tests_coverage_percentage{repository="my-qaicb-repo"}` - Test Coverage
- `security_vulnerabilities_total{repository="my-qaicb-repo"}` - Security Vulnerabilities

## Troubleshooting

If metrics still don't show:

1. **Check Pushgateway has metrics**: 
   ```bash
   curl http://213.109.162.134:30091/metrics | grep my-qaicb-repo | head -5
   ```

2. **Check Prometheus scrape status** (if accessible):
   - Verify pushgateway job exists and is UP

3. **Try direct query in Grafana Explore**:
   - Go to Explore > Prometheus
   - Try query: `pipeline_runs_total{repository="my-qaicb-repo"}`
   - If this works, dashboard queries may need adjustment

4. **Regenerate dashboard**:
   ```bash
   python3 scripts/complete_pipeline_solution.py
   ```

## Notes

- Metrics pushed to Pushgateway persist until overwritten
- Prometheus scrapes every 15 seconds (from config)
- Dashboard uses `last_over_time([15m])` to handle stale metrics
- Multiple fallback queries ensure metrics show even if some are missing

