# 📊 ML Pipeline - Complete Dashboard Access Guide

## 🎯 All Your Dashboards Are Running!

**Server:** 213.109.162.134  
**Status:** ✅ All systems operational

---

## 1️⃣ GRAFANA (Monitoring & Metrics)

### Access Information
```
🔗 URL: http://213.109.162.134:30102
👤 Username: admin
🔑 Password: admin123
```

### What You'll See

**After logging in, navigate to:**

1. **Dashboards → Browse** to see all available dashboards
   
2. **Pre-installed dashboards include:**
   - **Kubernetes / Compute Resources / Cluster** - Overall cluster health
   - **Kubernetes / Compute Resources / Namespace (Pods)** - Pod metrics
   - **Kubernetes / Compute Resources / Node (Pods)** - Node metrics
   - **Kubernetes / Networking / Cluster** - Network metrics
   - **Kubernetes / USE Method / Cluster** - Utilization, Saturation, Errors

3. **Key Metrics to Watch:**
   - CPU usage
   - Memory usage
   - Pod status
   - Network traffic
   - Storage utilization

### How to Create a Custom Dashboard for Your Pipeline

```
1. Click "+" → "Create Dashboard"
2. Click "Add visualization"
3. Select "Prometheus" as data source
4. Use these queries:

Pipeline Metrics:
- tekton_pipelinerun_duration_seconds
- tekton_pipelinerun_count
- tekton_taskrun_duration_seconds

Kubernetes Metrics:
- container_cpu_usage_seconds_total{namespace="ml-pipeline"}
- container_memory_usage_bytes{namespace="ml-pipeline"}
- kube_pod_status_phase{namespace="ml-pipeline"}
```

### Import Pre-Built Dashboards

```
1. Go to Dashboards → New → Import
2. Enter dashboard ID:
   - 315 - Kubernetes cluster monitoring
   - 7249 - Kubernetes cluster
   - 8588 - Tekton pipelines

3. Click "Load" and select "Prometheus" as data source
```

---

## 2️⃣ ARGOCD (GitOps & Deployments)

### Access Information
```
🔗 HTTP:  http://213.109.162.134:32146
🔗 HTTPS: https://213.109.162.134:30981
👤 Username: admin
🔑 Password: AcfOP4fSGVt-4AAg
```

### What You'll See

**Main Features:**

1. **Applications Tab**
   - View all deployed applications
   - Sync status
   - Health status
   - Last sync time

2. **Create an Application**
   ```
   Click "+ NEW APP"
   
   General:
   - Application Name: ml-pipeline-app
   - Project: default
   - Sync Policy: Automatic
   
   Source:
   - Repository URL: https://github.com/almightymoon/Pipeline.git
   - Revision: main
   - Path: k8s
   
   Destination:
   - Cluster: https://kubernetes.default.svc
   - Namespace: ml-pipeline
   
   Click "CREATE"
   ```

3. **Monitor Deployments**
   - Click on any application
   - View resource tree
   - See sync status
   - Check deployment history

### ArgoCD CLI Access

From your server:
```bash
argocd login 213.109.162.134:32146 --username admin --password AcfOP4fSGVt-4AAg --insecure

argocd app list
argocd app get ml-pipeline-app
argocd app sync ml-pipeline-app
```

---

## 3️⃣ JIRA (Issue Tracking)

### Access Information
```
🔗 URL: https://faniqueprimus.atlassian.net/jira/software/projects/KAN/boards/1
📧 Email: faniqueprimus@gmail.com
```

### What You'll See

**Automatic Issues Created:**
- **KAN-4** - Integration test issue
- **KAN-5** - Pipeline completion notification (from latest run)

**Future Issues Will Include:**
- Pipeline failures (Priority: High)
- Test failures (Priority: Medium)  
- Model performance issues (Priority: High)
- Dataset quality problems (Priority: Medium)

### Customize Issue Creation

Edit the Jira notify task:
```bash
kubectl edit task jira-notify -n ml-pipeline

# Modify the description template to include more details
# Add custom fields for your metrics
# Change priority levels
```

---

## 4️⃣ PROMETHEUS (Raw Metrics)

### Access Information
```
From your LOCAL machine, run:
ssh -L 9090:localhost:9090 ubuntu@213.109.162.134

Then open: http://localhost:9090
```

### What You'll See

**Query Examples:**

1. **Pod CPU Usage:**
   ```
   rate(container_cpu_usage_seconds_total{namespace="ml-pipeline"}[5m])
   ```

2. **Memory Usage:**
   ```
   container_memory_usage_bytes{namespace="ml-pipeline"}
   ```

3. **Pipeline Execution Count:**
   ```
   count(kube_pod_labels{namespace="ml-pipeline"})
   ```

4. **Network Traffic:**
   ```
   rate(container_network_receive_bytes_total{namespace="ml-pipeline"}[5m])
   ```

---

## 5️⃣ VAULT (Secrets Management)

### Access Information
```
From your LOCAL machine, run:
ssh -L 8200:localhost:8200 ubuntu@213.109.162.134

Then open: http://localhost:8200
🔑 Token: root
```

### Or Via CLI:
```bash
ssh ubuntu@213.109.162.134
kubectl exec -it vault-0 -n vault -- sh

# Inside Vault:
vault status
vault kv list secret/ml-pipeline
vault kv get secret/ml-pipeline/jira
```

### What You'll See

**Stored Secrets:**
- `secret/ml-pipeline/jira` - Jira credentials
- `secret/ml-pipeline/harbor` - Docker registry
- `secret/ml-pipeline/aws` - Cloud credentials (if added)

---

## 📈 Create a Pipeline Monitoring Dashboard

Let me create a custom Grafana dashboard for you:

### Dashboard JSON

Save this and import into Grafana:

```json
{
  "dashboard": {
    "title": "ML Pipeline Monitoring",
    "panels": [
      {
        "title": "Pipeline Runs",
        "targets": [{
          "expr": "count(kube_pod_labels{namespace=\"ml-pipeline\"})"
        }]
      },
      {
        "title": "Success Rate",
        "targets": [{
          "expr": "sum(kube_pod_status_phase{namespace=\"ml-pipeline\",phase=\"Succeeded\"}) / sum(kube_pod_status_phase{namespace=\"ml-pipeline\"})"
        }]
      },
      {
        "title": "CPU Usage",
        "targets": [{
          "expr": "sum(rate(container_cpu_usage_seconds_total{namespace=\"ml-pipeline\"}[5m]))"
        }]
      },
      {
        "title": "Memory Usage",
        "targets": [{
          "expr": "sum(container_memory_usage_bytes{namespace=\"ml-pipeline\"})"
        }]
      }
    ]
  }
}
```

**To import:**
1. Open Grafana: http://213.109.162.134:30102
2. Go to Dashboards → New → Import
3. Paste the JSON above
4. Click "Load"

---

## 🚀 Complete Monitoring Workflow

### When You Run a Pipeline:

**1. Start the pipeline:**
```bash
ssh ubuntu@213.109.162.134
cd ~/Pipeline
./run-pipeline.sh python https://github.com/almightymoon/Pipeline.git
```

**2. Monitor in real-time (Terminal):**
```bash
tkn pipelinerun logs <pipeline-name> -n ml-pipeline -f
```

**3. View in Grafana:**
- Open: http://213.109.162.134:30102
- Navigate to: Dashboards → Kubernetes → Pods
- Filter by namespace: `ml-pipeline`
- Watch CPU/Memory in real-time

**4. Check ArgoCD:**
- Open: http://213.109.162.134:32146
- View sync status
- Monitor deployment health

**5. Check Jira:**
- Open: https://faniqueprimus.atlassian.net/browse/KAN
- New issues appear on failures
- Completion notifications on success

**6. Query Prometheus (Advanced):**
```bash
# Port forward
ssh -L 9090:localhost:9090 ubuntu@213.109.162.134

# Open http://localhost:9090
# Run queries for detailed metrics
```

---

## 📊 Dashboard Overview Matrix

| Dashboard | URL | Purpose | When to Use |
|-----------|-----|---------|-------------|
| **Grafana** | http://213.109.162.134:30102 | Visualize metrics | Monitor performance, debug issues |
| **ArgoCD** | http://213.109.162.134:32146 | Manage deployments | Deploy apps, check sync status |
| **Jira** | https://faniqueprimus.atlassian.net | Track issues | Review failures, manage tickets |
| **Prometheus** | Port-forward 9090 | Raw metrics | Advanced queries, troubleshooting |
| **Vault** | Port-forward 8200 | Manage secrets | Add/update credentials |

---

## 🔧 Troubleshooting

### Grafana not loading?
```bash
# Restart Grafana
ssh ubuntu@213.109.162.134
kubectl rollout restart deployment prometheus-grafana -n monitoring

# Wait for it to be ready
kubectl rollout status deployment prometheus-grafana -n monitoring

# Check logs
kubectl logs -f deployment/prometheus-grafana -n monitoring
```

### ArgoCD connection issues?
```bash
# Check service
kubectl get svc argocd-server -n argocd

# Restart if needed
kubectl rollout restart deployment argocd-server -n argocd
```

### Can't access from browser?
```bash
# Make sure the NodePort service is exposed
kubectl get svc -n monitoring | grep grafana
kubectl get svc -n argocd | grep argocd-server

# Check firewall rules on server
sudo ufw status
sudo ufw allow 30102/tcp  # Grafana
sudo ufw allow 32146/tcp  # ArgoCD
```

---

## 🎉 You're All Set!

**Try accessing now:**

1. **Grafana:** http://213.109.162.134:30102 (admin/admin123)
2. **ArgoCD:** http://213.109.162.134:32146 (admin/AcfOP4fSGVt-4AAg)
3. **Jira:** https://faniqueprimus.atlassian.net/browse/KAN-5

All dashboards are integrated with your pipeline and will show real-time data when pipelines run! 🚀


