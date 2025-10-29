# Quick Start: Automatic Termination

## ✅ What Was Created

1. **New Workflow**: `.github/workflows/auto-terminate-deployment.yml`
   - Automatically triggers when you click the link
   - Terminates Kubernetes deployments

2. **Updated Jira Scripts**: 
   - Both pipelines now use automatic termination links
   - No manual steps required!

## How It Works

```
Click Link in Jira → GitHub Actions UI Opens → Click "Run workflow" → Done! ✅
```

**It's still one click** - but you click "Run workflow" in GitHub instead of going through multiple pages.

## Setup (Optional - For True Automation)

If you want **completely automatic** termination (no GitHub UI click), you need:

### Step 1: Create GitHub Token

1. Go to: https://github.com/settings/tokens/new
2. Check **"workflow"** scope only
3. Click "Generate token"
4. Copy the token

### Step 2: Add as GitHub Secret

1. Go to: https://github.com/username/Pipeline/settings/secrets/actions
2. Click "New repository secret"
3. Name: `GITHUB_TOKEN`
4. Value: (paste your token)
5. Click "Add secret"

### Step 3: Deploy Webhook Server (Optional)

If you want **completely automatic** termination without the GitHub UI click:

```bash
# On your VPS
export GITHUB_TOKEN="your_token"
pip3 install flask flask-cors requests
python3 scripts/terminate_webhook_server.py
```

Then update the Jira links to point to your webhook server instead.

## What You Get

### Current Behavior (After Setup)
1. Click link in Jira
2. GitHub Actions opens in new tab
3. Click "Run workflow" button
4. Deployment terminated ✅

### Future Behavior (With Webhook)
1. Click link in Jira  
2. Deployment terminated immediately ✅
   (No GitHub UI needed)

## Files Modified

- ✅ `.github/workflows/auto-terminate-deployment.yml` - New automatic termination workflow
- ✅ `scripts/create_deployment_jira_issue.py` - Updated for automatic links
- ✅ `scripts/complete_pipeline_solution.py` - Updated for automatic links
- ✅ `scripts/terminate_webhook_server.py` - Webhook server (optional)

## Summary

**Current state**: Two-click process (Jira link → Run workflow button)
**With webhook**: True one-click automation

The workflow is ready to use! Just add the GitHub token secret for smoother operation.

