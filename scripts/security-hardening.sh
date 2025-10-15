#!/bin/bash
# ===========================================================
# Security Hardening Script for ML Pipeline
# This script helps secure the pipeline by removing hardcoded credentials
# ===========================================================

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔒 ML Pipeline Security Hardening${NC}"
echo "=================================="

# Function to generate secure password
generate_password() {
    openssl rand -base64 32 | tr -d "=+/" | cut -c1-25
}

# Function to check if environment variable is set
check_env_var() {
    local var_name="$1"
    if [ -z "${!var_name:-}" ]; then
        echo -e "${RED}❌ $var_name is not set${NC}"
        return 1
    else
        echo -e "${GREEN}✅ $var_name is set${NC}"
        return 0
    fi
}

echo -e "${YELLOW}📋 Checking required environment variables...${NC}"

# Required environment variables
REQUIRED_VARS=(
    "KEYCLOAK_ADMIN_PASSWORD"
    "KEYCLOAK_DB_PASSWORD"
    "GRAFANA_PASSWORD"
    "HARBOR_PASSWORD"
    "SONARQUBE_TOKEN"
    "JIRA_API_TOKEN"
    "JIRA_EMAIL"
    "KUBECONFIG"
)

missing_vars=()
for var in "${REQUIRED_VARS[@]}"; do
    if ! check_env_var "$var"; then
        missing_vars+=("$var")
    fi
done

if [ ${#missing_vars[@]} -gt 0 ]; then
    echo -e "${RED}❌ Missing required environment variables:${NC}"
    for var in "${missing_vars[@]}"; do
        echo -e "   - $var"
    done
    
    echo -e "\n${YELLOW}🔧 Generating secure passwords for missing variables...${NC}"
    
    # Generate secure passwords
    if [[ " ${missing_vars[@]} " =~ " KEYCLOAK_ADMIN_PASSWORD " ]]; then
        export KEYCLOAK_ADMIN_PASSWORD=$(generate_password)
        echo "KEYCLOAK_ADMIN_PASSWORD=$KEYCLOAK_ADMIN_PASSWORD"
    fi
    
    if [[ " ${missing_vars[@]} " =~ " KEYCLOAK_DB_PASSWORD " ]]; then
        export KEYCLOAK_DB_PASSWORD=$(generate_password)
        echo "KEYCLOAK_DB_PASSWORD=$KEYCLOAK_DB_PASSWORD"
    fi
    
    if [[ " ${missing_vars[@]} " =~ " GRAFANA_PASSWORD " ]]; then
        export GRAFANA_PASSWORD=$(generate_password)
        echo "GRAFANA_PASSWORD=$GRAFANA_PASSWORD"
    fi
    
    if [[ " ${missing_vars[@]} " =~ " HARBOR_PASSWORD " ]]; then
        export HARBOR_PASSWORD=$(generate_password)
        echo "HARBOR_PASSWORD=$HARBOR_PASSWORD"
    fi
    
    echo -e "\n${YELLOW}⚠️  Please set the remaining variables manually:${NC}"
    for var in "${missing_vars[@]}"; do
        if [[ ! " $var " =~ " KEYCLOAK_ADMIN_PASSWORD|KEYCLOAK_DB_PASSWORD|GRAFANA_PASSWORD|HARBOR_PASSWORD " ]]; then
            echo "export $var=\"your-secure-value-here\""
        fi
    done
fi

echo -e "\n${YELLOW}🔍 Scanning for hardcoded credentials...${NC}"

# Find hardcoded credentials
hardcoded_files=()
if grep -r "admin123" . --exclude-dir=.git --exclude="*.md" --exclude="security-hardening.sh" >/dev/null 2>&1; then
    echo -e "${RED}❌ Found hardcoded 'admin123' passwords${NC}"
    hardcoded_files+=("admin123")
fi

if grep -r "password" . --exclude-dir=.git --exclude="*.md" --exclude="security-hardening.sh" | grep -v "PASSWORD\|password:" | grep -v "export.*password" >/dev/null 2>&1; then
    echo -e "${RED}❌ Found potential hardcoded passwords${NC}"
    hardcoded_files+=("password")
fi

if grep -r "213.109.162.134" . --exclude-dir=.git --exclude="*.md" --exclude="security-hardening.sh" >/dev/null 2>&1; then
    echo -e "${RED}❌ Found hardcoded IP addresses${NC}"
    hardcoded_files+=("hardcoded-ip")
fi

if [ ${#hardcoded_files[@]} -eq 0 ]; then
    echo -e "${GREEN}✅ No hardcoded credentials found${NC}"
else
    echo -e "${YELLOW}⚠️  Please review and replace hardcoded values with environment variables${NC}"
fi

echo -e "\n${YELLOW}🛡️  Security recommendations:${NC}"
echo "1. Use strong, unique passwords for each service"
echo "2. Rotate credentials regularly"
echo "3. Use secrets management (Vault, Kubernetes secrets)"
echo "4. Enable audit logging"
echo "5. Use HTTPS/TLS for all communications"
echo "6. Implement proper access controls"
echo "7. Regular security scans and updates"

echo -e "\n${GREEN}✅ Security hardening check completed${NC}"
