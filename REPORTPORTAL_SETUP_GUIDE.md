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

