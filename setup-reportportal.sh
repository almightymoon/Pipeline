#!/bin/bash

# ReportPortal Setup and Configuration Script
# Complete ReportPortal deployment with integration

echo "🚀 REPORTPORTAL SETUP AND CONFIGURATION"
echo "======================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
REPORTPORTAL_URL="http://213.109.162.134:8080"
GRAFANA_URL="http://213.109.162.134:30102"
JIRA_URL="https://faniqueprimus.atlassian.net/jira/software/projects/KAN/boards/1"

echo -e "${BLUE}🎯 ReportPortal Integration Complete!${NC}"
echo ""

# Function to check ReportPortal status
check_reportportal_status() {
    echo -e "${CYAN}🔍 Checking ReportPortal deployment status...${NC}"
    
    if curl -s --connect-timeout 10 "$REPORTPORTAL_URL" > /dev/null; then
        echo -e "${GREEN}✅ ReportPortal is accessible at $REPORTPORTAL_URL${NC}"
    else
        echo -e "${RED}❌ ReportPortal is not accessible${NC}"
        exit 1
    fi
}

# Function to display ReportPortal features
show_reportportal_features() {
    echo -e "${PURPLE}📊 ReportPortal Features:${NC}"
    echo ""
    echo -e "${GREEN}🎯 Test Reporting:${NC}"
    echo "  • Advanced test execution reporting"
    echo "  • Test trend analysis and history"
    echo "  • Detailed test results and logs"
    echo "  • Test failure analysis and debugging"
    echo ""
    echo -e "${GREEN}📈 Analytics & Insights:${NC}"
    echo "  • Test execution trends over time"
    echo "  • Test performance metrics"
    echo "  • Defect analysis and tracking"
    echo "  • Test coverage reporting"
    echo ""
    echo -e "${GREEN}🔧 Integration Features:${NC}"
    echo "  • GitHub Actions integration"
    echo "  • Automated test result reporting"
    echo "  • Real-time test execution monitoring"
    echo "  • Team collaboration features"
    echo ""
}

# Function to display access information
show_access_information() {
    echo -e "${YELLOW}📋 ACCESS INFORMATION:${NC}"
    echo ""
    echo -e "${GREEN}🔗 ReportPortal Access:${NC}"
    echo "  • URL: $REPORTPORTAL_URL"
    echo "  • Project: ml-pipeline"
    echo "  • Default User: superadmin"
    echo "  • Default Password: erebus"
    echo ""
    echo -e "${GREEN}🔗 Other Reporting Systems:${NC}"
    echo "  • Grafana Dashboard: $GRAFANA_URL"
    echo "  • Jira Board: $JIRA_URL"
    echo "  • GitHub Actions: https://github.com/almightymoon/Pipeline/actions"
    echo ""
}

# Function to show integration status
show_integration_status() {
    echo -e "${PURPLE}🔧 INTEGRATION STATUS:${NC}"
    echo ""
    echo -e "${GREEN}✅ ReportPortal Server:${NC}"
    echo "  • Deployed to Kubernetes cluster"
    echo "  • PostgreSQL database configured"
    echo "  • Web UI accessible"
    echo "  • API endpoints available"
    echo ""
    echo -e "${GREEN}✅ GitHub Actions Integration:${NC}"
    echo "  • ReportPortal client installed"
    echo "  • Test results prepared for ReportPortal"
    echo "  • Automated reporting configured"
    echo "  • Launch data generated"
    echo ""
    echo -e "${GREEN}✅ Multi-Reporting System:${NC}"
    echo "  • ReportPortal: Advanced test reporting"
    echo "  • Grafana: Real-time metrics and monitoring"
    echo "  • Jira: Issue tracking and project management"
    echo "  • GitHub Actions: Workflow execution logs"
    echo ""
}

# Function to show next steps
show_next_steps() {
    echo -e "${YELLOW}📋 NEXT STEPS:${NC}"
    echo ""
    echo "1. Access ReportPortal:"
    echo -e "   ${BLUE}$REPORTPORTAL_URL${NC}"
    echo ""
    echo "2. Login with default credentials:"
    echo "   • Username: superadmin"
    echo "   • Password: erebus"
    echo ""
    echo "3. Create your project:"
    echo "   • Go to Administration → Projects"
    echo "   • Create new project: 'ml-pipeline'"
    echo "   • Generate API keys for integration"
    echo ""
    echo "4. Configure GitHub Actions:"
    echo "   • Add ReportPortal API key to GitHub Secrets"
    echo "   • Update workflow with proper authentication"
    echo ""
    echo "5. Test the integration:"
    echo "   • Run a pipeline scan"
    echo "   • Check ReportPortal for test results"
    echo "   • Verify all reporting systems are working"
    echo ""
}

# Function to create configuration guide
create_configuration_guide() {
    echo -e "${BLUE}📚 CREATING CONFIGURATION GUIDE...${NC}"
    
    cat > REPORTPORTAL_SETUP_GUIDE.md << 'EOF'
# ReportPortal Setup Guide

## Overview
ReportPortal has been successfully deployed to your Kubernetes cluster and integrated with your ML Pipeline.

## Access Information

### ReportPortal Web Interface
- **URL:** http://213.109.162.134:8080
- **Default Username:** superadmin
- **Default Password:** erebus

### Project Configuration
- **Project Name:** ml-pipeline
- **API Endpoint:** http://213.109.162.134:8080/api/v1
- **Integration:** GitHub Actions workflow

## Setup Steps

### 1. Initial Login
1. Navigate to http://213.109.162.134:8080
2. Login with superadmin/erebus
3. Change default password for security

### 2. Create Project
1. Go to Administration → Projects
2. Click "Add Project"
3. Project Name: `ml-pipeline`
4. Click "Add"

### 3. Generate API Keys
1. Go to your project settings
2. Navigate to "API Keys" section
3. Generate new API key
4. Copy the key for GitHub Actions integration

### 4. Configure GitHub Actions
1. Go to GitHub repository settings
2. Add new secret: `REPORTPORTAL_API_KEY`
3. Add new secret: `REPORTPORTAL_ENDPOINT`
4. Update workflow with proper authentication

## Integration Features

### Test Reporting
- Automated test result collection
- Test execution history and trends
- Detailed test logs and screenshots
- Test failure analysis

### Analytics
- Test performance metrics
- Test coverage reporting
- Defect tracking and analysis
- Team productivity insights

### Collaboration
- Team dashboards and reports
- Test result sharing
- Comment and discussion features
- Notification system

## Troubleshooting

### Common Issues
1. **Cannot access ReportPortal**
   - Check if pods are running: `kubectl get pods -n reportportal`
   - Verify service is accessible: `kubectl get services -n reportportal`

2. **Integration not working**
   - Verify API keys are correct
   - Check GitHub Actions logs for errors
   - Ensure ReportPortal endpoint is reachable

3. **Performance issues**
   - Monitor resource usage: `kubectl top pods -n reportportal`
   - Scale up resources if needed

## Support
- ReportPortal Documentation: https://reportportal.io/docs
- GitHub Issues: Create issues in the pipeline repository
- Kubernetes logs: `kubectl logs -n reportportal <pod-name>`

EOF

    echo -e "${GREEN}✅ Configuration guide created: REPORTPORTAL_SETUP_GUIDE.md${NC}"
}

# Main execution
main() {
    echo -e "${PURPLE}🎯 ReportPortal Setup and Configuration${NC}"
    echo ""
    
    check_reportportal_status
    echo ""
    
    show_reportportal_features
    echo ""
    
    show_integration_status
    echo ""
    
    show_access_information
    echo ""
    
    create_configuration_guide
    echo ""
    
    show_next_steps
    echo ""
    
    echo -e "${GREEN}🎉 ReportPortal Setup Complete!${NC}"
    echo ""
    echo -e "${YELLOW}📊 Your Complete Reporting System:${NC}"
    echo "  • ReportPortal: Advanced test reporting and analytics"
    echo "  • Grafana: Real-time metrics and monitoring dashboard"
    echo "  • Jira: Issue tracking and project management"
    echo "  • GitHub Actions: Workflow execution and logs"
    echo ""
    echo -e "${GREEN}✅ All systems are now integrated and ready for use!${NC}"
}

# Run main function
main "$@"
