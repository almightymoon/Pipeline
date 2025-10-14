# Repository-Specific Dashboard System

## Overview

This system automatically creates a **unique Grafana dashboard** for each repository scanned by the pipeline and updates the corresponding **Jira ticket** with a direct link to that specific dashboard.

## How It Works

### 1. **Unique Dashboard Per Repository**
- Each repository gets its own dedicated dashboard in Grafana
- The dashboard UID is generated based on the repository name (consistent across runs)
- Example:
  - `repo1` → Dashboard UID: `a1b2c3d4-...` → URL: `http://grafana/d/a1b2c3d4-.../ repo1-dashboard`
  - `repo2` → Dashboard UID: `e5f6g7h8-...` → URL: `http://grafana/d/e5f6g7h8-.../repo2-dashboard`

### 2. **Real-Time Metrics**
The dashboard pulls real-time data from the current pipeline run:
- **Security Vulnerabilities**: Critical, High, Medium, Low (from Trivy scans)
- **Code Quality**: TODO comments, debug statements, large files
- **Test Results**: Passed/failed tests, coverage percentage
- **Repository Info**: Files scanned, repository size, scan time

### 3. **Jira Integration**
- Creates a Jira ticket for each pipeline run
- Includes a direct link to the repository-specific dashboard
- Example Jira description:
  ```
  📊 DEDICATED DASHBOARD FOR THIS REPOSITORY:
  🎯 View repo1 Dashboard: http://213.109.162.134:30102/d/a1b2c3d4.../repo1
  ```

## Usage

### Automatic Usage (In Pipeline)

The script is designed to run automatically after the pipeline completes scanning a repository:

```bash
# In your pipeline workflow (after scanning completes)
./create-repo-dashboard.sh
```

### Manual Usage

You can also run it manually:

```bash
# From the project root
./create-repo-dashboard.sh

# Or directly with Python
python3 scripts/create_repo_dashboard_and_jira.py
```

## Configuration

### Repository Configuration

Edit `repos-to-scan.yaml` to configure which repositories to scan:

```yaml
repositories:
  - url: https://github.com/tensorflow/models
    name: tensorflow-models
    branch: master
    scan_type: full
  
  - url: https://github.com/almightymoon/Neuropilot
    name: Neuropilot-project
    branch: main
    scan_type: full
```

### Grafana Configuration

The script uses these Grafana settings (defined in the script):
- URL: `http://213.109.162.134:30102`
- Username: `admin`
- Password: `admin123`

### Jira Configuration

Set these environment variables for Jira integration:
```bash
export JIRA_URL="your-domain.atlassian.net"
export JIRA_EMAIL="your-email@example.com"
export JIRA_API_TOKEN="your-api-token"
export JIRA_PROJECT_KEY="PROJECT"
```

## Dashboard Features

Each repository-specific dashboard includes:

### 1. **Pipeline Status Panel**
- Total runs
- Successful runs
- Failed runs

### 2. **Security Vulnerabilities Panel**
- Critical vulnerabilities (red if > 5)
- High vulnerabilities (yellow if > 1)
- Medium vulnerabilities
- Low vulnerabilities

### 3. **Code Quality Panel**
- TODO/FIXME comments
- Debug statements
- Large files (>1MB)
- Overall quality score (0-100)

### 4. **Test Results Panel**
- Tests passed
- Tests failed
- Code coverage percentage

### 5. **Repository Information Panel**
- Repository name and URL
- Branch and scan type
- Files scanned and repository size
- Pipeline run number and timestamp

### 6. **Detailed Analysis Panels**
- Security vulnerabilities breakdown
- Code quality issues detail
- Large files optimization recommendations
- Test results analysis

## Example Workflow

### Scenario 1: Scanning tensorflow/models

1. Configure `repos-to-scan.yaml`:
   ```yaml
   repositories:
     - url: https://github.com/tensorflow/models
       name: tensorflow-models
       branch: master
       scan_type: full
   ```

2. Run the pipeline (scans the repository)

3. Run the dashboard script:
   ```bash
   ./create-repo-dashboard.sh
   ```

4. **Output**:
   - ✅ Dashboard created: `http://213.109.162.134:30102/d/abc123.../tensorflow-models`
   - ✅ Jira issue created with link to dashboard

### Scenario 2: Scanning Neuropilot

1. Update `repos-to-scan.yaml`:
   ```yaml
   repositories:
     - url: https://github.com/almightymoon/Neuropilot
       name: Neuropilot-project
       branch: main
       scan_type: full
   ```

2. Run the pipeline (scans the repository)

3. Run the dashboard script:
   ```bash
   ./create-repo-dashboard.sh
   ```

4. **Output**:
   - ✅ Dashboard created: `http://213.109.162.134:30102/d/def456.../neuropilot-project`
   - ✅ Jira issue created with link to dashboard

## Benefits

### 1. **Unique Dashboards**
- Each repository has its own dedicated dashboard
- No confusion between different repositories
- Historical data is preserved per repository

### 2. **Direct Jira Links**
- Jira tickets link directly to the correct dashboard
- Team members can quickly access relevant metrics
- No need to search for the right dashboard

### 3. **Real-Time Data**
- Dashboards show actual pipeline metrics
- No hardcoded values
- Reflects the current state of each repository

### 4. **Consistent UIDs**
- Repository dashboards use consistent UIDs
- Same repository always gets the same dashboard UID
- Updates existing dashboard instead of creating duplicates

## Troubleshooting

### Issue: Dashboard not created

**Check:**
1. Grafana is accessible: `curl http://213.109.162.134:30102`
2. Credentials are correct (admin/admin123)
3. Repository name is valid (no special characters)

**Solution:**
```bash
# Test Grafana connection
curl -u admin:admin123 http://213.109.162.134:30102/api/health
```

### Issue: Jira ticket not created

**Check:**
1. Environment variables are set:
   ```bash
   echo $JIRA_URL
   echo $JIRA_EMAIL
   echo $JIRA_API_TOKEN
   echo $JIRA_PROJECT_KEY
   ```

2. Jira credentials are valid

**Solution:**
```bash
# Test Jira connection
curl -u "$JIRA_EMAIL:$JIRA_API_TOKEN" \
  https://$JIRA_URL/rest/api/2/myself
```

### Issue: No metrics showing

**Check:**
1. Pipeline scan completed successfully
2. Scan result files exist:
   - `/tmp/trivy-results.json`
   - `/tmp/quality-results.txt`
   - `/tmp/scan-metrics.txt`

**Solution:**
Make sure the pipeline completes all scan steps before running the dashboard script.

## File Structure

```
pipeline/
├── scripts/
│   └── create_repo_dashboard_and_jira.py  # Main script
├── create-repo-dashboard.sh               # Wrapper script
├── repos-to-scan.yaml                     # Repository configuration
└── REPOSITORY_DASHBOARD_GUIDE.md          # This guide
```

## API Endpoints Used

### Grafana API
- **Create/Update Dashboard**: `POST /api/dashboards/db`
- **Get Dashboard**: `GET /api/dashboards/uid/{uid}`

### Jira API
- **Create Issue**: `POST /rest/api/2/issue`

## Dashboard URL Format

```
http://213.109.162.134:30102/d/{dashboard_uid}/{dashboard_slug}

Examples:
- http://213.109.162.134:30102/d/a1b2c3d4-e5f6-7890-abcd-ef1234567890/tensorflow-models
- http://213.109.162.134:30102/d/12345678-90ab-cdef-1234-567890abcdef/neuropilot-project
```

## Advanced Usage

### Customize Dashboard Template

Edit `scripts/create_repo_dashboard_and_jira.py` and modify the `create_dashboard_for_repo()` function to customize:
- Panel layout
- Colors and thresholds
- Additional metrics
- Panel content

### Add Custom Metrics

To add custom metrics:
1. Update `get_repo_metrics_from_pipeline()` to read your custom data
2. Add new panels in `create_dashboard_for_repo()`
3. Update Jira description in `create_jira_issue_with_dashboard()`

## Next Steps

1. **Integration**: Add `./create-repo-dashboard.sh` to your pipeline workflow
2. **Testing**: Test with different repositories
3. **Customization**: Adjust dashboard panels to your needs
4. **Monitoring**: Check dashboards regularly for security issues

## Support

For issues or questions:
1. Check the troubleshooting section above
2. Review pipeline logs for error messages
3. Verify Grafana and Jira connectivity
4. Ensure all environment variables are set correctly

