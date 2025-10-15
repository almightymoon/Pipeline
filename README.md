# 🚀 ML/AI Pipeline - Enterprise CI/CD Security Scanner

A comprehensive, automated CI/CD pipeline for ML/AI projects with integrated security scanning, code quality analysis, and deployment automation.

---

## 📋 Table of Contents

- [Features](#features)
- [Quick Start](#quick-start)
- [Architecture](#architecture)
- [Configuration](#configuration)
- [Services](#services)
- [Usage](#usage)
- [Documentation](#documentation)
- [Troubleshooting](#troubleshooting)

---

## ✨ Features

### 🔒 Security Scanning
- **Trivy** - Vulnerability scanning for containers and filesystems
- **Secret Detection** - Finds API keys, passwords, and tokens
- **SonarQube** - SAST (Static Application Security Testing)
- **Dependency Analysis** - Checks for vulnerable dependencies

### 📊 Code Quality
- **Quality Metrics** - TODO/FIXME comments, debug statements, large files
- **Quality Score** - Automated scoring (0-100) based on code quality
- **SonarQube Integration** - Detailed code quality analysis
- **Best Practices** - Automated recommendations

### 🚀 Deployment
- **Docker** - Automated container building
- **Kubernetes** - Automated deployment to K8s clusters
- **NodePort Services** - External access to deployed applications
- **Health Checks** - Automated application monitoring

### 📈 Monitoring & Reporting
- **Grafana** - Real-time dashboards for each repository
- **Prometheus** - Metrics collection and storage
- **Jira Integration** - Automated issue creation with scan results
- **GitHub Actions** - Complete CI/CD automation

---

## 🚀 Quick Start

### Prerequisites

- Docker installed
- GitHub account with Actions enabled
- (Optional) Kubernetes cluster for deployments

### 1. Clone the Repository

```bash
git clone https://github.com/almightymoon/Pipeline.git
cd Pipeline
```

### 2. Set Up Services

#### Start SonarQube (Local)
```bash
docker run -d \
  --name sonarqube \
  -p 30100:9000 \
  -e SONAR_ES_BOOTSTRAP_CHECKS_DISABLE=true \
  sonarqube:10.3-community
```

#### Start Grafana (Local)
```bash
docker run -d \
  --name grafana \
  -p 30102:3000 \
  grafana/grafana:latest
```

#### Start Prometheus (Local)
```bash
docker run -d \
  --name prometheus \
  -p 30090:9090 \
  prom/prometheus:latest
```

### 3. Configure GitHub Secrets

Go to **Settings → Secrets and variables → Actions** and add:

```
JIRA_URL=https://your-jira-instance.atlassian.net
JIRA_EMAIL=your-email@example.com
JIRA_API_TOKEN=your-jira-api-token
JIRA_PROJECT_KEY=YOUR-PROJECT-KEY

GRAFANA_URL=http://localhost:30102
GRAFANA_USERNAME=admin
GRAFANA_PASSWORD=admin

SONARQUBE_URL=http://localhost:30100
SONARQUBE_TOKEN=your-sonarqube-token
```

### 4. Configure Repositories to Scan

Edit `repos-to-scan.yaml`:

```yaml
repositories:
  - name: my-project
    url: https://github.com/username/my-project
    branch: main
    scan_type: full
```

### 5. Push to Trigger Pipeline

```bash
git add repos-to-scan.yaml
git commit -m "Add repository to scan"
git push
```

The pipeline will automatically:
1. ✅ Scan the repository
2. ✅ Run security analysis
3. ✅ Generate Grafana dashboard
4. ✅ Create Jira issue with results
5. ✅ Deploy application (if Dockerfile exists)

---

## 🏗️ Architecture

### Pipeline Flow

```
┌─────────────────┐
│  GitHub Push    │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Clone External  │
│   Repository    │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Security Scans  │
│ • Trivy         │
│ • Secrets       │
│ • SonarQube     │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Code Quality    │
│ • TODO/FIXME    │
│ • Debug Stmts   │
│ • Large Files   │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Build & Deploy  │
│ • Docker Build  │
│ • K8s Deploy    │
│ • Service Expose│
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Report & Monitor│
│ • Grafana       │
│ • Prometheus    │
│ • Jira Issue    │
└─────────────────┘
```

### Components

| Component | Purpose | URL |
|-----------|---------|-----|
| **GitHub Actions** | CI/CD Orchestration | GitHub UI |
| **SonarQube** | Code Quality Analysis | http://localhost:30100 |
| **Grafana** | Dashboards & Visualization | http://localhost:30102 |
| **Prometheus** | Metrics Storage | http://localhost:30090 |
| **Jira** | Issue Tracking | Your Jira Instance |
| **Trivy** | Security Scanning | Embedded in Pipeline |

---

## ⚙️ Configuration

### Repository Configuration

Edit `repos-to-scan.yaml` to add repositories:

```yaml
repositories:
  - name: project-name          # Display name
    url: https://github.com/...  # Repository URL
    branch: main                 # Branch to scan
    scan_type: full             # Scan type: full, security, quality
```

### Environment Variables

Create `.env` file (optional):

```bash
# Grafana
GRAFANA_URL=http://localhost:30102
GRAFANA_USERNAME=admin
GRAFANA_PASSWORD=admin

# SonarQube
SONARQUBE_URL=http://localhost:30100
SONARQUBE_TOKEN=your-token

# Jira
JIRA_URL=https://your-instance.atlassian.net
JIRA_EMAIL=your-email@example.com
JIRA_API_TOKEN=your-token
JIRA_PROJECT_KEY=PROJECT
```

---

## 🌐 Services

### SonarQube

**Access:** http://localhost:30100
**Default Credentials:** admin/admin

**Features:**
- Code quality analysis
- Security vulnerability detection
- Code smells and bugs
- Technical debt tracking

### Grafana

**Access:** http://localhost:30102
**Default Credentials:** admin/admin

**Features:**
- Real-time dashboards per repository
- Security metrics visualization
- Quality score tracking
- Deployment status

### Prometheus

**Access:** http://localhost:30090

**Features:**
- Metrics collection
- Time-series data storage
- Query interface
- Alerting (optional)

---

## 📖 Usage

### Scanning a Repository

1. Add repository to `repos-to-scan.yaml`
2. Commit and push changes
3. Pipeline runs automatically
4. Check results in:
   - GitHub Actions logs
   - Grafana dashboard
   - Jira issue
   - SonarQube report

### Viewing Results

#### Grafana Dashboard
```
http://localhost:30102
→ Dashboards
→ Pipeline Dashboard - {repository-name}
```

#### SonarQube Report
```
http://localhost:30100
→ Projects
→ {repository-name}
```

#### Jira Issue
Check your Jira project for automatically created issues with scan results.

### Accessing Deployed Applications

If a Dockerfile is detected, the application is deployed to Kubernetes:

```
http://{server-ip}:{node-port}
```

Node ports are assigned automatically (30000-32767 range).

---

## 📚 Documentation

### Core Documentation

- **PIPELINE_FIXED_SUMMARY.md** - Pipeline fixes and current status
- **SONARQUBE_AND_JIRA_IMPROVEMENTS.md** - SonarQube setup and Jira report improvements

### Additional Guides (in `docs/`)

- **COMPLETE_PIPELINE_GUIDE.md** - Comprehensive pipeline documentation
- **DASHBOARDS_GUIDE.md** - Grafana dashboard setup
- **JIRA_SETUP_GUIDE.md** - Jira integration guide
- **K3S_CLUSTER_SETUP.md** - Kubernetes cluster setup
- **CREDENTIALS_GUIDE.md** - Secrets and credentials management

---

## 🔧 Troubleshooting

### SonarQube Not Accessible

**Problem:** "This site can't be reached" when accessing SonarQube

**Solution:** SonarQube runs locally. Access from your local machine:
```bash
http://localhost:30100
```

If running on a remote server, use SSH tunnel:
```bash
ssh -L 30100:localhost:30100 user@server-ip
```

### Pipeline Fails

**Check:**
1. GitHub Secrets are configured correctly
2. Services (SonarQube, Grafana, Prometheus) are running
3. Repository URL in `repos-to-scan.yaml` is accessible
4. GitHub Actions logs for detailed error messages

### Grafana Dashboard Not Showing Data

**Solution:**
1. Check Prometheus is running: `docker ps | grep prometheus`
2. Verify metrics are being pushed: Check pipeline logs
3. Refresh Grafana dashboard
4. Check dashboard time range (default: last 1 hour)

### Jira Issue Not Created

**Check:**
1. `JIRA_URL`, `JIRA_EMAIL`, `JIRA_API_TOKEN`, `JIRA_PROJECT_KEY` secrets are set
2. Jira API token has correct permissions
3. Project key exists in Jira
4. Check pipeline logs for Jira API errors

---

## 🎯 Key Features

### Automated Security Scanning
- ✅ Trivy vulnerability scanning
- ✅ Secret detection (API keys, passwords, tokens)
- ✅ SonarQube SAST analysis
- ✅ Dependency vulnerability checking

### Code Quality Analysis
- ✅ TODO/FIXME comment detection
- ✅ Debug statement detection
- ✅ Large file identification
- ✅ Quality score calculation (0-100)

### Deployment Automation
- ✅ Docker image building
- ✅ Kubernetes deployment
- ✅ Service exposure via NodePort
- ✅ Health check monitoring

### Reporting & Monitoring
- ✅ Grafana dashboards (one per repository)
- ✅ Prometheus metrics collection
- ✅ Jira issue creation with detailed results
- ✅ GitHub Actions integration

---

## 📊 Metrics Collected

### Security Metrics
- Total vulnerabilities (Critical/High/Medium/Low)
- Secrets detected (API Keys/Passwords/Tokens)
- Security scan duration
- Vulnerability trends

### Quality Metrics
- TODO/FIXME comments count
- Debug statements count
- Large files count (>1MB)
- Quality score (0-100)
- Code coverage (if tests exist)

### Deployment Metrics
- Build success/failure rate
- Deployment status
- Application health
- Response time

---

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

---

## 📝 License

This project is licensed under the MIT License.

---

## 🆘 Support

For issues, questions, or contributions:
- **GitHub Issues:** https://github.com/almightymoon/Pipeline/issues
- **Documentation:** See `docs/` folder
- **Examples:** Check `repos-to-scan.yaml` for configuration examples

---

## 🎉 Quick Links

| Service | URL | Purpose |
|---------|-----|---------|
| **SonarQube** | http://localhost:30100 | Code quality analysis |
| **Grafana** | http://localhost:30102 | Dashboards & metrics |
| **Prometheus** | http://localhost:30090 | Metrics storage |
| **GitHub Actions** | GitHub UI | Pipeline execution |

---

**Built with ❤️ for secure, high-quality ML/AI development**
