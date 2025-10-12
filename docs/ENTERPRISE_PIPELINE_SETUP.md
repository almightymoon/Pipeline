# 🚀 Enterprise CI/CD Pipeline Setup Guide

## 📋 Overview

This guide will help you set up the complete enterprise CI/CD pipeline shown in the diagram, using GitHub Actions as the orchestrator. The pipeline includes all the stages from commit validation to deployment and monitoring.

---

## 🏗️ Pipeline Architecture

### **Pipeline Stages:**
1. **🔍 Validate Commit** - Signature verification & changelog generation
2. **🏗️ Build** - Multi-arch container builds with SBOM generation
3. **🔒 Security Scan** - SAST/SCA with SonarQube, Trivy, Dependency Check
4. **📤 Publish** - Harbor registry & Nexus repository
5. **🚀 Deploy** - Kubernetes with Helm & Vault secrets
6. **🧪 Test** - Unit, integration, and end-to-end tests
7. **🔍 QA** - E2E testing with Playwright
8. **⚡ Performance** - Load testing with K6 & Artillery
9. **📊 Monitoring** - Prometheus metrics & Grafana dashboards
10. **🎫 Jira Integration** - Automatic issue creation and updates

### **Supporting Services:**
- **🔐 Vault** - Secret management
- **📊 Prometheus** - Metrics collection
- **📈 Grafana** - Visualization
- **🎫 Jira** - Issue tracking
- **📦 Harbor** - Container registry
- **🔍 SonarQube** - Code quality
- **☸️ Kubernetes** - Container orchestration

---

## 🚀 Quick Start

### **Step 1: Repository Setup**

1. **Clone this repository:**
   ```bash
   git clone https://github.com/almightymoon/Pipeline.git
   cd Pipeline
   ```

2. **Copy the GitHub Actions workflow:**
   ```bash
   mkdir -p .github/workflows
   cp enterprise-ci-cd-pipeline.yml .github/workflows/
   ```

3. **Copy the Helm charts:**
   ```bash
   cp -r charts/ .github/workflows/
   ```

### **Step 2: Configure GitHub Secrets**

Go to your GitHub repository → **Settings** → **Secrets and variables** → **Actions** and add these secrets:

#### **🔐 Essential Secrets:**
```bash
# Container Registry
HARBOR_USERNAME=your-harbor-username
HARBOR_PASSWORD=your-harbor-password

# Security Scanning
SONARQUBE_URL=https://sonar.yourcompany.com
SONARQUBE_TOKEN=your-sonar-token
SONARQUBE_ORG=your-org-key

# Kubernetes
KUBECONFIG=base64-encoded-kubeconfig

# Vault
VAULT_URL=https://vault.yourcompany.com
VAULT_TOKEN=your-vault-token

# Jira
JIRA_URL=https://yourcompany.atlassian.net
JIRA_PROJECT_KEY=PROJ

# Monitoring
PROMETHEUS_PUSHGATEWAY_URL=http://prometheus-pushgateway:9091

# Notifications
SLACK_WEBHOOK_URL=https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK
```

### **Step 3: Infrastructure Setup**

#### **🔧 Harbor Registry Setup:**
```bash
# Create project
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

#### **🔍 SonarQube Setup:**
```bash
# Generate token
curl -X POST "https://sonar.yourcompany.com/api/user_tokens/generate" \
  -u admin:admin \
  -d "name=github-actions&type=GLOBAL_ANALYSIS_TOKEN"
```

#### **🔐 Vault Setup:**
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

#### **☸️ Kubernetes Setup:**
```bash
# Create namespace
kubectl create namespace ml-pipeline

# Create service account
kubectl create serviceaccount ml-pipeline -n ml-pipeline

# Create role binding
kubectl create rolebinding ml-pipeline-binding \
  --clusterrole=edit \
  --serviceaccount=ml-pipeline:ml-pipeline \
  --namespace=ml-pipeline

# Get kubeconfig for GitHub
kubectl config view --raw --minify > kubeconfig
base64 -i kubeconfig -o kubeconfig-base64.txt
```

---

## 📁 Project Structure

```
Pipeline/
├── .github/
│   └── workflows/
│       └── enterprise-ci-cd-pipeline.yml    # Main pipeline
├── charts/
│   └── ml-pipeline/
│       ├── Chart.yaml                       # Helm chart
│       ├── values.yaml                      # Chart values
│       └── templates/
│           ├── deployment.yaml              # Kubernetes deployment
│           └── _helpers.tpl                 # Helm helpers
├── tests/
│   ├── integration/
│   │   └── test_api_integration.py          # Integration tests
│   └── performance/
│       ├── load-test.js                     # K6 load test
│       └── artillery-config.yml             # Artillery config
├── requirements.txt                         # Python dependencies
└── README.md
```

---

## 🔄 Pipeline Flow

### **1. Code Commit Triggers:**
- **Push to main/develop** → Full pipeline
- **Pull Request** → Validation + Security scan
- **Manual trigger** → Full pipeline with environment selection

### **2. Stage Dependencies:**
```
Validate Commit → Build → Security Scan → Publish → Deploy
                                              ↓
Test ← QA ← Performance ← Monitoring ← Cleanup
```

### **3. Parallel Execution:**
- **Test, QA, Performance** run in parallel after deployment
- **Security scans** run in parallel with build
- **Monitoring** runs after all testing stages

---

## 🎯 Key Features

### **🔒 Security First:**
- **Commit signature verification**
- **SAST/SCA scanning** with SonarQube, Trivy
- **Dependency vulnerability scanning**
- **Supply chain verification** with in-toto
- **Secret management** with Vault

### **🚀 Advanced Deployment:**
- **Multi-architecture builds** (AMD64, ARM64)
- **Helm-based deployments** with rollback capability
- **Environment-specific configurations**
- **Blue-green deployments** support
- **GPU support** for ML workloads

### **📊 Comprehensive Testing:**
- **Unit tests** with coverage reporting
- **Integration tests** with real API endpoints
- **E2E tests** with Playwright
- **Performance tests** with K6 and Artillery
- **Load testing** with realistic scenarios

### **📈 Monitoring & Observability:**
- **Prometheus metrics** collection
- **Grafana dashboards** for visualization
- **Real-time alerting** via Slack
- **Performance monitoring** and trending
- **Error tracking** and analysis

### **🎫 Enterprise Integration:**
- **Jira automation** for issue tracking
- **Automatic changelog** generation
- **Release management** with semantic versioning
- **Compliance reporting** and audit trails

---

## 🛠️ Customization

### **Environment Configuration:**
```yaml
# In values.yaml
environment:
  name: "staging"  # staging, production
  configMap:
    enabled: true
    data:
      LOG_LEVEL: "info"
      ENVIRONMENT: "staging"
```

### **Resource Limits:**
```yaml
resources:
  limits:
    cpu: 1000m
    memory: 1Gi
  requests:
    cpu: 500m
    memory: 512Mi
```

### **Auto-scaling:**
```yaml
autoscaling:
  enabled: true
  minReplicas: 2
  maxReplicas: 10
  targetCPUUtilizationPercentage: 80
```

---

## 📊 Monitoring & Alerts

### **Grafana Dashboards:**
- **ML Pipeline Overview** - High-level metrics
- **Test Results** - Pass/fail trends
- **Performance Metrics** - Response times, throughput
- **Resource Usage** - CPU, memory, storage
- **Security Alerts** - Vulnerability trends

### **Prometheus Metrics:**
```promql
# Pipeline success rate
rate(pipeline_run_total{status="success"}[5m])

# Average test duration
avg_over_time(test_duration_seconds[5m])

# Error rate
rate(http_requests_total{status=~"5.."}[5m])
```

### **Slack Notifications:**
- **Pipeline start/completion**
- **Test failures**
- **Security alerts**
- **Performance degradation**
- **Deployment status**

---

## 🔧 Troubleshooting

### **Common Issues:**

#### **1. Harbor Authentication Failed:**
```bash
Error: failed to push: unauthorized
```
**Solution:**
- Verify Harbor credentials in GitHub secrets
- Check robot account permissions
- Ensure project exists in Harbor

#### **2. SonarQube Analysis Failed:**
```bash
Error: Unable to connect to SonarQube server
```
**Solution:**
- Verify SonarQube URL and token
- Check network connectivity
- Ensure organization key is correct

#### **3. Kubernetes Deployment Failed:**
```bash
Error: unable to connect to the server
```
**Solution:**
- Verify kubeconfig is valid and base64 encoded
- Check cluster connectivity
- Ensure service account has proper permissions

#### **4. Vault Authentication Failed:**
```bash
Error: permission denied
```
**Solution:**
- Verify Vault token is valid
- Check Kubernetes service account binding
- Ensure policy allows access to required paths

#### **5. Test Failures:**
```bash
Error: Integration tests failed
```
**Solution:**
- Check if application is deployed correctly
- Verify API endpoints are accessible
- Review test configuration and timeouts

---

## 🚀 Advanced Features

### **1. Multi-Environment Support:**
```yaml
# Different configurations per environment
staging:
  replicas: 2
  resources:
    requests:
      cpu: 250m
      memory: 256Mi

production:
  replicas: 5
  resources:
    requests:
      cpu: 500m
      memory: 512Mi
```

### **2. GPU Support:**
```yaml
gpu:
  enabled: true
  nvidia.com/gpu: 1
  tolerations:
    - key: nvidia.com/gpu
      operator: Exists
      effect: NoSchedule
```

### **3. Blue-Green Deployments:**
```yaml
deployment:
  strategy: "blue-green"
  traffic:
    blue: 100
    green: 0
```

### **4. Canary Releases:**
```yaml
deployment:
  strategy: "canary"
  traffic:
    stable: 90
    canary: 10
```

---

## 📚 Additional Resources

### **Documentation:**
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Harbor Registry Guide](https://goharbor.io/docs/)
- [SonarQube Documentation](https://docs.sonarqube.org/)
- [Vault Documentation](https://www.vaultproject.io/docs)
- [Kubernetes Documentation](https://kubernetes.io/docs/)

### **Tools & Services:**
- [Tekton Pipelines](https://tekton.dev/)
- [ArgoCD](https://argo-cd.readthedocs.io/)
- [Prometheus](https://prometheus.io/docs/)
- [Grafana](https://grafana.com/docs/)
- [K6 Load Testing](https://k6.io/docs/)

### **Best Practices:**
- [12-Factor App](https://12factor.net/)
- [GitOps Principles](https://www.gitops.tech/)
- [Security Best Practices](https://owasp.org/www-project-top-ten/)
- [Kubernetes Security](https://kubernetes.io/docs/concepts/security/)

---

## ✅ Verification Checklist

### **Pre-Deployment:**
- [ ] GitHub repository configured
- [ ] All secrets added to GitHub
- [ ] Harbor registry accessible
- [ ] SonarQube configured
- [ ] Vault accessible
- [ ] Kubernetes cluster ready
- [ ] Jira integration working
- [ ] Monitoring stack deployed

### **Post-Deployment:**
- [ ] Pipeline runs successfully
- [ ] Container images built and pushed
- [ ] Security scans pass
- [ ] Tests execute and pass
- [ ] Application deploys to Kubernetes
- [ ] Metrics appear in Prometheus
- [ ] Dashboards load in Grafana
- [ ] Jira issues created automatically
- [ ] Slack notifications working

---

## 🎉 Success!

**Your enterprise CI/CD pipeline is now fully operational!**

### **What You Have:**
✅ **Complete CI/CD pipeline** with all enterprise features  
✅ **Security scanning** and vulnerability management  
✅ **Automated testing** at multiple levels  
✅ **Kubernetes deployment** with Helm  
✅ **Monitoring and alerting** with Prometheus/Grafana  
✅ **Issue tracking** with Jira integration  
✅ **Performance testing** with load testing tools  
✅ **Secret management** with Vault  
✅ **Container registry** with Harbor  
✅ **Multi-environment** support  

### **Next Steps:**
1. **Monitor** your first pipeline run
2. **Customize** configurations for your needs
3. **Scale** to additional environments
4. **Add** more test scenarios
5. **Integrate** with additional tools as needed

**Happy deploying! 🚀**
