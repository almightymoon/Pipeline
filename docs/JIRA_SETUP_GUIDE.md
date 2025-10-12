# 🔗 Jira Integration Setup Guide

## 📋 What You Need

Before integrating Jira, you need the following information:

### For Jira Cloud (Atlassian)
1. **Jira URL**: `https://your-company.atlassian.net`
2. **Email**: Your Atlassian account email
3. **API Token**: Generate at https://id.atlassian.com/manage-profile/security/api-tokens
4. **Project Key**: Your project key (e.g., "ML", "PROJ", "DEV")

### For Jira Server/Data Center
1. **Jira URL**: `https://jira.your-company.com`
2. **Username**: Your Jira username
3. **Password or Personal Access Token**
4. **Project Key**: Your project key

---

## 🎯 Quick Setup (3 Steps)

### Step 1: Get Your Jira API Token

**For Jira Cloud:**
1. Go to https://id.atlassian.com/manage-profile/security/api-tokens
2. Click "Create API token"
3. Give it a name like "ML Pipeline Integration"
4. Copy the token (you can't see it again!)

**For Jira Server:**
1. Log into your Jira instance
2. Go to Profile → Personal Access Tokens
3. Create a new token with appropriate permissions
4. Copy the token

### Step 2: Run the Setup Script

**Option A: Interactive Setup**
```bash
ssh ubuntu@213.109.162.134
# Password: qwert1234

cd ~/Pipeline
./setup-jira-integration.sh
```

Follow the prompts to enter:
- Jira URL
- Username/Email
- API Token
- Project Key
- (Optional) Slack webhook

**Option B: Manual Configuration**

Edit and run this script on the server:

```bash
ssh ubuntu@213.109.162.134

# Set your values
export JIRA_URL="https://your-company.atlassian.net"
export JIRA_USERNAME="your-email@company.com"
export JIRA_API_TOKEN="your-api-token-here"
export JIRA_PROJECT="ML"

# Store in Vault
kubectl exec -it vault-0 -n vault -- vault kv put secret/ml-pipeline/jira \
    url="$JIRA_URL" \
    username="$JIRA_USERNAME" \
    api_token="$JIRA_API_TOKEN" \
    project_key="$JIRA_PROJECT"

# Create Kubernetes secret
kubectl create secret generic jira-credentials \
    --namespace=ml-pipeline \
    --from-literal=jira-url="$JIRA_URL" \
    --from-literal=jira-username="$JIRA_USERNAME" \
    --from-literal=jira-api-token="$JIRA_API_TOKEN" \
    --from-literal=jira-project-key="$JIRA_PROJECT"

# Deploy configuration
kubectl apply -f integrations/jira-config.yaml

# Create Jira task (the notification task)
kubectl apply -f ~/Pipeline/jira-task.yaml  # Created by setup script
```

### Step 3: Test the Integration

```bash
# Test creating a Jira issue
kubectl create -f - <<EOF
apiVersion: tekton.dev/v1beta1
kind: TaskRun
metadata:
  name: jira-test-$(date +%s)
  namespace: ml-pipeline
spec:
  taskRef:
    name: jira-notify
  params:
    - name: summary
      value: "Test Issue from ML Pipeline"
    - name: description
      value: "This is a test issue to verify Jira integration is working correctly."
    - name: priority
      value: "Low"
EOF

# Check the task execution
kubectl get taskruns -n ml-pipeline | grep jira-test

# View logs
kubectl logs -f $(kubectl get pods -n ml-pipeline -l tekton.dev/taskRun --sort-by=.metadata.creationTimestamp -o name | tail -1) -n ml-pipeline
```

If successful, you'll see:
```
✓ Created: https://your-jira.atlassian.net/browse/ML-XXX
```

---

## 🔧 How to Use in Pipelines

### Add Jira Notification to Your Pipeline

Edit your pipeline to add Jira notifications on failure:

```yaml
apiVersion: tekton.dev/v1beta1
kind: Pipeline
metadata:
  name: my-ml-pipeline
  namespace: ml-pipeline
spec:
  # ... your pipeline tasks ...
  
  finally:
    - name: notify-jira-on-failure
      when:
        - input: "$(tasks.status)"
          operator: in
          values: ["Failed"]
      taskRef:
        name: jira-notify
      params:
        - name: summary
          value: "Pipeline $(context.pipelineRun.name) Failed"
        - name: description
          value: |
            Pipeline: $(context.pipeline.name)
            Run: $(context.pipelineRun.name)
            Status: FAILED
            
            Check logs: kubectl logs pipelinerun/$(context.pipelineRun.name) -n ml-pipeline
        - name: priority
          value: "High"
```

### Example: Notify on Test Failure

```yaml
- name: run-tests
  taskRef:
    name: test-application
  # ... task config ...

- name: notify-test-failure
  runAfter: [run-tests]
  when:
    - input: "$(tasks.run-tests.status)"
      operator: in
      values: ["Failed"]
  taskRef:
    name: jira-notify
  params:
    - name: summary
      value: "Test Failures in $(params.pipeline-name)"
    - name: description
      value: "Automated tests failed. Review test results and fix issues."
    - name: priority
      value: "Medium"
```

---

## 📊 What Gets Created in Jira

When the pipeline creates a Jira issue, it includes:

**Standard Fields:**
- **Summary**: Brief description of the issue
- **Description**: Detailed information
- **Issue Type**: Task (configurable)
- **Priority**: High/Medium/Low
- **Project**: Your specified project key
- **Reporter**: API user

**Custom Fields** (if configured):
- Pipeline name
- Pipeline status  
- Pipeline duration
- GPU utilization
- Model accuracy
- Test coverage

---

## 🔔 Slack Integration (Optional)

If you also want Slack notifications:

1. Create a Slack webhook:
   - Go to https://api.slack.com/apps
   - Create an app → Incoming Webhooks
   - Copy the webhook URL

2. During setup, enable Slack and provide:
   - Webhook URL
   - Channel name (e.g., `#ml-pipeline`)

3. Test Slack notification:
```bash
kubectl create -f - <<EOF
apiVersion: tekton.dev/v1beta1
kind: TaskRun
metadata:
  name: slack-test-$(date +%s)
  namespace: ml-pipeline
spec:
  taskRef:
    name: slack-notify
  params:
    - name: message
      value: "Test message from ML Pipeline"
    - name: pipeline-name
      value: "test-pipeline"
    - name: status
      value: "success"
EOF
```

---

## 🎯 Common Use Cases

### 1. Notify on Pipeline Failure
```yaml
- name: notify-failure
  taskRef:
    name: jira-notify
  params:
    - name: summary
      value: "ML Pipeline Failed: $(params.pipeline-name)"
    - name: description
      value: "Pipeline execution failed. Immediate attention required."
    - name: priority
      value: "Critical"
```

### 2. Report Model Performance Issues
```yaml
- name: check-model-performance
  # ... check performance ...
  
- name: report-performance-issue
  when:
    - input: "$(tasks.check-model-performance.results.accuracy)"
      operator: notin
      values: ["0.8", "0.9", "1.0"]
  taskRef:
    name: jira-notify
  params:
    - name: summary
      value: "Model Performance Degradation Detected"
    - name: description
      value: "Model accuracy dropped below threshold. Current: $(tasks.check-model-performance.results.accuracy)"
    - name: priority
      value: "High"
```

### 3. Dataset Quality Alerts
```yaml
- name: notify-dataset-issue
  taskRef:
    name: jira-notify
  params:
    - name: summary
      value: "Dataset Quality Issue: $(params.dataset-name)"
    - name: description
      value: "Data quality checks failed. Review dataset before training."
    - name: priority
      value: "Medium"
```

---

## 🔍 Troubleshooting

### Issue: "Failed to create Jira issue: 401 Unauthorized"
**Solution:** Check your credentials:
```bash
kubectl get secret jira-credentials -n ml-pipeline -o yaml
# Verify the credentials are correct
```

### Issue: "Failed to create Jira issue: 404 Not Found"
**Solution:** Verify the Jira URL and project key:
```bash
# Test the URL manually
curl -u "your-email:your-token" https://your-jira.atlassian.net/rest/api/2/project/ML
```

### Issue: Task fails with "Invalid project key"
**Solution:** Ensure the project exists and you have access:
```bash
# List all projects you have access to
curl -u "your-email:your-token" https://your-jira.atlassian.net/rest/api/2/project
```

### Issue: Custom fields not working
**Solution:** Get the actual custom field IDs from Jira:
```bash
# Get field IDs
curl -u "your-email:your-token" \
  https://your-jira.atlassian.net/rest/api/2/field | jq '.[] | select(.custom==true)'
```

---

## 📚 Advanced Configuration

### Auto-Close Issues on Success

Create a task to transition issues when pipelines succeed:

```yaml
apiVersion: tekton.dev/v1beta1
kind: Task
metadata:
  name: jira-close-issue
  namespace: ml-pipeline
spec:
  params:
    - name: issue-key
      type: string
  steps:
    - name: close-issue
      image: curlimages/curl:latest
      script: |
        #!/bin/sh
        curl -X POST \
          -H "Authorization: Basic $(echo -n $JIRA_USER:$JIRA_TOKEN | base64)" \
          -H "Content-Type: application/json" \
          -d '{"transition":{"id":"31"}}' \
          $JIRA_URL/rest/api/2/issue/$(params.issue-key)/transitions
      env:
        - name: JIRA_URL
          valueFrom:
            secretKeyRef:
              name: jira-credentials
              key: jira-url
        - name: JIRA_USER
          valueFrom:
            secretKeyRef:
              name: jira-credentials
              key: jira-username
        - name: JIRA_TOKEN
          valueFrom:
            secretKeyRef:
              name: jira-credentials
              key: jira-api-token
```

### Link GitHub Commits to Jira

Add commit info to Jira descriptions:
```yaml
- name: description
  value: |
    Pipeline: $(context.pipeline.name)
    Commit: $(params.git-revision)
    Author: $(params.git-author)
    
    GitHub: https://github.com/yourorg/repo/commit/$(params.git-revision)
```

---

## ✅ Checklist

Before going live, verify:

- [ ] Jira credentials are stored in Vault
- [ ] Kubernetes secret `jira-credentials` exists
- [ ] Test task run creates a Jira issue successfully
- [ ] Pipeline includes Jira notifications
- [ ] Slack integration tested (if enabled)
- [ ] Team members are added to Jira project
- [ ] Notification rules are configured
- [ ] SLA settings are appropriate

---

## 🎉 You're All Set!

Your ML Pipeline can now:
- ✅ Create Jira issues automatically on failures
- ✅ Report model performance issues
- ✅ Track dataset quality problems
- ✅ Alert on GPU/infrastructure issues
- ✅ Send Slack notifications (if enabled)
- ✅ Integrate with your team's workflow

**Next Steps:**
1. Provide your Jira credentials
2. Run the setup script
3. Test the integration
4. Add notifications to your pipelines
5. Monitor and refine based on team feedback

