#!/bin/bash

# Deploy Tekton Pipeline Resources
# This script ensures all Tekton pipelines and tasks are properly deployed

set -e

echo "========================================="
echo "DEPLOYING TEKTON PIPELINE RESOURCES"
echo "========================================="

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl is not installed or not in PATH"
    exit 1
fi

# Check if kubeconfig is available
if [ ! -f "kubeconfig" ]; then
    echo "❌ kubeconfig file not found"
    exit 1
fi

# Set kubeconfig
export KUBECONFIG=$(pwd)/kubeconfig

# Check cluster connection
echo "🔍 Checking cluster connection..."
if ! kubectl cluster-info &> /dev/null; then
    echo "❌ Cannot connect to cluster"
    exit 1
fi

echo "✅ Connected to cluster"

# Create namespace if it doesn't exist
echo "📦 Creating namespace ml-pipeline..."
kubectl create namespace ml-pipeline --dry-run=client -o yaml | kubectl apply -f -

# Deploy Tekton Tasks
echo "🔧 Deploying Tekton Tasks..."
for task_file in tekton/tasks/*.yaml; do
    if [ -f "$task_file" ]; then
        echo "  Deploying $(basename $task_file)..."
        kubectl apply -f "$task_file"
    fi
done

# Deploy Tekton Pipeline
echo "🚀 Deploying Tekton Pipeline..."
kubectl apply -f tekton/pipeline.yaml

# Verify deployment
echo "✅ Verifying deployment..."

echo "📋 Available Pipelines:"
kubectl get pipelines -n ml-pipeline

echo "📋 Available Tasks:"
kubectl get tasks -n ml-pipeline

echo "========================================="
echo "TEKTON RESOURCES DEPLOYED SUCCESSFULLY"
echo "========================================="
echo "Pipeline: ml-pipeline-enterprise"
echo "Namespace: ml-pipeline"
echo "Ready for pipeline execution!"
echo "========================================="
