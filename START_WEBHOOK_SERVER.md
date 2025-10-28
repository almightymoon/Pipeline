# Start the Webhook Server for Automatic Termination

## Quick Setup

Run these commands on your VPS:

```bash
# 1. SSH into your VPS
ssh ubuntu@213.109.162.134

# 2. Install Python dependencies
pip3 install flask flask-cors requests

# 3. Get your GitHub Personal Access Token
# Go to: https://github.com/settings/tokens/new
# Scope: Check "workflow" only
# Copy the token

# 4. Set the token as environment variable
export GITHUB_TOKEN="your_token_here"

# 5. Navigate to your pipeline directory
cd /path/to/pipeline-copy

# 6. Run the webhook server
python3 scripts/terminate_webhook_server.py

# The server will start on port 5000
```

## Run in Background

To keep it running:

```bash
# Using nohup
nohup python3 scripts/terminate_webhook_server.py > webhook.log 2>&1 &

# Or use screen
screen -S webhook
python3 scripts/terminate_webhook_server.py
# Press Ctrl+A then D to detach

# Or use systemd (create a service)
# TODO: Add systemd service file
```

## Test It

Once running, test with:

```bash
curl "http://213.109.162.134:5000/terminate?repository=test&deployment=test-deployment&namespace=pipeline-apps"
```

Should return JSON with success status.

## How It Works

```
Click link in Jira → Webhook Server → GitHub API → Workflow Runs → Terminated! ✅
```

## What You Need

- ✅ Python 3 with flask, flask-cors, requests
- ✅ GitHub Personal Access Token (workflow scope)
- ✅ Port 5000 accessible on VPS
- ✅ Webhook server running

## Security

The webhook server:
- Only triggers GitHub Actions workflows
- Requires your GitHub token
- Can add authentication later if needed
- Token has limited permissions (workflow only)

Once you start the webhook server, the Jira links will work automatically! 🎉

