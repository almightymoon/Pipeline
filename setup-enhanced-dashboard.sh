#!/bin/bash

# Enhanced Grafana Dashboard Setup Script
# This script deploys a comprehensive dashboard for external repository scanning

echo "🚀 Setting up Enhanced Grafana Dashboard for External Repository Scanning"
echo "=================================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
GRAFANA_URL="http://213.109.162.134:30102"
DASHBOARD_FILE="monitoring/enhanced-grafana-dashboard.json"
DASHBOARD_TITLE="Enhanced ML Pipeline - External Repository Scanner"

# Function to check if kubectl is available
check_kubectl() {
    if ! command -v kubectl &> /dev/null; then
        echo -e "${RED}❌ kubectl is not installed or not in PATH${NC}"
        exit 1
    fi
    echo -e "${GREEN}✅ kubectl found${NC}"
}

# Function to check Grafana connectivity
check_grafana() {
    echo -e "${BLUE}🔍 Checking Grafana connectivity...${NC}"
    
    if curl -s --connect-timeout 10 "$GRAFANA_URL/api/health" > /dev/null; then
        echo -e "${GREEN}✅ Grafana is accessible at $GRAFANA_URL${NC}"
    else
        echo -e "${RED}❌ Cannot connect to Grafana at $GRAFANA_URL${NC}"
        echo -e "${YELLOW}💡 Make sure Grafana is running and accessible${NC}"
        exit 1
    fi
}

# Function to create dashboard via API
create_dashboard() {
    echo -e "${BLUE}📊 Creating enhanced dashboard...${NC}"
    
    if [ ! -f "$DASHBOARD_FILE" ]; then
        echo -e "${RED}❌ Dashboard file not found: $DASHBOARD_FILE${NC}"
        exit 1
    fi
    
    # Create dashboard using Grafana API
    DASHBOARD_JSON=$(cat "$DASHBOARD_FILE")
    
    echo -e "${YELLOW}📝 Dashboard configuration:${NC}"
    echo "  Title: $DASHBOARD_TITLE"
    echo "  File: $DASHBOARD_FILE"
    echo "  URL: $GRAFANA_URL"
    
    # Note: This would require Grafana API authentication in a real scenario
    echo -e "${GREEN}✅ Dashboard configuration ready${NC}"
    echo -e "${YELLOW}💡 To deploy manually:${NC}"
    echo "  1. Open Grafana: $GRAFANA_URL"
    echo "  2. Go to Dashboards > Import"
    echo "  3. Upload the file: $DASHBOARD_FILE"
    echo "  4. Configure data source as 'Prometheus'"
    echo "  5. Save dashboard"
}

# Function to create Prometheus metrics configuration
create_prometheus_config() {
    echo -e "${BLUE}⚙️ Creating Prometheus configuration for metrics...${NC}"
    
    cat > monitoring/prometheus-external-repos.yml << 'EOF'
# Prometheus configuration for External Repository Scanner metrics
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'external-repo-scanner'
    static_configs:
      - targets: ['pipeline-metrics:8080']
    scrape_interval: 30s
    metrics_path: /metrics
    
  - job_name: 'github-actions'
    static_configs:
      - targets: ['github-webhook:9090']
    scrape_interval: 60s
    
  - job_name: 'jira-integration'
    static_configs:
      - targets: ['jira-metrics:9091']
    scrape_interval: 120s

# Recording rules for external repository metrics
rule_files:
  - "external-repo-rules.yml"

# Alerting rules
alerting:
  alertmanagers:
    - static_configs:
        - targets:
          - alertmanager:9093
EOF

    echo -e "${GREEN}✅ Prometheus configuration created${NC}"
}

# Function to create alerting rules
create_alerting_rules() {
    echo -e "${BLUE}🚨 Creating alerting rules...${NC}"
    
    cat > monitoring/external-repo-rules.yml << 'EOF'
groups:
  - name: external-repo-scanner
    rules:
      - alert: HighVulnerabilityCount
        expr: pipeline_repo_vulnerabilities > 10
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High vulnerability count detected"
          description: "Repository {{ $labels.repo_name }} has {{ $value }} vulnerabilities"
          
      - alert: ScanFailure
        expr: increase(pipeline_external_repo_scan_failures[5m]) > 0
        for: 2m
        labels:
          severity: critical
        annotations:
          summary: "External repository scan failed"
          description: "Scan failed for repository {{ $labels.repo_name }}"
          
      - alert: SecretsDetected
        expr: pipeline_repo_secrets_found > 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "Secrets detected in repository"
          description: "{{ $value }} secrets found in {{ $labels.repo_name }}"
EOF

    echo -e "${GREEN}✅ Alerting rules created${NC}"
}

# Function to create documentation
create_documentation() {
    echo -e "${BLUE}📚 Creating documentation...${NC}"
    
    cat > ENHANCED_DASHBOARD_GUIDE.md << 'EOF'
# Enhanced Grafana Dashboard Guide

## Overview
The Enhanced Grafana Dashboard provides comprehensive monitoring for external repository scanning with detailed metrics, alerts, and visualizations.

## Dashboard Features

### 📊 Main Panels

1. **Pipeline Overview**
   - Total pipeline runs
   - Success/failure rates
   - Real-time status

2. **External Repository Scan Status**
   - Repositories scanned
   - Vulnerabilities found
   - Secrets detected

3. **Currently Scanning Repository**
   - Real-time scan progress
   - Repository details
   - Current scan type

4. **Security Vulnerabilities Timeline**
   - Vulnerability trends over time
   - Critical/High severity breakdown
   - Rate of vulnerability discovery

5. **Repository Types Scanned**
   - Distribution by technology (Python, JS, Java, etc.)
   - Scan type breakdown (full, security-only, quick)

6. **Detailed Scan Results**
   - Live log streaming
   - Detailed scan output
   - Error tracking

7. **Jira Integration Status**
   - Issues created automatically
   - Integration health
   - Issue tracking metrics

8. **Scan Performance**
   - Scan duration metrics
   - Performance trends
   - Bottleneck identification

9. **Success Rate**
   - Overall pipeline health
   - Historical trends
   - Quality metrics

10. **Recent Repository Scans**
    - Last 10 scanned repositories
    - Status and results summary
    - Quick access to details

### 🔧 Configuration

#### Data Sources
- **Prometheus**: Primary metrics collection
- **Loki**: Log aggregation and search
- **GitHub**: Webhook integration

#### Variables
- `repository_filter`: Filter by specific repositories
- `time_range`: Adjustable time windows
- `scan_type`: Filter by scan types

### 🚨 Alerts

1. **High Vulnerability Count**
   - Triggers when >10 vulnerabilities found
   - Warning level alert
   - 5-minute evaluation period

2. **Scan Failure**
   - Triggers on scan failures
   - Critical level alert
   - Immediate notification

3. **Secrets Detected**
   - Triggers when secrets found
   - Critical level alert
   - Requires immediate attention

### 📈 Metrics Collected

#### Repository Metrics
- `pipeline_repo_files_total`: Total files in repository
- `pipeline_repo_lines_total`: Lines of code
- `pipeline_repo_python_files`: Python files count
- `pipeline_repo_javascript_files`: JavaScript files count
- `pipeline_repo_java_files`: Java files count

#### Security Metrics
- `pipeline_repo_vulnerabilities`: Vulnerability count
- `pipeline_repo_secrets_found`: Secrets detected
- `security_vulnerabilities_total`: Total vulnerabilities
- `security_critical_vulnerabilities_total`: Critical vulnerabilities

#### Performance Metrics
- `external_repo_scan_duration_seconds`: Scan duration
- `pipeline_runs_total`: Total pipeline runs
- `pipeline_runs_successful`: Successful runs
- `pipeline_runs_failed`: Failed runs

### 🔗 Integration Points

#### Jira Integration
- Automatic issue creation
- Detailed scan reports
- Link to Grafana dashboard
- GitHub Actions integration

#### GitHub Actions
- Real-time metrics push
- Scan result reporting
- Performance tracking
- Error logging

### 📱 Access Information

- **Grafana URL**: http://213.109.162.134:30102/d/ml-all-results/ml-pipeline-all-results
- **Dashboard ID**: ml-pipeline-all-results
- **Refresh Rate**: 5 seconds
- **Time Range**: Last 6 hours (configurable)

### 🛠️ Troubleshooting

#### Common Issues

1. **No Data Showing**
   - Check Prometheus connectivity
   - Verify metrics collection
   - Check data source configuration

2. **Missing Metrics**
   - Ensure workflow is running
   - Check metrics.txt generation
   - Verify Prometheus scraping

3. **Alerts Not Firing**
   - Check alerting rules syntax
   - Verify AlertManager configuration
   - Check notification channels

#### Support
- Check GitHub Actions logs
- Review Prometheus targets
- Monitor Grafana logs
- Contact system administrator

### 🔄 Updates

To update the dashboard:
1. Modify `monitoring/enhanced-grafana-dashboard.json`
2. Re-import in Grafana
3. Update Prometheus configuration if needed
4. Test new metrics collection

EOF

    echo -e "${GREEN}✅ Documentation created: ENHANCED_DASHBOARD_GUIDE.md${NC}"
}

# Main execution
main() {
    echo -e "${BLUE}🎯 Starting Enhanced Dashboard Setup...${NC}"
    
    check_kubectl
    check_grafana
    create_dashboard
    create_prometheus_config
    create_alerting_rules
    create_documentation
    
    echo ""
    echo -e "${GREEN}🎉 Enhanced Dashboard Setup Complete!${NC}"
    echo ""
    echo -e "${YELLOW}📋 Next Steps:${NC}"
    echo "1. Import the dashboard in Grafana:"
    echo "   📁 File: $DASHBOARD_FILE"
    echo "   🌐 URL: $GRAFANA_URL/dashboard/import"
    echo ""
    echo "2. Configure Prometheus data source"
    echo ""
    echo "3. Test the pipeline with a repository scan"
    echo ""
    echo "4. Monitor the enhanced dashboard for real-time metrics"
    echo ""
    echo -e "${BLUE}📊 Dashboard URL:${NC}"
    echo "   $GRAFANA_URL/d/ml-all-results/ml-pipeline-all-results"
    echo ""
    echo -e "${GREEN}✅ Setup completed successfully!${NC}"
}

# Run main function
main "$@"
