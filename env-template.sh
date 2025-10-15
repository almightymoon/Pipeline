#!/bin/bash
# ===========================================================
# Environment Configuration Template
# Copy this file to .env and fill in your actual values
# ===========================================================

# ===========================================================
# REQUIRED ENVIRONMENT VARIABLES
# ===========================================================

# Grafana Configuration
export GRAFANA_URL="http://your-server:30102"
export GRAFANA_USERNAME="admin"
export GRAFANA_PASSWORD="your-secure-grafana-password"

# Keycloak Configuration
export KEYCLOAK_URL="http://your-server:8080"
export KEYCLOAK_ADMIN_USERNAME="admin"
export KEYCLOAK_ADMIN_PASSWORD="your-secure-keycloak-password"
export KEYCLOAK_DB_PASSWORD="your-secure-db-password"

# Harbor Registry Configuration
export HARBOR_URL="http://your-server"
export HARBOR_USERNAME="admin"
export HARBOR_PASSWORD="your-secure-harbor-password"

# SonarQube Configuration
export SONARQUBE_URL="http://your-server:9000"
export SONARQUBE_TOKEN="your-sonarqube-token"

# Jira Configuration
export JIRA_URL="http://your-server:8080"
export JIRA_EMAIL="your-email@company.com"
export JIRA_API_TOKEN="your-jira-api-token"
export JIRA_PROJECT_KEY="MLP"

# Kubernetes Configuration
export K8S_SERVER_URL="https://your-k8s-server:6443"
export KUBECONFIG="your-base64-encoded-kubeconfig"

# Vault Configuration
export VAULT_URL="http://your-server:8200"
export VAULT_TOKEN="your-vault-token"

# Prometheus Configuration
export PROMETHEUS_URL="http://your-server:9090"
export PROMETHEUS_PUSHGATEWAY_URL="http://your-server:9091"

# ===========================================================
# OPTIONAL ENVIRONMENT VARIABLES
# ===========================================================

# DefectDojo Configuration
export DEFECTDOJO_URL="http://your-server:8080"
export DEFECTDOJO_API_KEY="your-defectdojo-api-key"

# Dependency Track Configuration
export DEPENDENCY_TRACK_URL="http://your-server:8080"
export DEPENDENCY_TRACK_API_KEY="your-dependency-track-api-key"

# Nexus Repository Configuration
export NEXUS_URL="http://your-server:8081"
export NEXUS_USERNAME="admin"
export NEXUS_PASSWORD="your-nexus-password"

# ReportPortal Configuration
export REPORTPORTAL_URL="http://your-server:8080"
export REPORTPORTAL_TOKEN="your-reportportal-token"

# OpenSearch Configuration
export OPENSEARCH_URL="http://your-server:9200"
export OPENSEARCH_USERNAME="admin"
export OPENSEARCH_PASSWORD="your-opensearch-password"

# ArgoCD Configuration
export ARGOCD_URL="http://your-server:32146"
export ARGOCD_USERNAME="admin"
export ARGOCD_PASSWORD="your-argocd-password"

# Slack Configuration (for notifications)
export SLACK_WEBHOOK_URL="https://hooks.slack.com/services/your/slack/webhook"

# ===========================================================
# SECURITY NOTES
# ===========================================================
# 1. Never commit this file with actual credentials
# 2. Use strong, unique passwords for each service
# 3. Rotate credentials regularly
# 4. Use secrets management (Vault, Kubernetes secrets, etc.)
# 5. Enable audit logging for all services
# 6. Use HTTPS/TLS for all communications
# 7. Implement proper access controls and RBAC
# 8. Regular security scans and updates
# 9. Monitor for unauthorized access attempts
# 10. Keep all services updated with latest security patches

# ===========================================================
# USAGE INSTRUCTIONS
# ===========================================================
# 1. Copy this file: cp env-template.sh .env
# 2. Edit .env with your actual values
# 3. Source the file: source .env
# 4. Run security hardening: ./scripts/security-hardening.sh
# 5. Test your configuration: ./scripts/test-configuration.sh
