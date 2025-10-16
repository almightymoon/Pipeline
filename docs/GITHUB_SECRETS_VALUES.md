# 🔐 GitHub Secrets - Your Actual Values

## 📋 Ready-to-Use Secret Values

Based on your server setup, here are the exact values to use:

---

## 🚀 Quick Setup Commands

### **Option 1: Using GitHub CLI (Recommended)**

```bash
# Install GitHub CLI if not installed
brew install gh  # macOS
# or
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg  # Linux

# Login to GitHub
gh auth login

# Set all secrets with your actual values
gh secret set HARBOR_USERNAME --body "admin"
gh secret set HARBOR_PASSWORD --body "password"
gh secret set SONARQUBE_URL --body "http://213.109.162.134:30100"
gh secret set SONARQUBE_TOKEN --body "sqa_0e2b69f31a838ecd2a4576b94f5928eecfab37c5"
gh secret set SONARQUBE_ORG --body "default-organization"
gh secret set VAULT_URL --body "http://213.109.162.134:8200"
gh secret set VAULT_TOKEN --body "sample-vault-token"
gh secret set JIRA_URL --body "https://faniqueprimus.atlassian.net"
gh secret set JIRA_PROJECT_KEY --body "KAN"
gh secret set PROMETHEUS_PUSHGATEWAY_URL --body "http://213.109.162.134:30091"

# Get Kubernetes config from your server
KUBECONFIG_BASE64=$(sshpass -p 'qwert1234' ssh -o StrictHostKeyChecking=no ubuntu@213.109.162.134 'kubectl config view --raw --minify | base64 -w 0')
gh secret set KUBECONFIG --body "$KUBECONFIG_BASE64"

# Optional: Slack webhook (set if you have one)
# gh secret set SLACK_WEBHOOK_URL --body "YOUR_SLACK_WEBHOOK_URL"
```

### **Option 2: Using GitHub Web UI**

Go to your repository → **Settings** → **Secrets and variables** → **Actions** and add these:

| Secret Name | Value |
|-------------|-------|
| `HARBOR_USERNAME` | `admin` |
| `HARBOR_PASSWORD` | `password` |
| `SONARQUBE_URL` | `http://213.109.162.134:30100` |
| `SONARQUBE_TOKEN` | `sqa_0e2b69f31a838ecd2a4576b94f5928eecfab37c5` |
| `SONARQUBE_ORG` | `default-organization` |
| `KUBECONFIG` | *(see KUBECONFIG section below)* |
| `VAULT_URL` | `http://213.109.162.134:8200` |
| `VAULT_TOKEN` | `sample-vault-token` |
| `JIRA_URL` | `https://faniqueprimus.atlassian.net` |
| `JIRA_PROJECT_KEY` | `KAN` |
| `PROMETHEUS_PUSHGATEWAY_URL` | `http://213.109.162.134:30091` |
| `SLACK_WEBHOOK_URL` | *(optional)* |

---

## 🔑 Getting KUBECONFIG Value

Run this command to get your Kubernetes config:

```bash
# Get the base64 encoded kubeconfig
sshpass -p 'qwert1234' ssh -o StrictHostKeyChecking=no ubuntu@213.109.162.134 'kubectl config view --raw --minify | base64 -w 0'
```

Copy the output and use it as the `KUBECONFIG` secret value.

---

## 📊 Your Server Details

### **🔗 Service URLs:**
- **Server IP:** `213.109.162.134`
- **Grafana:** http://213.109.162.134:30102 (admin/admin123)
- **ArgoCD:** http://213.109.162.134:32146 (admin/AcfOP4fSGVt-4AAg)
- **Jira:** https://faniqueprimus.atlassian.net/browse/KAN
- **Harbor:** http://213.109.162.134 (admin/password)
- **SonarQube:** http://213.109.162.134:30100 (admin/1234)
- **Vault:** http://213.109.162.134:8200

### **🔐 Default Credentials:**
- **Harbor:** admin / password
- **SonarQube:** admin / 1234
- **SonarQube Token:** sqa_0e2b69f31a838ecd2a4576b94f5928eecfab37c5
- **Grafana:** admin / admin123
- **ArgoCD:** admin / AcfOP4fSGVt-4AAg
- **Vault:** sample-vault-token

---

## 🚀 Automated Setup Script

I've created a script that will set up all secrets automatically:

```bash
# Run the automated setup script
./setup-github-secrets.sh
```

This script will:
1. ✅ Check if GitHub CLI is installed
2. ✅ Verify you're logged in
3. ✅ Set all secrets with your actual server values
4. ✅ Get Kubernetes config from your server
5. ✅ Provide next steps

---

## 🧪 Test Your Setup

After setting up the secrets, test them:

```bash
# Test the pipeline
git add .
git commit -m "Test enterprise CI/CD pipeline"
git push

# Monitor the pipeline
gh run list
gh run view --log

# Check the services
curl http://213.109.162.134:30102  # Grafana
curl http://213.109.162.134:32146  # ArgoCD
```

---

## 🎯 What Each Secret Does

### **Container Registry:**
- `HARBOR_USERNAME/PASSWORD` - Push Docker images to your Harbor registry

### **Security Scanning:**
- `SONARQUBE_URL/TOKEN/ORG` - Code quality and security analysis

### **Deployment:**
- `KUBECONFIG` - Deploy to your Kubernetes cluster
- `VAULT_URL/TOKEN` - Access secrets from your Vault

### **Integration:**
- `JIRA_URL/PROJECT_KEY` - Create issues in your Jira project
- `PROMETHEUS_PUSHGATEWAY_URL` - Send metrics to your Prometheus

### **Notifications:**
- `SLACK_WEBHOOK_URL` - Send notifications to Slack (optional)

---

## ✅ Verification Checklist

After setting up secrets:

- [ ] All secrets added to GitHub repository
- [ ] GitHub CLI can access secrets
- [ ] Kubernetes config is valid
- [ ] Services are accessible from GitHub Actions
- [ ] Test pipeline run succeeds

---

## 🎉 You're Ready!

Once all secrets are configured:

1. **Push code** → Pipeline triggers automatically
2. **Monitor progress** → GitHub Actions tab
3. **Check results** → Grafana dashboards
4. **Review issues** → Jira board
5. **Deploy status** → ArgoCD

**Your enterprise CI/CD pipeline will now work with your actual server!** 🚀
