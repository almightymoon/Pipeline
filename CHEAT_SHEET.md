# 🎯 Pipeline Quick Reference - Cheat Sheet

## 🚀 Common Commands

### GitHub Secrets Setup
```bash
# Quick setup (all secrets at once)
./setup-github-secrets.sh

# Individual secrets via CLI
gh secret set SONARQUBE_URL --repo almightymoon/Pipeline --body "http://213.109.162.134:30100"
gh secret set SONARQUBE_TOKEN --repo almightymoon/Pipeline --body "sqa_51ef0e4f497977eb546e6e8470d8901f5cdec161"

# List all secrets
gh secret list --repo almightymoon/Pipeline
```

### Trigger Pipeline
```bash
# Automatic trigger (push changes)
git add repos-to-scan.yaml
git commit -m "Trigger scan"
git push

# Manual trigger
gh workflow run "scan-external-repos.yml"

# Watch running workflow
gh run watch

# View logs
gh run view --log
```

### Check Services Status
```bash
# SonarQube
curl http://213.109.162.134:30100/api/system/status

# Grafana
curl http://213.109.162.134:30102/api/health

# Prometheus
curl http://213.109.162.134:30090/-/healthy
```

### SSH to VPS
```bash
# Connect to server
ssh ubuntu@213.109.162.134
# Password: qwert1234

# Or with sshpass
sshpass -p 'qwert1234' ssh ubuntu@213.109.162.134
```

### Kubernetes Commands (on VPS)
```bash
# Check SonarQube pod
kubectl get pods -n sonarqube

# View SonarQube logs
kubectl logs -n sonarqube -l app.kubernetes.io/name=sonarqube

# Restart SonarQube
kubectl rollout restart deployment/sonarqube -n sonarqube

# Check all services
kubectl get pods -A

# Check Prometheus
kubectl get pods -n monitoring

# Check Grafana
kubectl get pods -n grafana
```

## 🔗 Quick Access URLs

```bash
# Open in browser (macOS)
open http://213.109.162.134:30100  # SonarQube
open http://213.109.162.134:30102  # Grafana
open http://213.109.162.134:30090  # Prometheus

# Linux
xdg-open http://213.109.162.134:30100
```

## 📊 Service Credentials

| Service | URL | Username | Password |
|---------|-----|----------|----------|
| SonarQube | :30100 | admin | 1234 |
| Grafana | :30102 | admin | admin123 |
| Prometheus | :30090 | - | - |

## 🔍 Troubleshooting Commands

### Pipeline Issues
```bash
# Check workflow status
gh run list --limit 5

# View specific run
gh run view RUN_ID

# Re-run failed workflow
gh run rerun RUN_ID
```

### SonarQube Issues
```bash
# Test connection
curl -u admin:1234 http://213.109.162.134:30100/api/authentication/validate

# List projects
curl -u admin:1234 http://213.109.162.134:30100/api/projects/search

# Get project details
curl -u admin:1234 "http://213.109.162.134:30100/api/components/show?component=qaicb"

# Check pod on VPS
sshpass -p 'qwert1234' ssh ubuntu@213.109.162.134 'kubectl get pods -n sonarqube'

# View logs on VPS
sshpass -p 'qwert1234' ssh ubuntu@213.109.162.134 'kubectl logs -n sonarqube -l app.kubernetes.io/name=sonarqube --tail=50'
```

### Grafana Issues
```bash
# Test connection
curl -u admin:admin123 http://213.109.162.134:30102/api/health

# List dashboards
curl -u admin:admin123 http://213.109.162.134:30102/api/search?type=dash-db

# Check pod on VPS
sshpass -p 'qwert1234' ssh ubuntu@213.109.162.134 'kubectl get pods -n grafana'
```

### Prometheus Issues
```bash
# Test connection
curl http://213.109.162.134:30090/-/healthy

# Query metrics
curl 'http://213.109.162.134:30090/api/v1/query?query=up'

# Check targets
curl http://213.109.162.134:30090/api/v1/targets

# Check pod on VPS
sshpass -p 'qwert1234' ssh ubuntu@213.109.162.134 'kubectl get pods -n monitoring'
```

## 🔄 Repository Configuration

### Edit repos-to-scan.yaml
```yaml
repositories:
  - url: https://github.com/hamadkmehsud/qaicb
    name: qaicb
    branch: main
    scan_type: full  # Options: full, security-only, quick
```

### Multiple Repositories
```yaml
repositories:
  - url: https://github.com/user/repo1
    name: repo1
    branch: main
    scan_type: full
    
  - url: https://github.com/user/repo2
    name: repo2
    branch: develop
    scan_type: security-only
```

## 📈 Viewing Results

### After Pipeline Completes
```bash
# 1. Check SonarQube
open http://213.109.162.134:30100/dashboard?id=qaicb

# 2. Check Grafana Dashboard
open http://213.109.162.134:30102/dashboards

# 3. Query Prometheus
open "http://213.109.162.134:30090/graph?g0.expr=pipeline_scan_duration_seconds{repository=\"qaicb\"}"
```

## 🛠️ Maintenance

### Update SonarQube
```bash
# On VPS
kubectl set image deployment/sonarqube sonarqube=sonarqube:10.4-community -n sonarqube
```

### Backup SonarQube Data
```bash
# On VPS
kubectl exec -n sonarqube -it deployment/sonarqube -- tar czf /tmp/sonarqube-backup.tar.gz /opt/sonarqube/data
kubectl cp sonarqube/sonarqube-xxx:/tmp/sonarqube-backup.tar.gz ./sonarqube-backup.tar.gz
```

### Clean Up Old Data
```bash
# Delete old pipeline runs from GitHub
gh run list --limit 100 --json databaseId -q '.[].databaseId' | xargs -I {} gh run delete {}
```

## 📝 Quick Edits

### Update SonarQube Token
```bash
gh secret set SONARQUBE_TOKEN --repo almightymoon/Pipeline --body "NEW_TOKEN_HERE"
```

### Update Grafana Password
```bash
gh secret set GRAFANA_PASSWORD --repo almightymoon/Pipeline --body "NEW_PASSWORD"
```

## 🎯 Most Used Commands

```bash
# 1. Trigger scan
git add repos-to-scan.yaml && git commit -m "scan" && git push

# 2. Watch progress
gh run watch

# 3. Check results
open http://213.109.162.134:30100

# 4. Check SonarQube status on VPS
sshpass -p 'qwert1234' ssh ubuntu@213.109.162.134 'kubectl get pods -n sonarqube'
```

---

## 📚 Documentation Files

- `QUICK_START.md` - 3-step setup guide
- `SONARQUBE_INTEGRATION.md` - Detailed SonarQube guide  
- `docs/GITHUB_SECRETS_VALUES.md` - All secret values
- `docs/COMPLETE_PIPELINE_GUIDE.md` - Full pipeline docs
- `README.md` - Project overview

---

**💡 Tip:** Bookmark this file for quick reference!

