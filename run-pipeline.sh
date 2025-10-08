#!/bin/bash
# ===========================================================
# Quick Pipeline Runner
# ===========================================================

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Function to create and run a pipeline
run_pipeline() {
    local project_type=$1
    local git_url=$2
    local gpu_count=${3:-1}
    local enable_parallelism=${4:-false}
    
    local pipeline_name="ml-pipeline-${project_type}-$(date +%s)"
    
    print_status "Creating PipelineRun: ${pipeline_name}"
    
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
      value: "${git_url}"
    - name: project-type
      value: "${project_type}"
    - name: gpu-count
      value: "${gpu_count}"
    - name: enable-model-parallelism
      value: "${enable_parallelism}"
    - name: image-registry
      value: "harbor.example.com/ml-team"
    - name: image-tag
      value: "${project_type}-$(date +%Y%m%d-%H%M%S)"
  workspaces:
    - name: shared-data
      volumeClaimTemplate:
        spec:
          accessModes:
            - ReadWriteOnce
          resources:
            requests:
              storage: 10Gi
    - name: docker-credentials
      secret:
        secretName: harbor-creds
    - name: vault-secrets
      secret:
        secretName: vault-token
EOF
    
    print_success "PipelineRun created: ${pipeline_name}"
    
    # Show status
    echo ""
    print_status "Pipeline Status:"
    kubectl get pipelinerun ${pipeline_name} -n ml-pipeline
    
    echo ""
    print_status "To monitor the pipeline:"
    echo "kubectl get pipelinerun ${pipeline_name} -n ml-pipeline -w"
    echo ""
    echo "To view logs:"
    echo "kubectl logs -f pipelinerun/${pipeline_name} -n ml-pipeline"
}

# Show usage
show_usage() {
    echo "Usage: $0 <project-type> <git-url> [gpu-count] [enable-parallelism]"
    echo ""
    echo "Project Types:"
    echo "  python    - Python application"
    echo "  java      - Java application"
    echo "  ml        - ML/AI project"
    echo "  multi     - Multi-language project"
    echo ""
    echo "Examples:"
    echo "  $0 python https://github.com/tektoncd/pipeline.git"
    echo "  $0 ml https://github.com/huggingface/transformers.git 2 true"
    echo "  $0 java https://github.com/spring-projects/spring-boot.git 1 false"
    echo ""
}

# Main script
case "${1:-}" in
    python|java|ml|multi)
        if [ -z "${2:-}" ]; then
            echo "Error: Git URL is required"
            show_usage
            exit 1
        fi
        run_pipeline "$1" "$2" "${3:-1}" "${4:-false}"
        ;;
    --help|-h)
        show_usage
        ;;
    *)
        echo "Error: Invalid project type: ${1:-}"
        show_usage
        exit 1
        ;;
esac
