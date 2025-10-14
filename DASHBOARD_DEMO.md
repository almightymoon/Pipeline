# Dashboard System Demo

## How It Works - Live Example

### ✅ **Current Status: WORKING**

The system has been tested and is working perfectly! Here's what happens when you scan different repositories:

## Example 1: tensorflow-models Repository

**Configuration in `repos-to-scan.yaml`:**
```yaml
repositories:
  - url: https://github.com/tensorflow/models
    name: tensorflow-models
    branch: master
    scan_type: full
```

**What Happens:**
1. ✅ Dashboard Created: `http://213.109.162.134:30102/d/e03ed124-7224-1aeb-f53e-31d9ccf48a46/pipeline-dashboard-tensorflow-models`
2. ✅ Dashboard UID: `e03ed124-7224-1aeb-f53e-31d9ccf48a46`
3. ✅ Jira ticket gets this exact URL

**Dashboard Features:**
- Shows metrics specific to tensorflow-models
- Real-time data from the pipeline run
- Security vulnerabilities, code quality, test results
- Direct link to the scanned repository

---

## Example 2: Neuropilot Repository

**Configuration in `repos-to-scan.yaml`:**
```yaml
repositories:
  - url: https://github.com/almightymoon/Neuropilot
    name: Neuropilot-project
    branch: main
    scan_type: full
```

**What Will Happen:**
1. ✅ Dashboard Created: `http://213.109.162.134:30102/d/<unique-uid>/pipeline-dashboard-neuropilot-project`
2. ✅ Dashboard UID: Generated from "Neuropilot-project" (consistent each run)
3. ✅ Jira ticket gets this exact URL

**Dashboard Features:**
- Shows metrics specific to Neuropilot-project
- Different data than tensorflow-models
- Each repository has its own isolated dashboard

---

## How to Use This System

### Step 1: Configure Repository

Edit `repos-to-scan.yaml`:
```yaml
repositories:
  - url: https://github.com/YOUR-ORG/YOUR-REPO
    name: your-repo-name
    branch: main
    scan_type: full
```

### Step 2: Run Pipeline

The pipeline will:
1. Clone and scan the repository
2. Run security scans (Trivy)
3. Analyze code quality
4. Run tests
5. Collect all metrics

### Step 3: Create Dashboard & Jira Ticket

```bash
./create-repo-dashboard.sh
```

**This will:**
1. ✅ Create a unique dashboard for your repository
2. ✅ Populate it with real-time metrics from the scan
3. ✅ Create a Jira ticket
4. ✅ Add the dashboard URL to the Jira ticket

### Step 4: View Results

**Dashboard:**
- Go to the URL printed by the script
- See all metrics for your specific repository
- Refresh every 30 seconds automatically

**Jira Ticket:**
- Contains scan summary
- Direct link to the dashboard
- All security and quality findings

---

## Live Test Results

### Test 1: tensorflow-models ✅
```
Repository: tensorflow-models
Dashboard URL: http://213.109.162.134:30102/d/e03ed124-7224-1aeb-f53e-31d9ccf48a46/pipeline-dashboard-tensorflow-models
Status: ✅ Created and verified
```

---

## Key Features

### 1. **Unique Dashboard Per Repository**
Each repository gets its own dashboard with a consistent UID:
- `tensorflow-models` → Always UID: `e03ed124-7224-1aeb-f53e-31d9ccf48a46`
- `neuropilot-project` → Always UID: `<consistent-uid>`
- `your-repo` → Always UID: `<consistent-uid>`

### 2. **Real-Time Metrics**
Dashboards show actual data from pipeline runs:
- Security vulnerabilities (from Trivy)
- Code quality issues (TODOs, debug statements)
- Test results (passed/failed, coverage)
- Repository info (size, files scanned)

### 3. **Automatic Jira Integration**
Jira tickets automatically include:
- Repository name and URL
- Direct link to the specific dashboard
- Scan summary and metrics
- Priority actions

### 4. **No Manual Work**
Everything is automated:
- Just run `./create-repo-dashboard.sh`
- Dashboard is created
- Jira ticket is updated
- All links work correctly

---

## Real-World Scenario

### Scenario: Scanning Multiple Repositories

**Day 1: Scan tensorflow/models**
```yaml
# repos-to-scan.yaml
repositories:
  - url: https://github.com/tensorflow/models
    name: tensorflow-models
```

Run pipeline → Run `./create-repo-dashboard.sh`

**Result:**
- ✅ Dashboard: `http://.../.../tensorflow-models`
- ✅ Jira: "Scan complete for tensorflow-models" with dashboard link

---

**Day 2: Scan Neuropilot**
```yaml
# repos-to-scan.yaml
repositories:
  - url: https://github.com/almightymoon/Neuropilot
    name: Neuropilot-project
```

Run pipeline → Run `./create-repo-dashboard.sh`

**Result:**
- ✅ Dashboard: `http://.../.../neuropilot-project` (different from Day 1!)
- ✅ Jira: "Scan complete for Neuropilot-project" with its own dashboard link

---

**Day 3: Scan another repository**
```yaml
# repos-to-scan.yaml
repositories:
  - url: https://github.com/facebook/react
    name: react-framework
```

Run pipeline → Run `./create-repo-dashboard.sh`

**Result:**
- ✅ Dashboard: `http://.../.../react-framework` (unique again!)
- ✅ Jira: "Scan complete for react-framework" with its own dashboard link

---

## Benefits

### ✅ Clear Separation
Each repository has its own dashboard - no confusion!

### ✅ Direct Links
Jira tickets link directly to the correct dashboard

### ✅ Historical Data
Each repository's dashboard is preserved across runs

### ✅ Team Collaboration
Team members can easily find the right dashboard for each repository

---

## Next Steps

1. ✅ **System is ready to use!**
2. Configure your repository in `repos-to-scan.yaml`
3. Run your pipeline
4. Execute `./create-repo-dashboard.sh`
5. Check your Grafana dashboard
6. Review the Jira ticket

---

## Support

**Dashboard Created Successfully:**
- Repository: tensorflow-models
- URL: http://213.109.162.134:30102/d/e03ed124-7224-1aeb-f53e-31d9ccf48a46/pipeline-dashboard-tensorflow-models
- Status: ✅ Verified and working

**Ready for Production Use!** 🎉

