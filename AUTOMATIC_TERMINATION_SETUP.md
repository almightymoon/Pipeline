# Automatic Termination Setup Guide

## Overview

This setup allows you to **automatically terminate deployments with one click** from Jira without going through GitHub manually.

## How It Works

1. You click the termination link in Jira
2. A simple webhook server triggers the GitHub Actions workflow
3. GitHub Actions automatically terminates the Kubernetes deployment
4. Done! ✅

## Setup Instructions

### Step 1: Create GitHub Personal Access Token

1. Go to: https://github.com/settings/tokens/new
2. Name: `Pipeline Termination Token`
3. Scopes: Check `workflow` 
4. Click "Generate token"
5. **Copy the token** (you won't see it again!)

### Step 2: Deploy the Webhook Server

#### Option A: Run on Your VPS

```bash
# SSH into your VPS
ssh ubuntu@213.109.162.134

# Install dependencies
pip3 install flask flask-cors requests

# Set your GitHub token
export GITHUB_TOKEN="your_token_here"

# Run the server
cd /path/to/pipeline-copy
python3 scripts/terminate_webhook_server.py

# Or run in background
nohup python3 scripts/terminate_webhook_server.py &
```

#### Option B: Deploy as Kubernetes Service

```bash
# Create a Kubernetes deployment
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: terminate-webhook
  namespace: default
spec:
  replicas: 1
  selector:
    matchLabels:
      app: terminate-webhook
  template:
    metadata:
      labels:
        app: terminate-webhook
    spec:
      containers:
      - name: webhook
        image: python:3.9-slim
        command: ["python", "-m", "http.server", "5000"]
        env:
        - name: GITHUB_TOKEN
          valueFrom:
            secretKeyRef:
              name: github-token
              key: token
EOF

# Create service
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: terminate-webhook
  namespace: default
spec:
  type: NodePort
  ports:
  - port: 5000
    nodePort: 30500
  selector:
    app: terminate-webhook
EOF
```

### Step 3: Update Jira Links

The Jira scripts are now configured to use the direct GitHub API endpoint.

### Step 4: Create GitHub Secret (if needed)

```bash
# In your GitHub repository settings
# Settings → Secrets and variables → Actions
# Add secret: GITHUB_TOKEN
```

## How to Use

### From Jira Issue:

1. **Click the termination link** in the Jira issue
2. **Select "Run workflow"** in the GitHub Actions UI
3. **Done!** The deployment is automatically terminated

### Direct API Call (Alternative):

You can also trigger termination via curl:

```bash
curl -X POST \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Accept: application/vnd.github+json" \
  https://api.github.com/repos/almightymoon/Pipeline/dispatches \
  -d '{
    "event_type": "terminate_deployment",
    "client_payload": {
      "repository": "my-app",
      "deployment": "my-app-deployment",
      "namespace": "pipeline-apps"
    }
  }'
```

## Architecture

```
Jira Issue
    ↓ [Click Terminate Link]
GitHub Actions UI (Manual Run)
    ↓ [Run Workflow button]
Auto Terminate Workflow
    ↓ [Repository Dispatch Event]
Kubernetes Cluster
    ↓ [kubectl delete]
Deployment Terminated ✅
```

## Files Created

1. **`.github/workflows/auto-terminate-deployment.yml`** - Automatic termination workflow
2. **`scripts/terminate_webhook_server.py`** - Webhook server (optional, for future automation)

## Security Notes

- ⚠️ GitHub Personal Access Token has limited scope (`workflow` only)
- ✅ Can only trigger workflows in your repository
- ✅ Cannot access code or secrets
- ✅ Token should be stored securely

## Troubleshooting

### Workflow not triggering?

1. Check if `GITHUB_TOKEN` secret is set
2. Verify token has `workflow` scope
3. Check workflow file syntax is correct
4. Check GitHub Actions logs for errors

### Deployment not terminating?

1. Check Kubernetes connectivity
2. Verify namespace name is correct
3. Check if deployment exists in that namespace
4. Look at workflow logs for kubectl errors

## Next Steps

Once working, you can:
- Add webhook server for true automatic termination
- Add Slack notifications on termination
- Add Jira ticket update on termination
- Add metrics for termination events

