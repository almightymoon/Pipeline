# 🚀 Manual Dashboard Import Guide

## ✅ **Credentials Found!**
- **URL:** http://213.109.162.134:30102
- **Username:** admin
- **Password:** prom-operator

## 📋 **Step-by-Step Import Process**

### **Step 1: Access Grafana**
1. Open browser and go to: http://213.109.162.134:30102
2. Login with:
   - Username: `admin`
   - Password: `prom-operator`

### **Step 2: Delete All Existing Dashboards**
1. Click **"Dashboards"** in the left sidebar
2. For each dashboard you see:
   - Click on the dashboard name
   - Click the **gear icon** (⚙️) in the top right corner
   - Click **"Dashboard settings"**
   - Scroll down and click **"Delete Dashboard"**
   - Confirm deletion

### **Step 3: Import the Ultimate Dashboard**
1. Click the **"+"** button in the left sidebar
2. Click **"Import"**
3. Click **"Upload JSON file"**
4. Select the file: `monitoring/ultimate-pipeline-dashboard.json`
5. Click **"Load"**
6. In the data source dropdown, select **"Prometheus"**
7. Click **"Import"**

### **Step 4: Configure Data Sources (if needed)**
1. Go to **"Configuration"** → **"Data Sources"**
2. If Prometheus is not listed, click **"Add data source"**
3. Select **"Prometheus"**
4. Configure:
   - **Name:** Prometheus
   - **URL:** http://prometheus.monitoring.svc.cluster.local:9090
   - **Access:** Proxy
   - **Default:** Yes
5. Click **"Save & Test"**

## 🎯 **Dashboard Access**
After import, your dashboard will be available at:
```
http://213.109.162.134:30102/d/ultimate-pipeline/ultimate-pipeline-intelligence
```

## 🚀 **Dashboard Features**
Your new dashboard includes:
- ✅ **Executive Summary** - Key metrics at a glance
- ✅ **Pipeline Performance Trends** - Real-time status
- ✅ **Code Quality Intelligence** - Quality scores and trends
- ✅ **Security Analysis Center** - Vulnerability tracking
- ✅ **Code Quality Breakdown** - Interactive pie charts
- ✅ **Repository Health Score** - Gauge showing health
- ✅ **Test Results Analytics** - Pass/fail and coverage
- ✅ **Detailed Quality Analysis** - Comprehensive tables
- ✅ **Repository Scan Summary** - All repos overview
- ✅ **Real-time Pipeline Logs** - Live log streaming
- ✅ **Interactive Filters** - Repository and search filters
- ✅ **Smart Annotations** - Automated alerts

## 🎯 **Populate with Real Data**
After importing, run a scan to populate with real data:
```bash
git add repos-to-scan.yaml && git commit -m "Test ultimate dashboard with real data" && git push
```

This will trigger the external repository scan and populate your dashboard with:
- Real security scan results from tensorflow/models
- Actual code quality metrics (407 TODO, 770 debug, 15 large files)
- Live pipeline performance data
- Interactive charts and visualizations

## 🎉 **Result**
You'll have a **professional enterprise-grade pipeline intelligence dashboard** that's MUCH better than the basic one you had before!
