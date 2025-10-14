# Repository-Specific Dashboard System - Complete Overview

## 🎯 What This System Does

Creates a **unique Grafana dashboard** for each repository you scan, and automatically updates **Jira tickets** with direct links to the correct dashboard.

### Before This System ❌
- One dashboard for all repositories → Confusion
- Jira tickets pointed to generic dashboards
- Hard to track which metrics belong to which repository
- Manual linking required

### After This System ✅
- **Repo 1** → Unique Dashboard 1 → Jira links to Dashboard 1
- **Repo 2** → Unique Dashboard 2 → Jira links to Dashboard 2
- **Repo 3** → Unique Dashboard 3 → Jira links to Dashboard 3
- Each dashboard shows real-time metrics for its specific repository
- Fully automated - no manual work needed

---

## 🔄 How It Works

```
┌─────────────────────────────────────────────────────────────────┐
│                    PIPELINE WORKFLOW                             │
└─────────────────────────────────────────────────────────────────┘

1. Configure Repository (repos-to-scan.yaml)
   │
   ├─> Repository: tensorflow/models
   │   Name: tensorflow-models
   │   Branch: master
   │
   ▼
2. Run Pipeline
   │
   ├─> Clone repository
   ├─> Security scan (Trivy)
   ├─> Code quality analysis
   ├─> Run tests
   └─> Collect metrics
   │
   ▼
3. Create Dashboard & Jira
   │
   ├─> Run: ./create-repo-dashboard.sh
   │
   ├─> Generate unique UID for repository
   │   └─> UID: e03ed124-7224-1aeb-f53e-31d9ccf48a46
   │
   ├─> Create Grafana dashboard
   │   └─> URL: http://213.109.162.134:30102/d/e03ed124-7224-1aeb-f53e-31d9ccf48a46/tensorflow-models
   │
   └─> Create Jira ticket
       └─> Links to: http://213.109.162.134:30102/d/e03ed124-7224-1aeb-f53e-31d9ccf48a46/tensorflow-models
   │
   ▼
4. Results
   │
   ├─> ✅ Dashboard live with real-time metrics
   ├─> ✅ Jira ticket has correct dashboard link
   └─> ✅ Team can track this repository's metrics
```

---

## 📁 File Structure

```
pipeline/
├── scripts/
│   ├── create_repo_dashboard_and_jira.py  ← Main script (creates dashboard & Jira)
│   ├── create_dynamic_dashboard.py         ← Old script (deprecated)
│   ├── create_jira_issue.py                ← Old script (deprecated)
│   └── create_jira_failure_issue.py        ← Failure handler
│
├── create-repo-dashboard.sh                ← Run this! (wrapper script)
│
├── repos-to-scan.yaml                      ← Configure repositories here
│
├── REPOSITORY_DASHBOARD_GUIDE.md           ← Full documentation
├── DASHBOARD_DEMO.md                       ← Live examples
├── QUICK_START_DASHBOARDS.md               ← Quick start guide
└── SYSTEM_OVERVIEW.md                      ← This file
```

---

## 🚀 Quick Start

### 1. Configure Repository
```bash
# Edit repos-to-scan.yaml
vim repos-to-scan.yaml
```

```yaml
repositories:
  - url: https://github.com/tensorflow/models
    name: tensorflow-models
    branch: master
    scan_type: full
```

### 2. Run Pipeline (Scans Repository)
```bash
# Your CI/CD pipeline runs automatically
# Or trigger manually
```

### 3. Create Dashboard & Jira Ticket
```bash
./create-repo-dashboard.sh
```

### 4. View Results
```
✅ Dashboard: http://213.109.162.134:30102/d/{uid}/tensorflow-models
✅ Jira Ticket: PROJ-123 (with dashboard link)
```

---

## 📊 Dashboard Features

Each repository-specific dashboard includes:

### Top Row: Key Metrics
- **Pipeline Status**: Total runs, successful, failed
- **Security Vulnerabilities**: Critical, high, medium, low
- **Code Quality**: TODO comments, debug statements, quality score
- **Test Results**: Passed, failed, coverage

### Middle Row: Details
- **Repository Information**: URL, branch, files scanned, size
- **Security Analysis**: Detailed vulnerability breakdown
- **Quality Analysis**: Code quality issues with recommendations

### Bottom Row: Deep Dive
- **Large Files**: Files >1MB with optimization tips
- **Test Details**: Test results analysis

### Auto-Refresh
- Updates every 30 seconds
- Shows latest pipeline data
- Real-time metrics

---

## 🔗 Jira Integration

### Jira Ticket Format
```
Title: 🔍 Pipeline Scan Complete: tensorflow-models - 2025-10-14 19:30:00 UTC

Description:
┌─────────────────────────────────────────┐
│ 🔍 EXTERNAL REPOSITORY SCAN REPORT      │
└─────────────────────────────────────────┘

Repository: tensorflow-models
URL: https://github.com/tensorflow/models
Branch: master

📊 DEDICATED DASHBOARD FOR THIS REPOSITORY:
🎯 View tensorflow-models Dashboard
   http://213.109.162.134:30102/d/e03ed124.../tensorflow-models

Security: 0 vulnerabilities ✅
Quality: 0 improvements needed ✅
Tests: 23 passed, 0 failed ✅
Coverage: 85.2%
```

---

## 🎨 Example Use Cases

### Use Case 1: Daily Security Scans
```
Day 1: Scan repo1 → Dashboard 1 → Jira Ticket 1
Day 2: Scan repo2 → Dashboard 2 → Jira Ticket 2
Day 3: Scan repo1 → Updates Dashboard 1 → Jira Ticket 3 (links to Dashboard 1)
```

### Use Case 2: Multi-Team Organization
```
Team A: Scans their repos → Team A dashboards
Team B: Scans their repos → Team B dashboards
Team C: Scans their repos → Team C dashboards
Each team sees only their relevant dashboards in Jira
```

### Use Case 3: Continuous Monitoring
```
Week 1: Scan → Baseline metrics
Week 2: Scan → Compare with Week 1
Week 3: Scan → Track improvement trends
All historical data preserved per repository
```

---

## 🔧 Technical Details

### Dashboard UID Generation
```python
# Consistent UID per repository name
import hashlib

repo_name = "tensorflow-models"
hash_object = hashlib.md5(repo_name.encode())
uid = f"{hash[:8]}-{hash[8:12]}-{hash[12:16]}-{hash[16:20]}-{hash[20:32]}"

# Result: e03ed124-7224-1aeb-f53e-31d9ccf48a46
# Always the same for "tensorflow-models"
```

### Metrics Collection
```python
# Real-time from pipeline
metrics = {
    "security": {
        "critical": 0,      # From Trivy scan
        "high": 0,
        "medium": 0,
        "low": 0
    },
    "quality": {
        "todo_comments": 0,  # From code analysis
        "debug_statements": 0,
        "large_files": 4
    },
    "tests": {
        "passed": 23,        # From test run
        "failed": 0,
        "coverage": 85.2
    }
}
```

### Grafana API
```bash
# Create/Update Dashboard
POST http://213.109.162.134:30102/api/dashboards/db
Auth: admin:admin123
Body: {dashboard JSON}

# Response
{
  "uid": "e03ed124-7224-1aeb-f53e-31d9ccf48a46",
  "url": "/d/e03ed124-7224-1aeb-f53e-31d9ccf48a46/tensorflow-models"
}
```

### Jira API
```bash
# Create Issue
POST https://your-domain.atlassian.net/rest/api/2/issue
Auth: email:api-token
Body: {issue JSON with dashboard link}

# Response
{
  "key": "PROJ-123"
}
```

---

## ✅ Verified Features

| Feature | Status | Notes |
|---------|--------|-------|
| Dashboard Creation | ✅ Working | Tested with tensorflow-models |
| Unique UIDs | ✅ Working | Consistent per repository |
| Grafana Integration | ✅ Active | Connected to http://213.109.162.134:30102 |
| Jira Integration | ✅ Configured | Requires environment variables |
| Real-time Metrics | ✅ Working | Collects from pipeline files |
| Auto-Refresh | ✅ Working | 30-second refresh |

---

## 📚 Documentation

### Quick Reference
- **Quick Start**: `QUICK_START_DASHBOARDS.md`
- **Live Demo**: `DASHBOARD_DEMO.md`
- **Full Guide**: `REPOSITORY_DASHBOARD_GUIDE.md`
- **This Overview**: `SYSTEM_OVERVIEW.md`

### Scripts
- **Main Script**: `scripts/create_repo_dashboard_and_jira.py`
- **Wrapper**: `create-repo-dashboard.sh`
- **Config**: `repos-to-scan.yaml`

---

## 🎓 Next Steps

1. ✅ **Read Quick Start**: `QUICK_START_DASHBOARDS.md`
2. ✅ **Configure Your Repository**: Edit `repos-to-scan.yaml`
3. ✅ **Run Pipeline**: Scan your repository
4. ✅ **Create Dashboard**: `./create-repo-dashboard.sh`
5. ✅ **View Results**: Check Grafana and Jira

---

## 🤝 Support

### Working Example
```
Repository: tensorflow-models
Dashboard: http://213.109.162.134:30102/d/e03ed124-7224-1aeb-f53e-31d9ccf48a46/pipeline-dashboard-tensorflow-models
Status: ✅ Verified and working
```

### Need Help?
1. Check `REPOSITORY_DASHBOARD_GUIDE.md` for troubleshooting
2. Review `DASHBOARD_DEMO.md` for examples
3. Verify Grafana connection: `curl http://213.109.162.134:30102/api/health`

---

## 🎉 Summary

**You now have:**
- ✅ Unique dashboard for each repository
- ✅ Automatic Jira integration
- ✅ Real-time metrics from pipeline
- ✅ Easy-to-use command: `./create-repo-dashboard.sh`
- ✅ Production-ready system

**Status: Ready to Use!** 🚀

