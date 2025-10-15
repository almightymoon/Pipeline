#!/bin/bash
set -e

echo "========================================="
echo "DEPLOYING TEKTON TASKS TO CLUSTER"
echo "========================================="

# Check for kubectl
if ! command -v kubectl &> /dev/null
then
    echo "❌ kubectl not found. Please install kubectl."
    exit 1
fi

# Check cluster connection
echo "🔍 Checking cluster connection..."
if ! kubectl cluster-info &> /dev/null; then
    echo "❌ Cannot connect to cluster"
    echo "⚠️ Skipping Tekton task deployment - cluster not accessible"
    exit 0
fi
echo "✅ Successfully connected to cluster"

# Create namespace if it doesn't exist
NAMESPACE="ml-pipeline"
if ! kubectl get namespace $NAMESPACE &> /dev/null; then
    echo "Creating namespace $NAMESPACE..."
    kubectl create namespace $NAMESPACE
fi

echo "📦 Deploying Tekton tasks..."

# Apply all Tekton Tasks
kubectl apply -f tekton/tasks/ -n $NAMESPACE

echo "✅ All Tekton tasks deployed successfully"

# List deployed tasks
echo "📋 Deployed tasks:"
kubectl get tasks -n $NAMESPACE

echo "========================================="
echo "TEKTON TASKS DEPLOYMENT COMPLETED"
echo "========================================="
