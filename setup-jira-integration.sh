#!/bin/bash
# ===========================================================
# Jira Integration Setup for ML Pipeline
# ===========================================================

set -e

echo "=========================================="
echo "🔗 Setting Up Jira Integration"
echo "=========================================="
echo ""

# Function to read user input
read_input() {
    local prompt="$1"
    local var_name="$2"
    local default="$3"
    
    if [ -n "$default" ]; then
        read -p "$prompt [$default]: " value
        eval $var_name="${value:-$default}"
    else
        read -p "$prompt: " value
        eval $var_name="$value"
    fi
}

# Collect Jira configuration
echo "📝 Jira Configuration"
echo "---------------------"
read_input "Jira Server URL" JIRA_URL "https://your-company.atlassian.net"
read_input "Jira Username/Email" JIRA_USERNAME ""
read -s -p "Jira API Token (hidden): " JIRA_API_TOKEN
echo ""
read_input "Jira Project Key" JIRA_PROJECT "ML"
echo ""

# Optional: Slack integration
echo ""
echo "📝 Slack Integration (Optional)"
echo "-------------------------------"
read_input "Enable Slack notifications? (y/n)" ENABLE_SLACK "n"

if [ "$ENABLE_SLACK" = "y" ]; then
    read_input "Slack Webhook URL" SLACK_WEBHOOK ""
    read_input "Slack Channel" SLACK_CHANNEL "#ml-pipeline"
fi
echo ""

# Store secrets in Vault
echo "[1/5] Storing Jira credentials in Vault..."
kubectl exec -it vault-0 -n vault -- vault kv put secret/ml-pipeline/jira \
    url="$JIRA_URL" \
    username="$JIRA_USERNAME" \
    api_token="$JIRA_API_TOKEN" \
    project_key="$JIRA_PROJECT"

if [ "$ENABLE_SLACK" = "y" ]; then
    kubectl exec -it vault-0 -n vault -- vault kv put secret/ml-pipeline/slack \
        webhook_url="$SLACK_WEBHOOK" \
        channel="$SLACK_CHANNEL"
fi

echo "✓ Credentials stored in Vault"

# Create Jira integration secret
echo ""
echo "[2/5] Creating Kubernetes secrets..."
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: jira-credentials
  namespace: ml-pipeline
type: Opaque
stringData:
  jira-url: "$JIRA_URL"
  jira-username: "$JIRA_USERNAME"
  jira-api-token: "$JIRA_API_TOKEN"
  jira-project-key: "$JIRA_PROJECT"
EOF

if [ "$ENABLE_SLACK" = "y" ]; then
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: slack-credentials
  namespace: ml-pipeline
type: Opaque
stringData:
  webhook-url: "$SLACK_WEBHOOK"
  channel: "$SLACK_CHANNEL"
EOF
fi

echo "✓ Kubernetes secrets created"

# Deploy Jira integration config
echo ""
echo "[3/5] Deploying Jira integration configuration..."
kubectl apply -f integrations/jira-config.yaml

echo "✓ Jira config deployed"

# Create Jira integration task
echo ""
echo "[4/5] Creating Jira integration Tekton task..."
cat <<EOF | kubectl apply -f -
apiVersion: tekton.dev/v1beta1
kind: Task
metadata:
  name: jira-notify
  namespace: ml-pipeline
spec:
  params:
    - name: issue-type
      type: string
      default: "pipeline_failure"
    - name: summary
      type: string
    - name: description
      type: string
    - name: priority
      type: string
      default: "High"
    - name: pipeline-name
      type: string
      default: ""
    - name: pipeline-status
      type: string
      default: ""
  steps:
    - name: create-jira-issue
      image: python:3.9-slim
      script: |
        #!/usr/bin/env python3
        import os
        import json
        import sys
        from urllib import request
        from base64 import b64encode
        
        # Get parameters
        issue_type = "$(params.issue-type)"
        summary = "$(params.summary)"
        description = "$(params.description)"
        priority = "$(params.priority)"
        pipeline_name = "$(params.pipeline-name)"
        pipeline_status = "$(params.pipeline-status)"
        
        # Get credentials from environment
        jira_url = os.environ.get('JIRA_URL', '').rstrip('/')
        jira_username = os.environ.get('JIRA_USERNAME')
        jira_token = os.environ.get('JIRA_API_TOKEN')
        jira_project = os.environ.get('JIRA_PROJECT', 'ML')
        
        if not all([jira_url, jira_username, jira_token]):
            print("❌ Missing Jira credentials")
            sys.exit(1)
        
        # Create Jira issue
        auth_string = f"{jira_username}:{jira_token}"
        auth_bytes = auth_string.encode('ascii')
        auth_b64 = b64encode(auth_bytes).decode('ascii')
        
        issue_data = {
            "fields": {
                "project": {"key": jira_project},
                "summary": summary,
                "description": description,
                "issuetype": {"name": "Task"},
                "priority": {"name": priority}
            }
        }
        
        # Add custom fields if available
        if pipeline_name:
            issue_data["fields"]["customfield_10001"] = pipeline_name
        if pipeline_status:
            issue_data["fields"]["customfield_10002"] = pipeline_status
        
        headers = {
            'Authorization': f'Basic {auth_b64}',
            'Content-Type': 'application/json'
        }
        
        req = request.Request(
            f'{jira_url}/rest/api/2/issue',
            data=json.dumps(issue_data).encode('utf-8'),
            headers=headers,
            method='POST'
        )
        
        try:
            with request.urlopen(req) as response:
                result = json.loads(response.read().decode('utf-8'))
                issue_key = result.get('key')
                print(f"✓ Created Jira issue: {issue_key}")
                print(f"  URL: {jira_url}/browse/{issue_key}")
        except Exception as e:
            print(f"❌ Failed to create Jira issue: {e}")
            sys.exit(1)
      env:
        - name: JIRA_URL
          valueFrom:
            secretKeyRef:
              name: jira-credentials
              key: jira-url
        - name: JIRA_USERNAME
          valueFrom:
            secretKeyRef:
              name: jira-credentials
              key: jira-username
        - name: JIRA_API_TOKEN
          valueFrom:
            secretKeyRef:
              name: jira-credentials
              key: jira-api-token
        - name: JIRA_PROJECT
          valueFrom:
            secretKeyRef:
              name: jira-credentials
              key: jira-project-key
EOF

echo "✓ Jira task created"

# Create Slack notification task (if enabled)
if [ "$ENABLE_SLACK" = "y" ]; then
echo ""
echo "[5/5] Creating Slack notification task..."
cat <<EOF | kubectl apply -f -
apiVersion: tekton.dev/v1beta1
kind: Task
metadata:
  name: slack-notify
  namespace: ml-pipeline
spec:
  params:
    - name: message
      type: string
    - name: pipeline-name
      type: string
      default: ""
    - name: status
      type: string
      default: ""
  steps:
    - name: send-slack-message
      image: curlimages/curl:latest
      script: |
        #!/bin/sh
        
        MESSAGE="$(params.message)"
        PIPELINE_NAME="$(params.pipeline-name)"
        STATUS="$(params.status)"
        WEBHOOK_URL="\$SLACK_WEBHOOK_URL"
        CHANNEL="\$SLACK_CHANNEL"
        
        # Determine color based on status
        if [ "\$STATUS" = "success" ]; then
            COLOR="good"
            EMOJI="✅"
        elif [ "\$STATUS" = "failed" ]; then
            COLOR="danger"
            EMOJI="❌"
        else
            COLOR="warning"
            EMOJI="⚠️"
        fi
        
        # Create Slack message
        PAYLOAD=$(cat <<PAYLOAD_EOF
        {
            "channel": "\$CHANNEL",
            "username": "ML Pipeline Bot",
            "icon_emoji": ":robot_face:",
            "attachments": [{
                "color": "\$COLOR",
                "title": "\$EMOJI \$PIPELINE_NAME",
                "text": "\$MESSAGE",
                "fields": [
                    {
                        "title": "Status",
                        "value": "\$STATUS",
                        "short": true
                    },
                    {
                        "title": "Pipeline",
                        "value": "\$PIPELINE_NAME",
                        "short": true
                    }
                ],
                "footer": "ML Pipeline",
                "ts": $(date +%s)
            }]
        }
PAYLOAD_EOF
        )
        
        curl -X POST -H 'Content-type: application/json' --data "\$PAYLOAD" "\$WEBHOOK_URL"
      env:
        - name: SLACK_WEBHOOK_URL
          valueFrom:
            secretKeyRef:
              name: slack-credentials
              key: webhook-url
        - name: SLACK_CHANNEL
          valueFrom:
            secretKeyRef:
              name: slack-credentials
              key: channel
EOF

echo "✓ Slack task created"
fi

echo ""
echo "=========================================="
echo "✅ Jira Integration Setup Complete!"
echo "=========================================="
echo ""
echo "📊 Configuration Summary:"
echo "  Jira URL: $JIRA_URL"
echo "  Jira Project: $JIRA_PROJECT"
echo "  Jira Username: $JIRA_USERNAME"
if [ "$ENABLE_SLACK" = "y" ]; then
echo "  Slack Channel: $SLACK_CHANNEL"
fi
echo ""
echo "🔑 Credentials stored in:"
echo "  - Vault: secret/ml-pipeline/jira"
echo "  - Kubernetes Secret: jira-credentials"
echo ""
echo "📋 Available Tekton Tasks:"
echo "  - jira-notify: Create Jira issues from pipelines"
if [ "$ENABLE_SLACK" = "y" ]; then
echo "  - slack-notify: Send Slack notifications"
fi
echo ""
echo "📚 Usage Example:"
cat <<'USAGE'

# Add to your pipeline:
- name: notify-on-failure
  taskRef:
    name: jira-notify
  params:
    - name: summary
      value: "Pipeline $(params.pipeline-name) failed"
    - name: description
      value: "Pipeline execution failed. Check logs for details."
    - name: priority
      value: "High"
    - name: pipeline-name
      value: "$(params.pipeline-name)"
    - name: pipeline-status
      value: "failed"

USAGE

echo ""
echo "🔗 Test the integration:"
echo "  kubectl create -f - <<EOF"
echo "  apiVersion: tekton.dev/v1beta1"
echo "  kind: TaskRun"
echo "  metadata:"
echo "    name: jira-test"
echo "    namespace: ml-pipeline"
echo "  spec:"
echo "    taskRef:"
echo "      name: jira-notify"
echo "    params:"
echo "      - name: summary"
echo "        value: 'Test Issue from ML Pipeline'"
echo "      - name: description"
echo "        value: 'This is a test issue created by the ML Pipeline integration'"
echo "      - name: priority"
echo "        value: 'Low'"
echo "  EOF"
echo ""

