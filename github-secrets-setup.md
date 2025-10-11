# 🔐 GitHub Secrets Setup for Enterprise CI/CD Pipeline

## Required GitHub Secrets

To use the enterprise CI/CD pipeline, you need to configure these secrets in your GitHub repository:

### 🔗 Repository Settings → Secrets and variables → Actions

---

## 📋 Complete Secrets List

### 1. **Container Registry Secrets**
```
HARBOR_USERNAME=your-harbor-username
HARBOR_PASSWORD=your-harbor-password
```

### 2. **Security Scanning Secrets**
```
SONARQUBE_URL=https://sonar.yourcompany.com
SONARQUBE_TOKEN=your-sonar-token
SONARQUBE_ORG=your-org-key
```

### 3. **Kubernetes Secrets**
```
KUBECONFIG=base64-encoded-kubeconfig
```

### 4. **Vault Secrets**
```
VAULT_URL=https://vault.yourcompany.com
VAULT_TOKEN=your-vault-token
```

### 5. **Jira Integration**
```
JIRA_URL=https://yourcompany.atlassian.net
JIRA_PROJECT_KEY=PROJ
```

### 6. **Monitoring Secrets**
```
PROMETHEUS_PUSHGATEWAY_URL=http://prometheus-pushgateway:9091
```

### 7. **Notification Secrets**
```
SLACK_WEBHOOK_URL=https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK
```

---

## 🚀 Quick Setup Commands

### 1. **Set up Harbor Registry**
```bash
# Create Harbor project
curl -X POST "https://harbor.yourcompany.com/api/v2.0/projects" \
  -H "Content-Type: application/json" \
  -u admin:password \
  -d '{"project_name": "ml-pipeline", "public": false}'

# Create robot account
curl -X POST "https://harbor.yourcompany.com/api/v2.0/projects/ml-pipeline/robots" \
  -H "Content-Type: application/json" \
  -u admin:password \
  -d '{"name": "github-actions", "description": "GitHub Actions robot account"}'
```

### 2. **Set up SonarQube**
```bash
# Generate token
curl -X POST "https://sonar.yourcompany.com/api/user_tokens/generate" \
  -u admin:admin \
  -d "name=github-actions&type=GLOBAL_ANALYSIS_TOKEN"
```

### 3. **Set up Vault**
```bash
# Enable Kubernetes auth
vault auth enable kubernetes

# Create role
vault write auth/kubernetes/role/ml-pipeline \
  bound_service_account_names=ml-pipeline \
  bound_service_account_namespaces=ml-pipeline \
  policies=ml-pipeline-policy \
  ttl=24h

# Create policy
vault policy write ml-pipeline-policy - <<EOF
path "secret/kubernetes/staging" {
  capabilities = ["read"]
}
path "secret/application/ml-pipeline" {
  capabilities = ["read"]
}
EOF
```

### 4. **Set up Jira Integration**
```bash
# Create API token in Jira
# Go to: https://id.atlassian.com/manage-profile/security/api-tokens
# Create token for your account
```

### 5. **Set up Kubernetes Access**
```bash
# Get kubeconfig
kubectl config view --raw --minify > kubeconfig

# Encode for GitHub secret
base64 -i kubeconfig -o kubeconfig-base64.txt
# Copy content of kubeconfig-base64.txt to KUBECONFIG secret
```

---

## 🔧 GitHub CLI Setup (Alternative)

If you have GitHub CLI installed:

```bash
# Install GitHub CLI
brew install gh

# Login to GitHub
gh auth login

# Set secrets
gh secret set HARBOR_USERNAME --body "your-harbor-username"
gh secret set HARBOR_PASSWORD --body "your-harbor-password"
gh secret set SONARQUBE_URL --body "https://sonar.yourcompany.com"
gh secret set SONARQUBE_TOKEN --body "your-sonar-token"
gh secret set SONARQUBE_ORG --body "your-org-key"
gh secret set KUBECONFIG --body "$(cat kubeconfig-base64.txt)"
gh secret set VAULT_URL --body "https://vault.yourcompany.com"
gh secret set VAULT_TOKEN --body "your-vault-token"
gh secret set JIRA_URL --body "https://yourcompany.atlassian.net"
gh secret set JIRA_PROJECT_KEY --body "PROJ"
gh secret set PROMETHEUS_PUSHGATEWAY_URL --body "http://prometheus-pushgateway:9091"
gh secret set SLACK_WEBHOOK_URL --body "https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK"
```

---

## 📱 Manual Setup via GitHub UI

### Step 1: Navigate to Repository Settings
1. Go to your GitHub repository
2. Click **Settings** tab
3. Click **Secrets and variables** → **Actions**

### Step 2: Add Each Secret
1. Click **New repository secret**
2. Enter the **Name** and **Value**
3. Click **Add secret**

**Repeat for all secrets listed above.**

---

## 🧪 Test Your Setup

### Create a Test Workflow
```yaml
# .github/workflows/test-secrets.yml
name: Test Secrets
on: [workflow_dispatch]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - name: Test Secrets
        run: |
          echo "Testing secrets..."
          echo "Harbor URL configured: ${{ secrets.HARBOR_USERNAME != '' }}"
          echo "SonarQube configured: ${{ secrets.SONARQUBE_URL != '' }}"
          echo "Vault configured: ${{ secrets.VAULT_URL != '' }}"
          echo "Jira configured: ${{ secrets.JIRA_URL != '' }}"
```

### Run the Test
1. Go to **Actions** tab
2. Click **Test Secrets** workflow
3. Click **Run workflow**
4. Check if all secrets are detected

---

## 🔒 Security Best Practices

### 1. **Use Least Privilege**
- Only grant necessary permissions to each service
- Use specific service accounts and roles
- Rotate tokens regularly

### 2. **Secure Secret Storage**
- Use Vault for sensitive application secrets
- Use GitHub Secrets for CI/CD credentials only
- Never commit secrets to code

### 3. **Monitor Access**
- Enable audit logging in all services
- Monitor secret usage
- Set up alerts for unusual activity

### 4. **Regular Rotation**
- Rotate tokens every 90 days
- Use short-lived tokens where possible
- Implement automated rotation where feasible

---

## 🚨 Troubleshooting

### Common Issues

#### 1. **Harbor Authentication Failed**
```
Error: failed to push: unauthorized
```
**Solution:**
- Verify Harbor credentials
- Check if robot account has push permissions
- Ensure project exists in Harbor

#### 2. **SonarQube Analysis Failed**
```
Error: Unable to connect to SonarQube server
```
**Solution:**
- Verify SonarQube URL is accessible
- Check token permissions
- Ensure organization key is correct

#### 3. **Kubernetes Deployment Failed**
```
Error: unable to connect to the server
```
**Solution:**
- Verify kubeconfig is valid
- Check cluster connectivity
- Ensure service account has proper permissions

#### 4. **Vault Authentication Failed**
```
Error: permission denied
```
**Solution:**
- Verify Vault token is valid
- Check Kubernetes service account binding
- Ensure policy allows access to required paths

---

## 📊 Monitoring Your Pipeline

### 1. **GitHub Actions Dashboard**
- Go to **Actions** tab
- Monitor pipeline runs
- Check logs for failures

### 2. **External Monitoring**
- **Grafana:** Monitor deployment metrics
- **Prometheus:** Check pipeline metrics
- **Jira:** Track issues created by pipeline

### 3. **Alerts**
- Set up Slack notifications for failures
- Configure email alerts for critical issues
- Monitor resource usage and costs

---

## ✅ Verification Checklist

- [ ] Harbor registry access configured
- [ ] SonarQube integration working
- [ ] Kubernetes cluster accessible
- [ ] Vault secrets accessible
- [ ] Jira integration functional
- [ ] Monitoring endpoints reachable
- [ ] Notification channels working
- [ ] Test workflow passes
- [ ] Security scanning enabled
- [ ] Deployment pipeline functional

---

## 🎉 You're Ready!

Once all secrets are configured:

1. **Push code** to trigger the pipeline
2. **Monitor** the Actions tab for progress
3. **Check** Grafana dashboards for metrics
4. **Review** Jira for created issues
5. **Verify** deployment in Kubernetes

**Your enterprise CI/CD pipeline is now fully operational!** 🚀
