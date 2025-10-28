# Automatic Termination from Jira - Webhook Setup

## How It Will Work

```
Click Link in Jira → Triggers Webhook Server → Calls GitHub API → Workflow Runs → Deployment Terminated! ✅
```

## Setup Instructions

### Step 1: Create GitHub Personal Access Token

1. Go to: https://github.com/settings/tokens/new
2. Name: `Pipeline Termination`
3. Scopes: Check **"workflow"**
4. Click "Generate token"
5. **Copy the token** (you'll only see it once!)

### Step 2: Add GitHub Token as Secret

1. Go to: https://github.com/almightymoon/Pipeline/settings/secrets/actions
2. Click "New repository secret"
3. Name: `GITHUB_TOKEN`
4. Value: (paste your token)
5. Click "Add secret"

### Step 3: Deploy the Webhook Server

On your VPS (213.109.162.134):

```bash
# SSH into your VPS
ssh ubuntu@213.109.162.134

# Navigate to pipeline directory
cd /path/to/Pipeline

# Install dependencies
pip3 install flask flask-cors requests

# Set your GitHub token
export GITHUB_TOKEN="your_token_here"

# Run the webhook server
python3 scripts/terminate_webhook_server.py &

# Or better, run as a service
# Create systemd service or use screen/tmux
```

### Step 4: Update Jira Links to Use Webhook

The Jira scripts need to point to your webhook server. The URL should be:
```
http://213.109.162.134:5000/terminate?repository=my-app&deployment=my-app-deployment&namespace=production
```

### Step 5: Configure Port Access

Make sure port 5000 is accessible:

```bash
# On your VPS
sudo ufw allow 5000
```

## How to Use

Once set up:
1. Click the termination link in Jira
2. Webhook server receives the request
3. Server calls GitHub API with authentication
4. GitHub Actions workflow runs automatically
5. Deployment terminated! ✅

## Architecture

```
Jira Issue
    ↓ [Click Terminate Link]
Webhook Server (tha213.109.162.134:5000)
    ↓ [Authenticated API Call]
GitHub Actions API
    ↓ [Triggers Workflow]
Auto Terminate Deployment Workflow
    ↓ [Runs]
Kubernetes Cluster
    ↓ [kubectl delete]
Deployment Terminated ✅
```

## Security

- GitHub token is stored securely in the webhook server
- Token has limited permissions (workflow only)
- Webhook server validates requests
- Can add authentication to webhook server if needed

## Testing

Test the webhook manually:

```bash
curl "http://213.109.162.134:5000/terminate?repository=my-app&deployment=my-app-deployment&namespace=pipeline-apps"
```

Should return:
```json
{
  "success": true,
  "message": "Workflow triggered successfully",
  "status": "termination_triggered"
}
```

## Troubleshooting

### Webhook not working?
1. Check if webhook server is running: `ps aux | grep terminate_webhook_server.py`
2. Check port 5000 is accessible: `curl http://213.109.162.134:5000/health`
3. Check logs: Look at the webhook server output

### Workflow not triggering?
1. Verify GitHub token has `workflow` scope
2. Check token is set in webhook server
3. Check GitHub Actions log for API errors

