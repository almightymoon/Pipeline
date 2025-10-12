# Current Pipeline Setup

## Overview
This is a production-ready CI/CD pipeline for automated build, test, security scanning, and deployment.

---

## Active Workflow
**File**: `.github/workflows/basic-pipeline.yml`

### Pipeline Stages:
1. **Validate Commit** - Validates commit messages and code quality
2. **Build & Package** - Builds Docker images and generates SBOM
3. **Run Tests** - Executes unit tests with coverage reports
4. **Security Analysis** - Scans for vulnerabilities and secrets using Trivy
5. **Deploy to Kubernetes** - Deploys to K3s cluster
6. **Setup Monitoring & Reporting** - Creates Jira issues and sends metrics
7. **Cleanup & Notifications** - Final cleanup and notifications

---

## Scripts
**Location**: `scripts/`

- **create_jira_issue.py** - Creates Jira issues for pipeline runs

---

## Key Documentation
- **README.md** - Main project documentation
- **SECURITY_SCAN_RESULTS.md** - Latest security scan findings
- **HOW_TO_USE.md** - Usage instructions
- **QUICK_START.md** - Quick start guide
- **SIMPLE_USAGE_GUIDE.md** - Simplified usage guide

---

## Infrastructure
- **Kubernetes**: K3s cluster at 213.109.162.134
- **Container Registry**: Harbor at harbor.yourcompany.com
- **Monitoring**: Prometheus (configured)
- **Issue Tracking**: Jira (KAN project)

---

## GitHub Secrets Configured
- `KUBECONFIG` - Kubernetes cluster access
- `HARBOR_USERNAME` / `HARBOR_PASSWORD` - Container registry
- `JIRA_URL` / `JIRA_EMAIL` / `JIRA_API_TOKEN` / `JIRA_PROJECT_KEY` - Jira integration

---

## How to Trigger the Pipeline

### Via GitHub UI:
1. Go to: https://github.com/almightymoon/Pipeline/actions
2. Select "Working ML Pipeline"
3. Click "Run workflow"

### Via CLI:
```bash
gh workflow run basic-pipeline.yml
```

---

## Pipeline Features
✅ Automated build and packaging
✅ Unit testing with coverage
✅ Security vulnerability scanning
✅ Secret detection
✅ Kubernetes deployment
✅ Jira issue creation
✅ Prometheus metrics
✅ Clean, maintainable codebase

---

## Next Steps
1. Add your application code
2. Configure application-specific tests
3. Customize deployment manifests in `k8s/`
4. Add environment-specific configurations

---

*Last updated: October 13, 2025*

