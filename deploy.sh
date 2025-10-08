#!/bin/bash
# ===========================================================
# ML Pipeline Deployment Script
# ===========================================================

set -e

echo "🚀 Starting ML Pipeline Deployment..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
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

# Check if kubectl is available
check_kubectl() {
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl is not installed. Please install kubectl first."
        exit 1
    fi
    print_success "kubectl is available"
}

# Check if helm is available
check_helm() {
    if ! command -v helm &> /dev/null; then
        print_warning "helm is not installed. Some features may not work."
    else
        print_success "helm is available"
    fi
}

# Check Kubernetes cluster connection
check_cluster() {
    if ! kubectl cluster-info &> /dev/null; then
        print_error "Cannot connect to Kubernetes cluster. Please check your kubeconfig."
        exit 1
    fi
    print_success "Connected to Kubernetes cluster"
}

# Install Tekton Pipelines
install_tekton() {
    print_status "Installing Tekton Pipelines..."
    
    # Check if Tekton is already installed
    if kubectl get crd pipelineruns.tekton.dev &> /dev/null; then
        print_success "Tekton Pipelines already installed"
        return
    fi
    
    kubectl apply -f https://storage.googleapis.com/tekton-releases/pipeline/latest/release.yaml
    
    # Wait for Tekton to be ready
    print_status "Waiting for Tekton Pipelines to be ready..."
    kubectl wait --for=condition=ready pod -l app=tekton-pipelines-controller -n tekton-pipelines --timeout=300s
    kubectl wait --for=condition=ready pod -l app=tekton-pipelines-webhook -n tekton-pipelines --timeout=300s
    
    print_success "Tekton Pipelines installed successfully"
}

# Install Tekton Tasks
install_tekton_tasks() {
    print_status "Installing Tekton Tasks..."
    
    # Install git-clone task
    kubectl apply -f https://raw.githubusercontent.com/tektoncd/catalog/main/task/git-clone/0.9/git-clone.yaml
    
    # Install buildah task
    kubectl apply -f https://raw.githubusercontent.com/tektoncd/catalog/main/task/buildah/0.6/buildah.yaml
    
    print_success "Tekton Tasks installed successfully"
}

# Create namespaces
create_namespaces() {
    print_status "Creating namespaces..."
    kubectl apply -f k8s/namespace.yaml
    print_success "Namespaces created successfully"
}

# Deploy GPU operator (if available)
deploy_gpu_operator() {
    print_status "Checking GPU operator..."
    
    # Check if NVIDIA GPU operator is available
    if helm repo list | grep -q nvidia; then
        print_status "Installing NVIDIA GPU Operator..."
        helm repo add nvidia https://helm.ngc.nvidia.com/nvidia
        helm repo update
        helm install --wait gpu-operator nvidia/gpu-operator --namespace gpu-operator --create-namespace
        print_success "NVIDIA GPU Operator installed"
    else
        print_warning "NVIDIA GPU Operator not available. GPU features will be limited."
    fi
}

# Deploy the main pipeline
deploy_pipeline() {
    print_status "Deploying ML Pipeline..."
    kubectl apply -f pipeline.yml
    print_success "ML Pipeline deployed successfully"
}

# Deploy Kubernetes manifests
deploy_k8s_manifests() {
    print_status "Deploying Kubernetes manifests..."
    
    # Deploy GPU operator configuration
    if [ -f "k8s/gpu-operator.yaml" ]; then
        kubectl apply -f k8s/gpu-operator.yaml
    fi
    
    # Deploy training job configuration
    if [ -f "k8s/ml-training-job.yaml" ]; then
        kubectl apply -f k8s/ml-training-job.yaml
    fi
    
    # Deploy Triton inference server
    if [ -f "k8s/triton-inference.yaml" ]; then
        kubectl apply -f k8s/triton-inference.yaml
    fi
    
    print_success "Kubernetes manifests deployed successfully"
}

# Deploy monitoring
deploy_monitoring() {
    print_status "Deploying monitoring configuration..."
    
    if [ -f "monitoring/prometheus-rules.yaml" ]; then
        kubectl apply -f monitoring/prometheus-rules.yaml
    fi
    
    print_success "Monitoring configuration deployed successfully"
}

# Create sample secrets
create_secrets() {
    print_status "Creating sample secrets..."
    
    # Create Harbor registry secret (sample)
    kubectl create secret docker-registry harbor-creds \
        --docker-server=harbor.example.com \
        --docker-username=admin \
        --docker-password=password \
        --namespace=ml-pipeline \
        --dry-run=client -o yaml | kubectl apply -f -
    
    # Create Vault token secret (sample)
    kubectl create secret generic vault-token \
        --from-literal=token=sample-vault-token \
        --namespace=ml-pipeline \
        --dry-run=client -o yaml | kubectl apply -f -
    
    # Create SonarQube token secret (sample)
    kubectl create secret generic sonar-token \
        --from-literal=token=sample-sonar-token \
        --namespace=ml-pipeline \
        --dry-run=client -o yaml | kubectl apply -f -
    
    print_success "Sample secrets created successfully"
}

# Create sample PipelineRun
create_sample_pipeline_run() {
    print_status "Creating sample PipelineRun..."
    
    cat <<EOF | kubectl apply -f -
apiVersion: tekton.dev/v1beta1
kind: PipelineRun
metadata:
  name: ml-pipeline-demo-\$(date +%s)
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
      value: "demo-\$(date +%Y%m%d-%H%M%S)"
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
    
    print_success "Sample PipelineRun created successfully"
}

# Show pipeline status
show_status() {
    print_status "Pipeline Status:"
    echo ""
    echo "📋 Namespaces:"
    kubectl get namespaces | grep ml-
    echo ""
    echo "🔧 Pipelines:"
    kubectl get pipelines -n ml-pipeline
    echo ""
    echo "🏃 PipelineRuns:"
    kubectl get pipelineruns -n ml-pipeline
    echo ""
    echo "📦 Tasks:"
    kubectl get tasks -n ml-pipeline
    echo ""
    echo "🔑 Secrets:"
    kubectl get secrets -n ml-pipeline
}

# Main deployment function
main() {
    echo "=========================================="
    echo "🚀 ML Pipeline Deployment Script"
    echo "=========================================="
    echo ""
    
    # Pre-flight checks
    check_kubectl
    check_helm
    check_cluster
    
    echo ""
    print_status "Starting deployment process..."
    echo ""
    
    # Deploy components
    install_tekton
    install_tekton_tasks
    create_namespaces
    deploy_gpu_operator
    deploy_pipeline
    deploy_k8s_manifests
    deploy_monitoring
    create_secrets
    
    echo ""
    print_success "🎉 Deployment completed successfully!"
    echo ""
    
    # Show status
    show_status
    
    echo ""
    print_status "Next steps:"
    echo "1. Update secrets with real values:"
    echo "   kubectl edit secret harbor-creds -n ml-pipeline"
    echo "   kubectl edit secret vault-token -n ml-pipeline"
    echo ""
    echo "2. Run a sample pipeline:"
    echo "   ./deploy.sh --run-sample"
    echo ""
    echo "3. Monitor pipeline execution:"
    echo "   kubectl get pipelineruns -n ml-pipeline -w"
    echo ""
    echo "4. View pipeline logs:"
    echo "   kubectl logs -f <pipeline-run-name> -n ml-pipeline"
    echo ""
}

# Handle command line arguments
case "${1:-}" in
    --run-sample)
        create_sample_pipeline_run
        ;;
    --status)
        show_status
        ;;
    --help)
        echo "Usage: $0 [--run-sample|--status|--help]"
        echo ""
        echo "Options:"
        echo "  --run-sample    Create and run a sample pipeline"
        echo "  --status        Show current pipeline status"
        echo "  --help          Show this help message"
        echo ""
        ;;
    *)
        main
        ;;
esac
