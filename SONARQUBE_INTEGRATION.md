# 🔍 SonarQube Integration Guide

## ✅ SonarQube is Now Running!

Your SonarQube instance is up and running on your VPS.

### 🔗 Access Information

- **URL:** http://213.109.162.134:30100
- **Username:** admin
- **Password:** 1234
- **Token:** `sqa_0e2b69f31a838ecd2a4576b94f5928eecfab37c5`

---

## 🚀 Quick Setup (Automated)

Run the automated setup script:

```bash
./setup-github-secrets.sh
```

This will configure all necessary GitHub secrets for your pipeline.

---

## 🔧 Manual Setup

If you prefer to set up secrets manually, add these to your GitHub repository:

### Go to: `Settings` → `Secrets and variables` → `Actions` → `New repository secret`

| Secret Name | Value |
|-------------|-------|
| `SONARQUBE_URL` | `http://213.109.162.134:30100` |
| `SONARQUBE_TOKEN` | `sqa_51ef0e4f497977eb546e6e8470d8901f5cdec161` |
| `SONARQUBE_ORG` | `default-organization` |

---

## 📝 Using GitHub CLI

```bash
# Login to GitHub CLI (if not already logged in)
gh auth login

# Set secrets for your repository (replace owner/repo with your actual repo)
gh secret set SONARQUBE_URL --repo owner/repo --body "http://213.109.162.134:30100"
gh secret set SONARQUBE_TOKEN --repo owner/repo --body "sqa_0e2b69f31a838ecd2a4576b94f5928eecfab37c5"
gh secret set SONARQUBE_ORG --repo owner/repo --body "default-organization"

# Verify secrets were set
gh secret list --repo owner/repo
```

---

## 🧪 Test Your Integration

### 1. Trigger the Pipeline

Edit `repos-to-scan.yaml` and push to GitHub:

```bash
git add repos-to-scan.yaml
git commit -m "Trigger pipeline scan"
git push
```

### 2. Monitor the Pipeline

```bash
# View running workflows
gh run list

# Watch the latest run
gh run watch
```

### 3. Check SonarQube Results

After the pipeline completes:
1. Go to http://213.109.162.134:30100
2. Login with `admin` / `1234`
3. Navigate to **Projects**
4. Find your scanned project (e.g., `qaicb`)
5. View the code quality and security analysis

---

## 📊 What the Pipeline Does

When you push changes to `repos-to-scan.yaml`, the pipeline will:

1. **Clone** the specified repository
2. **Scan** the code with SonarQube
3. **Analyze** security vulnerabilities with Trivy
4. **Create** a Grafana dashboard with results
5. **Generate** a Jira ticket (if configured)
6. **Store** metrics in Prometheus

---

## 🔍 SonarQube Project Configuration

The pipeline automatically creates a SonarQube project with these settings:

- **Project Key:** Repository name (e.g., `qaicb`)
- **Quality Gate:** Default (can be customized in SonarQube)
- **Analysis Scope:** All source files
- **Coverage Reports:** Included if available

---

## 🛠️ Advanced Configuration

### Custom SonarQube Properties

To customize analysis, create a `sonar-project.properties` file in the scanned repository:

```properties
sonar.projectKey=my-project
sonar.projectName=My Project
sonar.sources=src
sonar.tests=tests
sonar.exclusions=**/node_modules/**,**/dist/**,**/*.spec.ts
sonar.coverage.exclusions=**/*.test.js,**/*.spec.ts
```

### Quality Gates

Configure quality gates in SonarQube:
1. Go to **Quality Gates** in SonarQube
2. Create a new gate or modify the default
3. Set thresholds for:
   - Code Coverage
   - Duplications
   - Security Vulnerabilities
   - Code Smells

---

## 🐛 Troubleshooting

### SonarQube Not Accessible

```bash
# Check if SonarQube pod is running
sshpass -p 'qwert1234' ssh ubuntu@213.109.162.134 'kubectl get pods -n sonarqube'

# Check SonarQube logs
sshpass -p 'qwert1234' ssh ubuntu@213.109.162.134 'kubectl logs -n sonarqube -l app.kubernetes.io/name=sonarqube'
```

### Pipeline Fails at SonarQube Step

1. **Check secrets are set:**
   ```bash
   gh secret list --repo owner/repo
   ```

2. **Verify SonarQube is reachable:**
   ```bash
   curl http://213.109.162.134:30100/api/system/status
   ```

3. **Check SonarQube token is valid:**
   ```bash
   curl -u sqa_0e2b69f31a838ecd2a4576b94f5928eecfab37c5: \
     http://213.109.162.134:30100/api/authentication/validate
   ```

### Project Not Showing in SonarQube

- Wait 1-2 minutes after pipeline completes
- Refresh the SonarQube UI
- Check GitHub Actions logs for errors
- Verify the project key matches the repository name

---

## 📚 Additional Resources

- **SonarQube Documentation:** https://docs.sonarqube.org/
- **GitHub Secrets Guide:** `docs/GITHUB_SECRETS_VALUES.md`
- **Complete Pipeline Guide:** `docs/COMPLETE_PIPELINE_GUIDE.md`

---

## ✅ Verification Checklist

- [ ] SonarQube is accessible at http://213.109.162.134:30100
- [ ] Can login with admin/1234
- [ ] GitHub secrets are configured
- [ ] Pipeline runs successfully
- [ ] SonarQube analysis appears in dashboard
- [ ] Metrics are visible in Grafana
- [ ] Jira issues are created (if configured)

---

**🎉 Your SonarQube integration is ready!**

Push changes to `repos-to-scan.yaml` to trigger your first scan.

