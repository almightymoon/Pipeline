# 🎯 Dynamic Dashboard Guide

## ✅ **Problem Solved!**

You now have **ONE dynamic dashboard** that automatically updates based on whatever repository you're scanning in `repos-to-scan.yaml`. No more creating new dashboards every time!

---

## 🔗 **Dashboard URL:**
**http://213.109.162.134:30102/d/ae4e244b-b4b3-42af-8bb4-1cfcf29f7112/pipeline-dashboard-current-repository**

---

## 🚀 **How It Works:**

### **✅ Automatic Updates:**
- Dashboard reads from `repos-to-scan.yaml`
- Shows current repository name, URL, branch, scan type
- Displays scan time and repository-specific data
- Updates automatically when you change the repository

### **✅ Repository Information:**
- **Repository Name:** forex-project
- **Repository URL:** https://github.com/almightymoon/forex
- **Branch:** main
- **Scan Type:** full
- **Scan Time:** 2025-10-14 10:54:48 UTC

---

## 📋 **How to Change Repository:**

### **Method 1: Quick Change**
```bash
# 1. Edit repos-to-scan.yaml with new repository
# 2. Run this command:
./change-repo-and-update-dashboard.sh
```

### **Method 2: Manual Steps**
```bash
# 1. Edit repos-to-scan.yaml
nano repos-to-scan.yaml

# 2. Update dashboard
./update-dashboard-content.sh

# 3. Commit changes
git add . && git commit -m "Change repository to new-repo" && git push
```

---

## 🎯 **What Updates Automatically:**

### **✅ Repository Details:**
- Repository name and URL
- Branch and scan type
- Scan time and duration
- Pipeline run ID and number

### **✅ Repository-Specific Data:**
- Security vulnerabilities (specific to the repository)
- TODO/FIXME comments (from the actual repository)
- Failed tests (with actual error messages)
- Code quality metrics
- Pipeline execution logs

### **✅ Dashboard Sections:**
1. **Pipeline Status** - Total runs, successful, failed
2. **Test Results** - Tests passed, failed, coverage
3. **Repository Information** - Current repository details
4. **Security Vulnerabilities** - Repository-specific CVEs
5. **TODO/FIXME Comments** - Repository-specific TODOs
6. **Failed Test Details** - Repository-specific test failures
7. **Code Quality Metrics** - Repository-specific quality issues
8. **Pipeline Execution Logs** - Complete execution logs

---

## 🔄 **Example: Change from forex-project to another repository**

### **Step 1: Edit repos-to-scan.yaml**
```yaml
repositories:
  - url: https://github.com/username/new-repository
    name: new-repository
    branch: main
    scan_type: full
```

### **Step 2: Update Dashboard**
```bash
./change-repo-and-update-dashboard.sh
```

### **Step 3: Dashboard Updates**
- Repository name changes to "new-repository"
- URL changes to the new repository
- All data updates to be specific to the new repository
- Scan time updates to current timestamp

---

## 📊 **Current Dashboard Shows:**

### **✅ Repository: forex-project**
- **URL:** https://github.com/almightymoon/forex
- **Branch:** main
- **Scan Type:** full
- **Scan Time:** 2025-10-14 10:54:48 UTC

### **✅ Data Specific to forex-project:**
- 3 security vulnerabilities (react, chart.js, moment)
- 28 TODO comments (trading-specific items)
- 2 failed tests (WebSocket, calculations)
- 39 total code quality issues
- Complete pipeline execution logs

---

## 🎉 **Benefits:**

### **✅ No More Manual Dashboard Creation:**
- One dashboard for all repositories
- Automatic updates when you change repos
- No need to create new dashboards

### **✅ Always Current Data:**
- Shows the repository currently being scanned
- Updates scan time automatically
- Displays repository-specific metrics

### **✅ Easy Repository Switching:**
- Just edit `repos-to-scan.yaml`
- Run one command to update dashboard
- Everything updates automatically

---

## 🚀 **Ready to Use:**

Your dynamic dashboard is ready! Just change the repository in `repos-to-scan.yaml` and run `./change-repo-and-update-dashboard.sh` to update everything automatically.

**No more creating new dashboards - one dashboard updates for all repositories!** 🎉
