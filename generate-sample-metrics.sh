#!/bin/bash

# Sample Metrics Generator for Testing Dashboard
# This script generates sample Prometheus metrics for testing

echo "Generating sample metrics for dashboard testing..."

# Generate sample metrics file
cat > sample-metrics.txt << 'EOM'
# HELP pipeline_runs_total Total number of pipeline runs
# TYPE pipeline_runs_total counter
pipeline_runs_total 45

# HELP pipeline_runs_successful Total number of successful pipeline runs
# TYPE pipeline_runs_successful counter
pipeline_runs_successful 38

# HELP pipeline_runs_failed Total number of failed pipeline runs
# TYPE pipeline_runs_failed counter
pipeline_runs_failed 7

# HELP external_repo_scans_total Total number of external repository scans
# TYPE external_repo_scans_total counter
external_repo_scans_total 12

# HELP pipeline_repo_vulnerabilities Number of vulnerabilities found in repositories
# TYPE pipeline_repo_vulnerabilities gauge
pipeline_repo_vulnerabilities{repo_name="test-project"} 3
pipeline_repo_vulnerabilities{repo_name="sample-repo"} 8
pipeline_repo_vulnerabilities{repo_name="demo-app"} 1

# HELP pipeline_repo_files_total Total number of files in repositories
# TYPE pipeline_repo_files_total gauge
pipeline_repo_files_total{repo_name="test-project"} 245
pipeline_repo_files_total{repo_name="sample-repo"} 189
pipeline_repo_files_total{repo_name="demo-app"} 156

# HELP pipeline_repo_lines_total Total number of lines of code
# TYPE pipeline_repo_lines_total gauge
pipeline_repo_lines_total{repo_name="test-project"} 15420
pipeline_repo_lines_total{repo_name="sample-repo"} 12340
pipeline_repo_lines_total{repo_name="demo-app"} 9876

# HELP security_critical_vulnerabilities_total Total critical vulnerabilities
# TYPE security_critical_vulnerabilities_total counter
security_critical_vulnerabilities_total 2

# HELP security_high_vulnerabilities_total Total high severity vulnerabilities
# TYPE security_high_vulnerabilities_total counter
security_high_vulnerabilities_total 5

# HELP security_medium_vulnerabilities_total Total medium severity vulnerabilities
# TYPE security_medium_vulnerabilities_total counter
security_medium_vulnerabilities_total 8

# HELP security_low_vulnerabilities_total Total low severity vulnerabilities
# TYPE security_low_vulnerabilities_total counter
security_low_vulnerabilities_total 15

# HELP jira_issues_created_total Total Jira issues created
# TYPE jira_issues_created_total counter
jira_issues_created_total 23

# HELP external_repo_scan_duration_seconds Duration of external repository scans
# TYPE external_repo_scan_duration_seconds histogram
external_repo_scan_duration_seconds_bucket{le="10"} 2
external_repo_scan_duration_seconds_bucket{le="30"} 5
external_repo_scan_duration_seconds_bucket{le="60"} 8
external_repo_scan_duration_seconds_bucket{le="120"} 10
external_repo_scan_duration_seconds_bucket{le="300"} 12
external_repo_scan_duration_seconds_bucket{le="+Inf"} 12
external_repo_scan_duration_seconds_sum 456
external_repo_scan_duration_seconds_count 12
EOM

echo "Sample metrics generated in sample-metrics.txt"
echo "You can use these metrics to test your dashboard visualization"
