# 🚀 Quick Start - SonarQube Integration

## ⚡ 3-Step Setup

### Step 1: Set GitHub Secrets

Choose **ONE** method:

#### Method A: Automated (Recommended) ⭐
```bash
./setup-github-secrets.sh
```

#### Method B: Using GitHub CLI
```bash
gh auth login

# Replace 'almightymoon/Pipeline' with your actual repo
REPO="almightymoon/Pipeline"

gh secret set SONARQUBE_URL --repo "$REPO" --body "http://213.109.162.134:30100"
gh secret set SONARQUBE_TOKEN --repo "$REPO" --body "sqa_0e2b69f31a838ecd2a4576b94f5928eecfab37c5"
gh secret set GRAFANA_URL --repo "$REPO" --body "http://213.109.162.134:30102"
gh secret set GRAFANA_USERNAME --repo "$REPO" --body "admin"
gh secret set GRAFANA_PASSWORD --repo "$REPO" --body "admin123"
gh secret set PROMETHEUS_PUSHGATEWAY_URL --repo "$REPO" --body "http://213.109.162.134:9091"
```

#### Method C: GitHub Web UI
1. Go to your repository on GitHub
2. Click **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Add each secret from the table below:

| Secret Name | Value |
|-------------|-------|
| `SONARQUBE_URL` | `http://213.109.162.134:30100` |
| `SONARQUBE_TOKEN` | `sqa_0e2b69f31a838ecd2a4576b94f5928eecfab37c5` |
| `GRAFANA_URL` | `http://213.109.162.134:30102` |
| `GRAFANA_USERNAME` | `admin` |
| `GRAFANA_PASSWORD` | `admin123` |
| `PROMETHEUS_PUSHGATEWAY_URL` | `http://213.109.162.134:9091` |

---

### Step 2: Verify Secrets

```bash
gh secret list --repo almightymoon/Pipeline
```

You should see:
- ✅ SONARQUBE_URL
- ✅ SONARQUBE_TOKEN
- ✅ GRAFANA_URL
- ✅ GRAFANA_USERNAME
- ✅ GRAFANA_PASSWORD
- ✅ PROMETHEUS_PUSHGATEWAY_URL

---

### Step 3: Trigger Pipeline

The pipeline triggers automatically when you modify `repos-to-scan.yaml`:

```bash
# Make a change (or just trigger workflow manually)
git add .
git commit -m "Test SonarQube integration"
git push
```

Or trigger manually:
```bash
gh workflow run "scan-external-repos.yml"
```

---

## 📊 View Results

After pipeline completes (~3-5 minutes):

### SonarQube Dashboard
- **URL:** http://213.109.162.134:30100
- **Login:** admin / 1234
- **Project:** qaicb (or your repo name)

### Grafana Dashboard
- **URL:** http://213.109.162.134:30102
- **Login:** admin / admin123
- **Dashboard:** Pipeline Dashboard - qaicb

### Prometheus Metrics
- **URL:** http://213.109.162.134:30090
- **Query Example:** `pipeline_scan_duration_seconds{repository="qaicb"}`

---

## 🔧 Current Configuration

Your `repos-to-scan.yaml`:
```yaml
repositories:
  - url: https://github.com/hamadkmehsud/qaicb
    name: qaicb
    branch: main
    scan_type: full
```

---

## ✅ Success Indicators

Pipeline is working when you see:
- ✅ GitHub Actions workflow completes successfully
- ✅ SonarQube project appears at http://213.109.162.134:30100
- ✅ Grafana dashboard shows metrics
- ✅ No errors in workflow logs

---

## 🐛 Quick Troubleshooting

### "SonarQube not accessible"
```bash
# Check SonarQube is running
curl http://213.109.162.134:30100/api/system/status
```

### "Secrets not found"
```bash
# Verify secrets are set
gh secret list --repo almightymoon/Pipeline
```

### "Workflow not triggering"
```bash
# Manually trigger
gh workflow run "scan-external-repos.yml"

# Check workflow status
gh run list
```

---

## 📞 Need Help?

1. **Check logs:**
   ```bash
   gh run view --log
   ```

2. **Verify services:**
   ```bash
   curl http://213.109.162.134:30100/api/system/status  # SonarQube
   curl http://213.109.162.134:30102/api/health        # Grafana
   curl http://213.109.162.134:30090/-/healthy         # Prometheus
   ```

3. **Review documentation:**
   - `SONARQUBE_INTEGRATION.md` - Detailed SonarQube guide
   - `docs/GITHUB_SECRETS_VALUES.md` - All secret values
   - `docs/COMPLETE_PIPELINE_GUIDE.md` - Full pipeline documentation

---

## 🎯 Your Services

| Service | URL | Credentials |
|---------|-----|-------------|
| **SonarQube** | http://213.109.162.134:30100 | admin / 1234 |
| **Grafana** | http://213.109.162.134:30102 | admin / admin123 |
| **Prometheus** | http://213.109.162.134:30090 | No auth |

---

**🚀 You're all set! Push to trigger your first scan.**

