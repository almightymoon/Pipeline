#!/bin/bash
# ===========================================================
# Complete ML Pipeline Setup with All Access Credentials
# ===========================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${PURPLE}==========================================${NC}"
    echo -e "${PURPLE}$1${NC}"
    echo -e "${PURPLE}==========================================${NC}"
}

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to prompt for credentials
prompt_for_credentials() {
    print_header "🔐 Setting Up Access Credentials"
    echo ""
    echo "This script will help you configure access credentials for all pipeline services."
    echo "You can either:"
    echo "1. Use the sample credentials (for testing)"
    echo "2. Provide your own credentials"
    echo ""
    read -p "Do you want to use sample credentials for testing? (y/n): " use_sample
    
    if [[ $use_sample == "y" || $use_sample == "Y" ]]; then
        print_warning "Using sample credentials for testing purposes"
        USE_SAMPLE=true
    else
        print_status "You'll be prompted for real credentials"
        USE_SAMPLE=false
    fi
}

# Function to create custom secrets with user input
create_custom_secrets() {
    if [[ $USE_SAMPLE == true ]]; then
        print_status "Creating secrets with sample credentials..."
        kubectl apply -f credentials/all-services-secrets.yaml
        return
    fi
    
    print_status "Creating secrets with custom credentials..."
    
    # Harbor Registry
    echo ""
    print_status "Harbor Registry Configuration:"
    read -p "Harbor URL (default: harbor.example.com): " HARBOR_URL
    HARBOR_URL=${HARBOR_URL:-harbor.example.com}
    read -p "Harbor Username (default: admin): " HARBOR_USER
    HARBOR_USER=${HARBOR_USER:-admin}
    read -s -p "Harbor Password: " HARBOR_PASS
    echo ""
    
    # SonarQube
    echo ""
    print_status "SonarQube Configuration:"
    read -p "SonarQube URL (default: https://sonarqube.example.com): " SONAR_URL
    SONAR_URL=${SONAR_URL:-https://sonarqube.example.com}
    read -s -p "SonarQube Token: " SONAR_TOKEN
    echo ""
    
    # Jira
    echo ""
    print_status "Jira Configuration:"
    read -p "Jira URL (default: https://jira.example.com): " JIRA_URL
    JIRA_URL=${JIRA_URL:-https://jira.example.com}
    read -p "Jira Username/Email: " JIRA_USER
    read -s -p "Jira API Token: " JIRA_TOKEN
    echo ""
    
    # Prometheus
    echo ""
    print_status "Prometheus Configuration:"
    read -p "Prometheus URL (default: https://prometheus.example.com): " PROMETHEUS_URL
    PROMETHEUS_URL=${PROMETHEUS_URL:-https://prometheus.example.com}
    
    # Grafana
    echo ""
    print_status "Grafana Configuration:"
    read -p "Grafana URL (default: https://grafana.example.com): " GRAFANA_URL
    GRAFANA_URL=${GRAFANA_URL:-https://grafana.example.com}
    read -s -p "Grafana Admin Password: " GRAFANA_PASS
    echo ""
    
    # Slack
    echo ""
    print_status "Slack Integration (optional):"
    read -p "Slack Webhook URL (leave empty to skip): " SLACK_WEBHOOK
    
    # Create custom secrets
    create_harbor_secret "$HARBOR_URL" "$HARBOR_USER" "$HARBOR_PASS"
    create_sonar_secret "$SONAR_URL" "$SONAR_TOKEN"
    create_jira_secret "$JIRA_URL" "$JIRA_USER" "$JIRA_TOKEN"
    create_monitoring_secrets "$PROMETHEUS_URL" "$GRAFANA_URL" "$GRAFANA_PASS"
    if [[ -n "$SLACK_WEBHOOK" ]]; then
        create_slack_secret "$SLACK_WEBHOOK"
    fi
}

# Function to create Harbor secret
create_harbor_secret() {
    local url=$1
    local user=$2
    local pass=$3
    
    local auth=$(echo -n "$user:$pass" | base64)
    local config="{\"auths\":{\"$url\":{\"username\":\"$user\",\"password\":\"$pass\",\"auth\":\"$auth\"}}}"
    local encoded_config=$(echo -n "$config" | base64)
    
    for namespace in ml-pipeline ml-staging ml-production; do
        kubectl create secret docker-registry harbor-creds \
            --docker-server="$url" \
            --docker-username="$user" \
            --docker-password="$pass" \
            --namespace="$namespace" \
            --dry-run=client -o yaml | kubectl apply -f -
    done
}

# Function to create SonarQube secret
create_sonar_secret() {
    local url=$1
    local token=$2
    
    for namespace in ml-pipeline ml-staging ml-production; do
        kubectl create secret generic sonar-token \
            --from-literal=token="$token" \
            --from-literal=url="$url" \
            --namespace="$namespace" \
            --dry-run=client -o yaml | kubectl apply -f -
    done
}

# Function to create Jira secret
create_jira_secret() {
    local url=$1
    local user=$2
    local token=$3
    
    for namespace in ml-pipeline ml-staging ml-production; do
        kubectl create secret generic jira-credentials \
            --from-literal=url="$url" \
            --from-literal=username="$user" \
            --from-literal=api_token="$token" \
            --namespace="$namespace" \
            --dry-run=client -o yaml | kubectl apply -f -
    done
}

# Function to create monitoring secrets
create_monitoring_secrets() {
    local prometheus_url=$1
    local grafana_url=$2
    local grafana_pass=$3
    
    # Prometheus secret
    kubectl create secret generic prometheus-creds \
        --from-literal=url="$prometheus_url" \
        --from-literal=username="admin" \
        --from-literal=password="admin123" \
        --namespace="monitoring" \
        --dry-run=client -o yaml | kubectl apply -f -
    
    # Grafana secret
    kubectl create secret generic grafana-creds \
        --from-literal=url="$grafana_url" \
        --from-literal=admin_username="admin" \
        --from-literal=admin_password="$grafana_pass" \
        --namespace="monitoring" \
        --dry-run=client -o yaml | kubectl apply -f -
}

# Function to create Slack secret
create_slack_secret() {
    local webhook_url=$1
    
    for namespace in ml-pipeline ml-staging ml-production; do
        kubectl create secret generic slack-creds \
            --from-literal=webhook_url="$webhook_url" \
            --from-literal=channel="#ml-pipeline" \
            --from-literal=username="ML Pipeline Bot" \
            --namespace="$namespace" \
            --dry-run=client -o yaml | kubectl apply -f -
    done
}

# Function to deploy monitoring stack
deploy_monitoring_stack() {
    print_header "📊 Deploying Monitoring Stack"
    
    print_status "Creating monitoring namespace..."
    kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -
    
    print_status "Deploying Prometheus configuration..."
    kubectl apply -f credentials/prometheus-config.yaml
    
    print_status "Deploying Grafana configuration..."
    kubectl apply -f credentials/grafana-config.yaml
    
    print_status "Deploying Prometheus rules..."
    kubectl apply -f monitoring/prometheus-rules.yaml
    
    print_success "Monitoring stack deployed successfully"
}

# Function to create sample PipelineRun
create_sample_pipeline_run() {
    print_header "🚀 Creating Sample Pipeline Run"
    
    local pipeline_name="ml-pipeline-demo-$(date +%s)"
    
    cat <<EOF | kubectl apply -f -
apiVersion: tekton.dev/v1beta1
kind: PipelineRun
metadata:
  name: ${pipeline_name}
  namespace: ml-pipeline
spec:
  pipelineRef:
    name: enterprise-ml-pipeline
  params:
    - name: git-url
      value: "https://github.com/tektoncd/pipeline.git"
    - name: project-type
      value: "python"
    - name: gpu-count
      value: "1"
    - name: enable-model-parallelism
      value: "false"
    - name: image-registry
      value: "harbor.example.com/ml-team"
    - name: image-tag
      value: "demo-$(date +%Y%m%d-%H%M%S)"
  workspaces:
    - name: shared-data
      volumeClaimTemplate:
        spec:
          accessModes:
            - ReadWriteOnce
          resources:
            requests:
              storage: 5Gi
    - name: docker-credentials
      secret:
        secretName: harbor-creds
    - name: vault-secrets
      secret:
        secretName: vault-token
EOF
    
    print_success "Sample PipelineRun created: ${pipeline_name}"
    
    echo ""
    print_status "To monitor the pipeline:"
    echo "kubectl get pipelinerun ${pipeline_name} -n ml-pipeline -w"
    echo ""
    echo "To view logs:"
    echo "kubectl logs -f pipelinerun/${pipeline_name} -n ml-pipeline"
}

# Function to show service URLs and credentials
show_service_info() {
    print_header "🔗 Service Access Information"
    
    echo ""
    print_status "Service URLs and Access Information:"
    echo ""
    
    echo "📊 Monitoring Services:"
    echo "  - Prometheus: https://prometheus.example.com"
    echo "  - Grafana: https://grafana.example.com (admin/admin123)"
    echo "  - OpenSearch: https://opensearch.example.com"
    echo ""
    
    echo "🔒 Security Services:"
    echo "  - SonarQube: https://sonarqube.example.com"
    echo "  - DefectDojo: https://defectdojo.example.com"
    echo "  - Dependency Track: https://dependency-track.example.com"
    echo ""
    
    echo "📦 Registry & Storage:"
    echo "  - Harbor: https://harbor.example.com"
    echo "  - Nexus: https://nexus.example.com"
    echo ""
    
    echo "📋 Project Management:"
    echo "  - Jira: https://jira.example.com"
    echo ""
    
    echo "🔧 Infrastructure:"
    echo "  - Vault: https://vault.example.com"
    echo "  - Kubernetes Dashboard: kubectl proxy"
    echo ""
    
    echo "📱 Notifications:"
    echo "  - Slack: #ml-pipeline channel"
    echo "  - Email: ml-pipeline@example.com"
    echo ""
    
    print_warning "Remember to update the URLs and credentials with your actual values!"
}

# Main setup function
main() {
    print_header "🚀 ML Pipeline Complete Setup with Credentials"
    echo ""
    
    # Check prerequisites
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl is not installed. Please install kubectl first."
        exit 1
    fi
    
    if ! kubectl cluster-info &> /dev/null; then
        print_error "Cannot connect to Kubernetes cluster. Please check your kubeconfig."
        exit 1
    fi
    
    print_success "Prerequisites check passed"
    echo ""
    
    # Prompt for credentials
    prompt_for_credentials
    
    # Deploy the pipeline
    print_header "🏗️ Deploying ML Pipeline"
    ./deploy.sh
    
    # Create secrets
    create_custom_secrets
    
    # Deploy monitoring
    deploy_monitoring_stack
    
    # Show service information
    show_service_info
    
    # Create sample run
    if [[ "${1:-}" == "--run-sample" ]]; then
        create_sample_pipeline_run
    fi
    
    print_header "🎉 Setup Complete!"
    echo ""
    print_success "Your ML Pipeline is now ready with all access credentials!"
    echo ""
    print_status "Next steps:"
    echo "1. Update service URLs in the secrets with your actual values"
    echo "2. Test the pipeline with: ./run-pipeline.sh python https://github.com/your-repo.git"
    echo "3. Monitor via Grafana: https://grafana.example.com"
    echo "4. Check pipeline status: kubectl get pipelineruns -n ml-pipeline"
    echo ""
    print_status "For help, run: ./setup-with-credentials.sh --help"
}

# Handle command line arguments
case "${1:-}" in
    --run-sample)
        main --run-sample
        ;;
    --help|-h)
        echo "Usage: $0 [--run-sample|--help]"
        echo ""
        echo "Options:"
        echo "  --run-sample    Create and run a sample pipeline after setup"
        echo "  --help          Show this help message"
        echo ""
        echo "This script will:"
        echo "1. Set up access credentials for all pipeline services"
        echo "2. Deploy the complete ML pipeline"
        echo "3. Configure monitoring and security tools"
        echo "4. Create necessary secrets and configurations"
        echo ""
        ;;
    *)
        main
        ;;
esac
