#!/bin/bash

# Advanced Grafana Dashboard Import Script
# This script imports a comprehensive dashboard with advanced visualizations

echo "🚀 Importing Advanced Grafana Dashboard"
echo "======================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Configuration
GRAFANA_URL="http://213.109.162.134:30102"
DASHBOARD_FILE="monitoring/advanced-grafana-dashboard.json"
DASHBOARD_TITLE="Advanced ML Pipeline - External Repository Scanner"

# Function to check if file exists
check_dashboard_file() {
    if [ ! -f "$DASHBOARD_FILE" ]; then
        echo -e "${RED}❌ Dashboard file not found: $DASHBOARD_FILE${NC}"
        exit 1
    fi
    echo -e "${GREEN}✅ Dashboard file found: $DASHBOARD_FILE${NC}"
}

# Function to display dashboard preview
show_dashboard_preview() {
    echo -e "${BLUE}📊 Advanced Dashboard Features:${NC}"
    echo ""
    echo -e "${PURPLE}🎯 Key Panels:${NC}"
    echo "  • 🚀 Pipeline Overview - Total runs with color-coded thresholds"
    echo "  • ✅ Success Rate - Percentage with green/yellow/red indicators"
    echo "  • 🔍 Repositories Scanned - Real-time count"
    echo "  • ⚠️ Vulnerabilities Found - Security risk indicators"
    echo ""
    echo -e "${PURPLE}📈 Advanced Visualizations:${NC}"
    echo "  • 📈 Pipeline Runs Timeline - Smooth line charts with trends"
    echo "  • 🔐 Security Vulnerabilities Over Time - Stacked area chart"
    echo "  • 📊 Repository Types Distribution - Interactive pie chart"
    echo "  • 🔍 Scan Types Distribution - Donut chart with scan types"
    echo "  • ⚡ Scan Performance - Multiple percentile metrics"
    echo "  • 🔐 Security Vulnerabilities Heatmap - Repository vs time"
    echo "  • 📈 Code Quality Metrics - Multi-line time series"
    echo ""
    echo -e "${PURPLE}📋 Data Tables:${NC}"
    echo "  • 📋 Currently Scanning Repository - Live status table"
    echo "  • 📊 Recent Repository Scans - Top 10 with filtering"
    echo ""
    echo -e "${PURPLE}🔧 Interactive Features:${NC}"
    echo "  • 🎛️ Repository Filter - Filter by specific repos"
    echo "  • 🎛️ Scan Type Filter - Filter by scan types"
    echo "  • 🎛️ Severity Filter - Filter by vulnerability severity"
    echo "  • 📝 Live Scan Logs - Real-time log streaming"
    echo "  • 🔗 Quick Links - GitHub Actions, Jira, Config files"
    echo ""
    echo -e "${PURPLE}🚨 Alerting & Annotations:${NC}"
    echo "  • 📍 Pipeline Events - Automatic annotations"
    echo "  • 📍 Critical Vulnerabilities - Security alerts"
    echo "  • 📍 Scan Failures - Failure tracking"
    echo "  • 🚨 Active Alerts - Real-time alert status"
}

# Function to create import instructions
create_import_instructions() {
    echo -e "${YELLOW}📋 Import Instructions:${NC}"
    echo ""
    echo "1. Open Grafana in your browser:"
    echo -e "   ${BLUE}$GRAFANA_URL${NC}"
    echo ""
    echo "2. Navigate to Dashboards:"
    echo "   • Click 'Dashboards' in the left sidebar"
    echo "   • Click 'Import' button"
    echo ""
    echo "3. Import the dashboard:"
    echo "   • Click 'Upload JSON file'"
    echo "   • Select: ${BLUE}$DASHBOARD_FILE${NC}"
    echo "   • Click 'Load'"
    echo ""
    echo "4. Configure data source:"
    echo "   • Set Prometheus as data source"
    echo "   • Click 'Import'"
    echo ""
    echo "5. Access your new dashboard:"
    echo "   • Dashboard will be available in the dashboard list"
    echo "   • Bookmark for easy access"
    echo ""
}

# Function to create sample data generator
create_sample_data_script() {
    echo -e "${BLUE}📊 Creating sample data generator...${NC}"
    
    cat > generate-sample-metrics.sh << 'EOF'
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
EOF

    chmod +x generate-sample-metrics.sh
    echo -e "${GREEN}✅ Sample data generator created: generate-sample-metrics.sh${NC}"
}

# Function to create dashboard comparison
create_dashboard_comparison() {
    echo -e "${BLUE}📊 Dashboard Comparison:${NC}"
    echo ""
    echo -e "${RED}❌ OLD Dashboard (Basic):${NC}"
    echo "  • Single 'Pipeline Summary' panel"
    echo "  • Static numbers only"
    echo "  • No visualizations"
    echo "  • No interactivity"
    echo "  • No filtering"
    echo "  • No real-time updates"
    echo ""
    echo -e "${GREEN}✅ NEW Dashboard (Advanced):${NC}"
    echo "  • 16 comprehensive panels"
    echo "  • Multiple chart types (line, pie, heatmap, table)"
    echo "  • Interactive filtering and drill-down"
    echo "  • Real-time data streaming"
    echo "  • Color-coded thresholds and alerts"
    echo "  • Live log streaming"
    echo "  • Quick action links"
    echo "  • Automated annotations"
    echo "  • Performance metrics"
    echo "  • Security heatmaps"
    echo ""
}

# Main execution
main() {
    echo -e "${PURPLE}🎯 Advanced Grafana Dashboard Import${NC}"
    echo ""
    
    check_dashboard_file
    echo ""
    
    show_dashboard_preview
    echo ""
    
    create_dashboard_comparison
    echo ""
    
    create_import_instructions
    echo ""
    
    create_sample_data_script
    echo ""
    
    echo -e "${GREEN}🎉 Advanced Dashboard Ready for Import!${NC}"
    echo ""
    echo -e "${YELLOW}📋 Summary:${NC}"
    echo "• Dashboard file: ${BLUE}$DASHBOARD_FILE${NC}"
    echo "• Grafana URL: ${BLUE}$GRAFANA_URL${NC}"
    echo "• Features: 16 panels, interactive filtering, real-time data"
    echo "• Sample data generator: ${BLUE}generate-sample-metrics.sh${NC}"
    echo ""
    echo -e "${PURPLE}🚀 Next Steps:${NC}"
    echo "1. Import the dashboard using the instructions above"
    echo "2. Run ./generate-sample-metrics.sh to test with sample data"
    echo "3. Configure your Prometheus data source"
    echo "4. Enjoy your advanced dashboard! 🎉"
    echo ""
}

# Run main function
main "$@"
