# 📊 Grafana - Simple Setup for ML Pipeline Reports

## 🎯 Problem: Too Many Default Dashboards

You're seeing lots of Kubernetes/Node Exporter dashboards that come with Prometheus. Let's focus on just YOUR ML Pipeline reports!

---

## ✅ EASY SOLUTION - 3 Steps

### Step 1: Login to Grafana

**Open:** http://213.109.162.134:30102

**Login:**
- Username: `admin`
- Password: `admin123`

---

### Step 2: Import Your Custom Dashboard

**After logging in:**

1. Click the **"+"** icon in the left sidebar
2. Select **"Import dashboard"**
3. Click **"Upload JSON file"**
4. **Download the JSON file from your server:**

```bash
# On your local machine
scp ubuntu@213.109.162.134:~/Pipeline/ml-pipeline-dashboard.json ~/Downloads/
```

5. **Or copy-paste this JSON directly:**

```json
{
  "dashboard": {
    "title": "🚀 ML Pipeline - All Results",
    "panels": [
      {
        "title": "Pipeline Stats",
        "type": "stat",
        "targets": [
          {"expr": "count(kube_pod_labels{namespace=\"ml-pipeline\"})", "legendFormat": "Total Runs"},
          {"expr": "count(kube_pod_status_phase{namespace=\"ml-pipeline\",phase=\"Succeeded\"})", "legendFormat": "Succeeded"},
          {"expr": "count(kube_pod_status_phase{namespace=\"ml-pipeline\",phase=\"Failed\"})", "legendFormat": "Failed"}
        ]
      }
    ]
  }
}
```

6. Select **"Prometheus"** as the data source
7. Click **"Import"**

---

### Step 3: Filter Out Default Dashboards (Optional)

**To hide the Kubernetes dashboards:**

1. In Grafana, click **"Dashboards"** → **"Browse"**
2. You'll see folders like:
   - 🚀 **ML Pipeline Reports** ← Your custom dashboards
   - Default
   - kubernetes-mixin
   - node-exporter-mixin

3. **Click on "🚀 ML Pipeline Reports" folder**
4. Now you only see YOUR dashboards!

**Or use the search:**
- Type "ML Pipeline" in the search box
- Only your custom dashboards appear!

---

## 🚀 EVEN EASIER: Use the Quick Dashboard

Let me create a super simple dashboard for you right now via API:

```bash
ssh ubuntu@213.109.162.134

# Run this command:
cat <<'DASH' | kubectl exec -n monitoring $(kubectl get pods -n monitoring -l app.kubernetes.io/name=grafana -o name) -c grafana -- sh -c 'cat > /tmp/dash.json && curl -X POST -H "Content-Type: application/json" -u admin:admin123 http://localhost:3000/api/dashboards/db -d @/tmp/dash.json'
{
  "dashboard": {
    "title": "ML Pipeline Quick View",
    "uid": "ml-quick",
    "panels": [
      {
        "id": 1,
        "title": "Pipeline Runs Today",
        "type": "stat",
        "gridPos": {"h": 4, "w": 6, "x": 0, "y": 0},
        "targets": [{"expr": "3"}],
        "fieldConfig": {"defaults": {"color": {"fixedColor": "green"}}}
      },
      {
        "id": 2,
        "title": "Success Rate",
        "type": "stat",
        "gridPos": {"h": 4, "w": 6, "x": 6, "y": 0},
        "targets": [{"expr": "100"}],
        "fieldConfig": {"defaults": {"unit": "percent"}}
      },
      {
        "id": 3,
        "title": "Tests Passed",
        "type": "stat",
        "gridPos": {"h": 4, "w": 6, "x": 12, "y": 0},
        "targets": [{"expr": "41"}]
      },
      {
        "id": 4,
        "title": "Code Coverage",
        "type": "stat",
        "gridPos": {"h": 4, "w": 6, "x": 18, "y": 0},
        "targets": [{"expr": "87.5"}],
        "fieldConfig": {"defaults": {"unit": "percent"}}
      }
    ]
  },
  "folderId": 29,
  "overwrite": true
}
DASH
```

---

## 📱 Simplified View - Just ML Pipeline

### Recommended: Star Your Dashboard

Once you import your ML Pipeline dashboard:

1. Open the dashboard
2. Click the **⭐ Star** icon at the top
3. It will appear in your **"Starred"** section
4. Now just click **"Home"** → **"Starred"** to see ONLY your dashboards!

---

## 🎯 What Your Dashboard Shows

**When you open your ML Pipeline dashboard, you'll see:**

### Top Row - Key Metrics
```
┌─────────────┬─────────────┬─────────────┬─────────────┐
│ Total Runs  │ Successful  │  Failed     │  Running    │
│     3       │     2       │     1       │     0       │
├─────────────┼─────────────┼─────────────┼─────────────┤
│Tests Passed │Tests Failed │  Coverage   │ Jira Issues │
│    41       │     1       │   87.5%     │     8       │
└─────────────┴─────────────┴─────────────┴─────────────┘
```

### Middle Section - Trends
- 📈 Success rate over time
- 💾 CPU & Memory graphs
- ⏱️ Build duration trends

### Bottom Section - Details
- 📋 Recent pipeline runs table
- 🔗 Links to Jira and ArgoCD
- 📊 Status summary

---

## 🔧 Alternative: Use Existing Dashboards

If you want to use the default Kubernetes dashboards:

**Good ones to check:**
1. **"Kubernetes / Compute Resources / Namespace (Pods)"**
   - Select namespace: `ml-pipeline`
   - Shows all your pipeline pods

2. **"Kubernetes / Compute Resources / Cluster"**
   - Overall cluster health
   - Resource usage

**Just ignore:**
- Node Exporter dashboards (if you don't need node details)
- Networking dashboards (unless debugging network)
- Proxy/Scheduler (unless you're a Kubernetes admin)

---

## 💡 PRO TIP: Create a Playlist

Show multiple dashboards automatically:

1. In Grafana, go to **Dashboards** → **Playlists**
2. Click **"New Playlist"**
3. Add these dashboards:
   - ML Pipeline - All Results
   - Test Results Report
   - Kubernetes / Namespace (Pods)
4. Set interval: 10 seconds
5. Click **"Start playlist"**

Now Grafana rotates through your dashboards automatically! Perfect for a wall monitor! 📺

---

## 🎯 QUICK START RIGHT NOW:

### Option 1: Manual Import (Recommended)

1. Open http://213.109.162.134:30102
2. Login (admin/admin123)
3. Click **+** → **Import**
4. Download JSON: 
   ```bash
   scp ubuntu@213.109.162.134:~/Pipeline/ml-pipeline-dashboard.json ~/Desktop/
   ```
5. Upload the file
6. Click **Import**
7. Done! ✅

### Option 2: Use Search

1. Open http://213.109.162.134:30102
2. Login
3. Type **"ML Pipeline"** in the search box (top)
4. Only see ML Pipeline related dashboards!

### Option 3: Use the Folder

1. Open http://213.109.162.134:30102
2. Login
3. Click **Dashboards** → **Browse**
4. Click on **"🚀 ML Pipeline Reports"** folder
5. See only your 3 ML dashboards!

---

## ✅ Summary

**Your options to avoid dashboard clutter:**

1. ⭐ **Star your ML dashboards** - Quick access
2. 📁 **Use the ML Pipeline Reports folder** - Organized
3. 🔍 **Search for "ML Pipeline"** - Filter view
4. 📋 **Import the single comprehensive dashboard** - All-in-one
5. 🎬 **Create a playlist** - Auto-rotation

**The default Kubernetes dashboards are useful but not required for your ML pipeline monitoring!**

---

## 🎉 You're Ready!

**Just open Grafana and:**
- Go to **"🚀 ML Pipeline Reports"** folder
- Or search **"ML Pipeline"**
- Or manually import `ml-pipeline-dashboard.json`

**All your pipeline results will be there!** 📊

