# How to Use the Termination Workflow

## Quick Guide

### Step 1: Go to the Workflow
Visit: https://github.com/almightymoon/Pipeline/actions/workflows/auto-terminate-deployment.yml

### Step 2: Click "Run workflow" Button
Look for the blue "Run workflow" dropdown button on the right side of the page.

### Step 3: Fill in the Parameters
- **Repository**: Name of your app (e.g., `my-app`)
- **Deployment**: Deployment name (e.g., `my-app-deployment`)
- **Namespace**: Kubernetes namespace (e.g., `pipeline-apps`)

### Step 4: Click Green "Run workflow"
The workflow will automatically terminate your Kubernetes deployment!

## Finding the Correct Values

To get the correct parameters, check your Jira issue:
- **Repository**: The "name" field in your deployment
- **Deployment**: Usually `name-deployment` (e.g., `my-app-deployment`)
- **Namespace**: Usually `pipeline-apps` for scan-repos or the namespace you specified in images-to-deploy.yaml

## Alternative: Use the Links

The Jira links will open the workflow page. Even though you still need to click "Run workflow", the parameters will be pre-filled in the URL!

Example URL from Jira:
```
https://github.com/almightymoon/Pipeline/actions/workflows/auto-terminate-deployment.yml?repository=my-app&deployment=my-app-deployment&namespace=production
```

After opening this link:
1. Click "Run workflow"
2. The parameters might already be filled!
3. Click "Run workflow" button
4. Done!

