# 🔐 ML Pipeline Access Credentials Guide

This guide provides all the access credentials and configurations needed for the ML Pipeline services.

## 🚀 Quick Setup

Run the complete setup with credentials:
```bash
./setup-with-credentials.sh
```

## 📊 Monitoring Services

### Prometheus
- **URL**: `https://prometheus.example.com`
- **Default Credentials**: `admin/admin123`
- **Configuration**: `credentials/prometheus-config.yaml`
- **Features**: Metrics collection, alerting, service discovery

### Grafana
- **URL**: `https://grafana.example.com`
- **Default Credentials**: `admin/admin123`
- **Configuration**: `credentials/grafana-config.yaml`
- **Features**: Dashboards, alerting, multi-datasource support
- **Datasources**: Prometheus, Loki, Jaeger, OpenSearch, InfluxDB, MySQL, PostgreSQL

### OpenSearch
- **URL**: `https://opensearch.example.com`
- **Default Credentials**: `admin/admin123`
- **Index**: `ml-pipeline-logs`
- **Features**: Log aggregation, search, analytics

## 🔒 Security Services

### SonarQube
- **URL**: `https://sonarqube.example.com`
- **Token**: `sqp_your_sonarqube_token_here`
- **Configuration**: `security/sonarqube-config.yaml`
- **Features**: Code quality, security scanning, technical debt

### DefectDojo
- **URL**: `https://defectdojo.example.com`
- **Default Credentials**: `admin/password`
- **API Key**: `your_defectdojo_api_key_here`
- **Features**: Vulnerability management, security orchestration

### Dependency Track
- **URL**: `https://dependency-track.example.com`
- **Default Credentials**: `admin/password`
- **API Key**: `your_dependency_track_api_key_here`
- **Features**: Software composition analysis, vulnerability tracking

## 📦 Registry & Storage

### Harbor Registry
- **URL**: `harbor.example.com`
- **Default Credentials**: `admin/password`
- **Features**: Container registry, image signing, vulnerability scanning
- **Namespaces**: `ml-pipeline`, `ml-staging`, `ml-production`

### Nexus Repository
- **URL**: `https://nexus.example.com`
- **Default Credentials**: `admin/admin123`
- **Features**: Artifact storage, Maven, npm, Docker registry

## 📋 Project Management

### Jira
- **URL**: `https://jira.example.com`
- **Username**: `ml-pipeline@example.com`
- **API Token**: `your_jira_api_token_here`
- **Configuration**: `integrations/jira-config.yaml`
- **Features**: Issue tracking, automated reporting, workflow management

## 🔧 Infrastructure

### HashiCorp Vault
- **URL**: `https://vault.example.com`
- **Token**: `your_vault_token_here`
- **Role ID**: `your_vault_role_id_here`
- **Secret ID**: `your_vault_secret_id_here`
- **Features**: Secret management, encryption, access control

### Kubernetes
- **Dashboard**: `kubectl proxy`
- **API Server**: Configured via kubeconfig
- **Features**: Container orchestration, service mesh, RBAC

## 📱 Notifications

### Slack Integration
- **Webhook URL**: `https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK`
- **Bot Token**: `xoxb-your-bot-token-here`
- **Channel**: `#ml-pipeline`
- **Features**: Real-time notifications, pipeline status updates

### Email SMTP
- **Server**: `smtp.example.com:587`
- **Username**: `ml-pipeline@example.com`
- **Password**: `your_smtp_password_here`
- **Features**: Email alerts, reports, notifications

## 🗄️ Databases

### PostgreSQL
- **Host**: `postgres.example.com:5432`
- **Database**: `ml_pipeline`
- **Username**: `ml_user`
- **Password**: `ml_password_here`
- **SSL Mode**: `require`

### MySQL
- **Host**: `mysql.example.com:3306`
- **Database**: `ml_pipeline`
- **Username**: `ml_user`
- **Password**: `ml_password_here`
- **SSL Mode**: `required`

### InfluxDB
- **URL**: `http://influxdb:8086`
- **Database**: `ml_pipeline_metrics`
- **Username**: `admin`
- **Password**: `influxdb_password`

## ☁️ Cloud Providers

### AWS
- **Access Key**: `AKIAIOSFODNN7EXAMPLE`
- **Secret Key**: `wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY`
- **Region**: `us-east-1`
- **Role ARN**: `arn:aws:iam::123456789012:role/MLPipelineRole`

### Azure
- **Tenant ID**: `your-azure-tenant-id`
- **Client ID**: `your-azure-client-id`
- **Client Secret**: `your-azure-client-secret`
- **Subscription ID**: `your-azure-subscription-id`

### Google Cloud Platform
- **Project ID**: `your-gcp-project-id`
- **Service Account**: `grafana@your-gcp-project.iam.gserviceaccount.com`
- **Private Key**: `your-gcp-private-key`

## 🤖 ML/AI Services

### Weights & Biases (WandB)
- **API Key**: `your_wandb_api_key_here`
- **Project**: `ml-pipeline-training`
- **Entity**: `ml-team`

### MLflow
- **Tracking URI**: `https://mlflow.example.com`
- **Username**: `admin`
- **Password**: `admin123`
- **API Key**: `your_mlflow_api_key_here`

### Hugging Face
- **API Token**: `hf_your_huggingface_token_here`
- **Username**: `your_huggingface_username`

## 🔗 Version Control

### GitHub
- **Token**: `ghp_your_github_token_here`
- **Username**: `your_github_username`
- **Webhook Secret**: `your_webhook_secret_here`

### GitLab
- **Token**: `glpat_your_gitlab_token_here`
- **Username**: `your_gitlab_username`
- **Webhook Secret**: `your_webhook_secret_here`

## 🛠️ Configuration Files

### Pipeline Configuration
- **Main Pipeline**: `pipeline.yml`
- **Deployment Script**: `deploy.sh`
- **Credentials Setup**: `setup-with-credentials.sh`
- **Quick Runner**: `run-pipeline.sh`

### Security Configuration
- **SonarQube**: `security/sonarqube-config.yaml`
- **All Secrets**: `credentials/all-services-secrets.yaml`
- **Prometheus Config**: `credentials/prometheus-config.yaml`
- **Grafana Config**: `credentials/grafana-config.yaml`

### Monitoring Configuration
- **Prometheus Rules**: `monitoring/prometheus-rules.yaml`
- **Grafana Dashboard**: `monitoring/grafana-dashboard.json`

## 🚨 Security Best Practices

### 1. Change Default Passwords
```bash
# Update all default passwords
kubectl edit secret harbor-creds -n ml-pipeline
kubectl edit secret grafana-creds -n monitoring
kubectl edit secret sonar-token -n ml-pipeline
```

### 2. Use Strong Tokens
- Generate strong API tokens for all services
- Rotate tokens regularly
- Use environment-specific tokens

### 3. Enable TLS/SSL
- Configure HTTPS for all web services
- Use valid SSL certificates
- Enable mutual TLS where supported

### 4. Network Security
- Use network policies to restrict access
- Enable firewall rules
- Use VPN for remote access

## 🔧 Troubleshooting

### Check Service Status
```bash
# Check all pods
kubectl get pods -A

# Check secrets
kubectl get secrets -n ml-pipeline
kubectl get secrets -n monitoring

# Check services
kubectl get svc -A
```

### Verify Credentials
```bash
# Test Harbor connection
kubectl run test-pod --image=harbor.example.com/ml-team/test:latest --dry-run=client -o yaml

# Test SonarQube connection
curl -u "admin:admin123" https://sonarqube.example.com/api/system/status

# Test Prometheus connection
curl https://prometheus.example.com/api/v1/status/config
```

### Common Issues
1. **Invalid Credentials**: Check secret values and URLs
2. **Network Issues**: Verify service endpoints and ports
3. **Permission Issues**: Check RBAC and service accounts
4. **Certificate Issues**: Verify SSL certificates and trust

## 📞 Support

- **Documentation**: See `README.md`
- **Issues**: Create GitHub issues
- **Slack**: `#ml-pipeline` channel
- **Email**: `ml-team@example.com`

---

**⚠️ Important**: Replace all sample credentials with your actual production values before deploying to production environments!
