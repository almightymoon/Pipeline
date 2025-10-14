# Quick Start - Repository Dashboards

## 🚀 Get Started in 3 Steps

### Step 1: Configure Repository
```bash
# Edit repos-to-scan.yaml
vim repos-to-scan.yaml
```

```yaml
repositories:
  - url: https://github.com/YOUR-ORG/YOUR-REPO
    name: your-repo-name
    branch: main
    scan_type: full
```

### Step 2: Run Pipeline
```bash
# Your pipeline runs and scans the repository
# (This happens automatically in CI/CD or manually)
```

### Step 3: Create Dashboard & Jira
```bash
# Run this after pipeline completes
./create-repo-dashboard.sh
```

**Output:**
```
✅ DASHBOARD CREATED SUCCESSFULLY!
Repository: your-repo-name
Dashboard URL: http://213.109.162.134:30102/d/abc123.../your-repo-name

✅ JIRA ISSUE CREATED SUCCESSFULLY!
Issue Key: PROJ-123
Dashboard Link: http://213.109.162.134:30102/d/abc123.../your-repo-name
```

---

## 📋 Commands Reference

### Create Dashboard and Jira Ticket
```bash
./create-repo-dashboard.sh
```

### Create Dashboard Only (Python)
```bash
python3 scripts/create_repo_dashboard_and_jira.py
```

### Test Grafana Connection
```bash
curl -u admin:admin123 http://213.109.162.134:30102/api/health
```

---

## 🎯 What You Get

### 1. Unique Dashboard
- **URL**: `http://213.109.162.134:30102/d/{uid}/{repo-name}`
- **Content**: Real-time metrics from your repository scan
- **Updates**: Auto-refresh every 30 seconds

### 2. Jira Ticket
- **Summary**: "Pipeline Scan Complete: your-repo-name"
- **Description**: Full scan report with dashboard link
- **Links**: Direct link to repository and dashboard

### 3. Metrics Tracked
- ✅ Security vulnerabilities (Critical, High, Medium, Low)
- ✅ Code quality (TODO comments, debug statements)
- ✅ Test results (passed, failed, coverage)
- ✅ Repository info (files scanned, size)

---

## 🔧 Configuration

### Grafana (Default)
```
URL: http://213.109.162.134:30102
Username: admin
Password: admin123
```

### Jira (Environment Variables)
```bash
export JIRA_URL="your-domain.atlassian.net"
export JIRA_EMAIL="your-email@example.com"
export JIRA_API_TOKEN="your-api-token"
export JIRA_PROJECT_KEY="PROJ"
```

---

## 📊 Example Dashboards

### tensorflow-models
```
URL: http://213.109.162.134:30102/d/e03ed124-7224-1aeb-f53e-31d9ccf48a46/pipeline-dashboard-tensorflow-models
UID: e03ed124-7224-1aeb-f53e-31d9ccf48a46
Status: ✅ Active
```

### Your Repository
```
URL: Will be generated when you run the script
UID: Unique and consistent for your repo name
Status: Ready to create
```

---

## ❓ FAQ

**Q: Do I need to create a new dashboard for each pipeline run?**
A: No! The same repository always gets the same dashboard UID, so it updates the existing dashboard.

**Q: What if I don't have Jira configured?**
A: The dashboard will still be created. Jira is optional.

**Q: Can I customize the dashboard?**
A: Yes! Edit `scripts/create_repo_dashboard_and_jira.py` to customize panels.

**Q: How do I view the dashboard?**
A: Use the URL printed by the script, or find it in Grafana under "Dashboards".

---

## 🎓 Learn More

- **Full Guide**: `REPOSITORY_DASHBOARD_GUIDE.md`
- **Demo**: `DASHBOARD_DEMO.md`
- **Main README**: `README.md`

---

## ✅ Verified Working

```
✅ Dashboard creation: Tested and working
✅ Unique UIDs per repository: Verified
✅ Grafana integration: Active
✅ Jira integration: Configured
✅ Real-time metrics: Collecting data
```

**Status: Production Ready** 🎉

