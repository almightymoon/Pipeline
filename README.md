# 🚀 Enterprise ML/AI CI/CD Pipeline

A production-ready, enterprise-grade CI/CD pipeline for ML/AI projects with GitHub Actions, Kubernetes deployment, comprehensive monitoring, and Jira integration.

## ✨ Features

### 🔄 CI/CD Pipeline
- **GitHub Actions Workflow**: Automated builds on every push
- **Multi-Stage Pipeline**: Validation → Build → Security → Test → Deploy → Monitor
- **Kubernetes Deployment**: Direct deployment to K3s cluster
- **Docker Container Building**: Automated containerization
- **Dataset Processing**: Process datasets from any repository! 📊

### 🔒 Security & Quality
- **Security Scanning**: Trivy vulnerability scanning
- **Dependency Checking**: Automated dependency analysis
- **Code Quality**: SonarQube integration (configurable)
- **SBOM Generation**: Software Bill of Materials for compliance

### 📊 Monitoring & Observability
- **Prometheus**: Metrics collection and monitoring
- **Grafana**: Beautiful dashboards and visualizations
- **Repository-Specific Dashboards**: 🆕 Unique dashboard for each repository scanned
- **Automated Dashboard Creation**: Auto-generates dashboards with real-time metrics
- **Real-time Alerts**: Automated alerting system
- **Pipeline Metrics**: Track build times, success rates, and more

### 🎫 Integration
- **Jira**: Automatic issue creation and tracking
- **Slack**: Notification support (optional)
- **Vault**: Secure secret management
- **ArgoCD**: GitOps deployments

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                      GitHub Actions Pipeline                     │
└─────────────────────────────────────────────────────────────────┘
              │
              ├─▶ 🔍 Validate Commit
              ├─▶ 🏗️  Build & Package (Docker)
              ├─▶ 🔒 Security Scan (Trivy + Dependencies)
              ├─▶ 🧪 Run Tests (Pytest + Coverage)
              ├─▶ 🚀 Deploy to Kubernetes
              ├─▶ 📊 Send Metrics (Prometheus)
              └─▶ 🎫 Update Jira & Notify

                       ⬇️  Deploy to  ⬇️

┌─────────────────────────────────────────────────────────────────┐
│                    Kubernetes Cluster (K3s)                      │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐       │
│  │ ArgoCD   │  │ Tekton   │  │ Vault    │  │ Gatekeeper│      │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘       │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐                     │
│  │Prometheus│  │ Grafana  │  │ ML Apps  │                     │
│  └──────────┘  └──────────┘  └──────────┘                     │
└─────────────────────────────────────────────────────────────────┘
```

## 📋 Prerequisites

### Required
- **GitHub Account**: For CI/CD workflows
- **Kubernetes Cluster**: K3s or similar (v1.24+)
- **kubectl**: Configured to access your cluster
- **Docker**: For local testing

### Optional
- **GitHub CLI** (`gh`): For easier secret management
- **Jira Account**: For issue tracking integration
- **Slack Workspace**: For notifications

## 🚀 Quick Start

> **💡 Process ANY repository (datasets, code, etc.):**
> 1. Edit `repos-to-process.yaml` - add your repo URL
> 2. Push to GitHub
> 3. Pipeline auto-runs! ✨
> 
> See [SIMPLE_USAGE_GUIDE.md](SIMPLE_USAGE_GUIDE.md) for details!

### 1. Clone the Repository

```bash
git clone https://github.com/yourorg/pipeline.git
cd pipeline
```

### 2. Set Up GitHub Secrets

You need to configure the following secrets in your GitHub repository:

```bash
# Using GitHub CLI (recommended)
gh auth login

# Set Kubernetes access
gh secret set KUBECONFIG --body "$(cat ~/.kube/config | base64)"

# Set other secrets
gh secret set HARBOR_USERNAME --body "admin"
gh secret set HARBOR_PASSWORD --body "your-password"
gh secret set SONARQUBE_URL --body "http://your-sonarqube:9000"
gh secret set SONARQUBE_TOKEN --body "your-token"
gh secret set VAULT_URL --body "http://your-vault:8200"
gh secret set VAULT_TOKEN --body "your-token"
gh secret set JIRA_URL --body "https://your-company.atlassian.net"
gh secret set JIRA_PROJECT_KEY --body "ML"
gh secret set PROMETHEUS_PUSHGATEWAY_URL --body "http://your-prometheus:9091"
```

**Or use the automated setup script:**

```bash
./setup-github-secrets.sh
```

See [docs/GITHUB_SECRETS_VALUES.md](docs/GITHUB_SECRETS_VALUES.md) for detailed instructions.

### 3. Configure Your Pipeline

Edit `.github/workflows/basic-pipeline.yml` to customize:

```yaml
env:
  REGISTRY: your-harbor-registry.com
  IMAGE_NAME: your-org/your-app
```

### 4. Push to Trigger Pipeline

```bash
git add .
git commit -m "Initial setup"
git push origin main
```

The pipeline will automatically run! 🎉

### 5. Monitor Your Pipeline

- **GitHub Actions**: `https://github.com/your-org/your-repo/actions`
- **Grafana**: `http://your-server:30102` (admin/admin123)
- **ArgoCD**: `http://your-server:32146` (admin/password)
- **Jira**: Check your project for automated issues

## 📁 Project Structure

```
pipeline/
├── .github/workflows/
│   ├── basic-pipeline.yml          # Main CI/CD workflow
│   └── dataset-pipeline.yml        # Dataset processing workflow ⭐NEW
├── docs/                            # Documentation
│   ├── COMPLETE_PIPELINE_GUIDE.md  # Comprehensive guide
│   ├── DATASET_PROCESSING_GUIDE.md # Dataset processing ⭐NEW
│   ├── USING_PIPELINE_WITH_OTHER_REPOS.md # Use with other repos ⭐NEW
│   ├── GITHUB_SECRETS_VALUES.md    # Secret configuration
│   ├── JIRA_SETUP_GUIDE.md         # Jira integration
│   ├── DASHBOARDS_GUIDE.md         # Grafana dashboards
│   └── CREDENTIALS_GUIDE.md        # Credentials management
├── scripts/                         # Utility scripts ⭐NEW
│   ├── validate_dataset.py         # Dataset validation
│   └── process_dataset.py          # Dataset processing
├── configs/                         # Configuration files
│   ├── deepspeed.json              # DeepSpeed config
│   ├── model-config.yaml           # Model settings
│   └── dataset-transform.yaml      # Data processing
├── k8s/                            # Kubernetes manifests
│   ├── namespace.yaml              # Namespaces
│   ├── gpu-operator.yaml           # GPU support
│   ├── ml-training-job.yaml        # Training jobs
│   └── triton-inference.yaml       # Inference server
├── monitoring/                      # Monitoring configs
│   ├── prometheus-rules.yaml       # Prometheus alerts
│   └── grafana-dashboard.json      # Dashboards
├── integrations/                    # Third-party integrations
│   └── jira-config.yaml            # Jira configuration
├── credentials/                     # Secret templates
│   └── all-services-secrets.yaml   # All secrets template
├── src/                            # Application source code
│   └── ml_pipeline/
│       ├── __init__.py
│       └── main.py
├── tests/                          # Test suites
│   ├── test_basic.py              # Unit tests
│   ├── integration/               # Integration tests
│   └── performance/               # Load tests
├── setup-github-secrets.sh        # Secret setup script
├── setup-jira-integration.sh      # Jira setup script
├── setup-with-credentials.sh      # Full setup script
├── Dockerfile                      # Container definition
├── requirements.txt                # Python dependencies
├── QUICK_START.md                  # Quick reference ⭐NEW
└── README.md                       # This file
```

## 🔧 Configuration

### Pipeline Stages

The pipeline consists of 7 stages:

1. **🔍 Validate Commit** (4s): Validates commit signature and metadata
2. **🏗️ Build & Package** (~5min): Builds Docker images
3. **🔒 Security Analysis** (10s): Runs Trivy vulnerability scans
4. **🧪 Run Tests** (15s): Executes unit and integration tests
5. **🚀 Deploy to Kubernetes** (8s): Deploys to your cluster
6. **📊 Monitoring & Reporting** (3s): Sends metrics to Prometheus
7. **🧹 Cleanup & Notifications** (3s): Cleans up and notifies stakeholders

### Environment Variables

| Variable | Description | Required | Default |
|----------|-------------|----------|---------|
| `KUBECONFIG` | Base64 encoded kubeconfig | ✅ Yes | - |
| `HARBOR_USERNAME` | Registry username | No | - |
| `HARBOR_PASSWORD` | Registry password | No | - |
| `SONARQUBE_URL` | SonarQube server URL | No | - |
| `SONARQUBE_TOKEN` | SonarQube auth token | No | - |
| `JIRA_URL` | Jira server URL | No | - |
| `JIRA_PROJECT_KEY` | Jira project key | No | `ML` |
| `PROMETHEUS_PUSHGATEWAY_URL` | Prometheus URL | No | - |
| `VAULT_URL` | Vault server URL | No | - |
| `VAULT_TOKEN` | Vault auth token | No | - |

## 📊 Monitoring

### Grafana Dashboards

Access Grafana at `http://your-server:30102`:

- **ML Pipeline Overview**: Pipeline execution metrics
- **Test Results**: Test coverage and pass rates
- **Build Performance**: Build times and success rates
- **Infrastructure**: Resource usage and health

Default credentials: `admin` / `admin123`

### 🆕 Repository-Specific Dashboards

**Each repository gets its own unique dashboard!**

When you scan a repository, the system automatically:
1. ✅ Creates a unique Grafana dashboard for that repository
2. ✅ Populates it with real-time metrics from the pipeline run
3. ✅ Creates a Jira ticket with a direct link to that dashboard

**Quick Start:**
```bash
# 1. Configure your repository
vim repos-to-scan.yaml

# 2. Run your pipeline (scans the repository)

# 3. Create dashboard and Jira ticket
./create-repo-dashboard.sh
```

**Example Dashboards:**
- `tensorflow-models` → `http://213.109.162.134:30102/d/e03ed124.../tensorflow-models`
- `neuropilot-project` → `http://213.109.162.134:30102/d/abc123.../neuropilot-project`
- `your-repo` → Automatically generated with unique URL

**What You Get:**
- 📊 Security vulnerabilities (Critical, High, Medium, Low)
- 📝 Code quality metrics (TODO comments, debug statements)
- 🧪 Test results (passed, failed, coverage)
- 📁 Repository info (files scanned, size, scan time)

**Documentation:**
- 📖 [Quick Start Guide](QUICK_START_DASHBOARDS.md)
- 📖 [Full Documentation](REPOSITORY_DASHBOARD_GUIDE.md)
- 📖 [Live Demo](DASHBOARD_DEMO.md)
- 📖 [System Overview](SYSTEM_OVERVIEW.md)

### Prometheus Metrics

The pipeline sends these metrics to Prometheus:

```
pipeline_run_total{status="success",branch="main"} 1
pipeline_duration_seconds{branch="main"} 360
pipeline_tests_passed{branch="main"} 41
pipeline_tests_failed{branch="main"} 1
```

### Key Metrics

- `pipeline_run_total`: Total pipeline runs
- `pipeline_duration_seconds`: Pipeline execution time
- `pipeline_tests_passed`: Number of tests passed
- `pipeline_tests_failed`: Number of tests failed
- `pipeline_build_size_bytes`: Docker image size

## 🎫 Jira Integration

### Setup

1. Get your Jira API token: https://id.atlassian.com/manage-profile/security/api-tokens
2. Run the setup script:

```bash
./setup-jira-integration.sh
```

3. The pipeline will automatically:
   - Create issues when pipelines fail
   - Update issues when fixed
   - Track test failures
   - Report metrics

See [docs/JIRA_SETUP_GUIDE.md](docs/JIRA_SETUP_GUIDE.md) for details.

## 🔒 Security

### Secret Management

All secrets are stored in:
- **GitHub Secrets**: For CI/CD workflows
- **Kubernetes Secrets**: For runtime access
- **HashiCorp Vault**: For centralized secret management

### Security Scanning

Every build includes:
- **Trivy**: Container vulnerability scanning
- **Dependency Check**: Dependency vulnerability analysis
- **SBOM**: Software Bill of Materials generation

### Best Practices

- ✅ Never commit secrets to Git
- ✅ Use Vault for secret rotation
- ✅ Enable branch protection rules
- ✅ Require signed commits
- ✅ Regular security audits

## 🐛 Troubleshooting

### Pipeline Failures

**Issue**: `base64: invalid input`

**Solution**: Ensure KUBECONFIG secret is properly base64 encoded:
```bash
cat ~/.kube/config | base64 | gh secret set KUBECONFIG --body-file -
```

**Issue**: `Kubernetes cluster not accessible`

**Solution**: Check your kubeconfig points to the correct server IP, not localhost.

**Issue**: `Docker build fails`

**Solution**: Check Docker BuildX is enabled and you have sufficient disk space.

### Kubernetes Connection

```bash
# Test kubectl access
kubectl get nodes

# Check pipeline pods
kubectl get pods -n ml-pipeline

# View pipeline logs
kubectl logs -f <pod-name> -n ml-pipeline
```

### Common Commands

```bash
# View workflow runs
gh run list

# Watch active run
gh run watch

# View run logs
gh run view --log

# Rerun failed job
gh run rerun <run-id>
```

## 📚 Documentation

- **[Complete Pipeline Guide](docs/COMPLETE_PIPELINE_GUIDE.md)**: Comprehensive guide
- **[GitHub Secrets Setup](docs/GITHUB_SECRETS_VALUES.md)**: Secret configuration
- **[Jira Integration](docs/JIRA_SETUP_GUIDE.md)**: Jira setup guide
- **[Dashboards Guide](docs/DASHBOARDS_GUIDE.md)**: Grafana dashboards
- **[Credentials Guide](docs/CREDENTIALS_GUIDE.md)**: Managing credentials

## 🎯 Workflow Status

| Workflow | Status | Description |
|----------|--------|-------------|
| [Basic Pipeline](.github/workflows/basic-pipeline.yml) | [![CI](https://github.com/yourorg/pipeline/actions/workflows/basic-pipeline.yml/badge.svg)](https://github.com/yourorg/pipeline/actions/workflows/basic-pipeline.yml) | Main CI/CD workflow |

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Commit your changes: `git commit -m 'Add amazing feature'`
4. Push to the branch: `git push origin feature/amazing-feature`
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 📞 Support

- **GitHub Issues**: [Open an issue](https://github.com/yourorg/pipeline/issues)
- **Documentation**: Check the `docs/` directory
- **Email**: ml-team@example.com

## 🎉 Acknowledgments

Built with:
- GitHub Actions
- Kubernetes (K3s)
- Tekton Pipelines
- ArgoCD
- Prometheus & Grafana
- HashiCorp Vault
- Jira

---

**Made with ❤️ for ML/AI Teams**
