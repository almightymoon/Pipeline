#!/bin/bash
# ===========================================================
# Create Custom Dashboards for ML Pipeline
# ===========================================================

set -e

echo "=========================================="
echo "📊 Creating Custom Dashboards"
echo "=========================================="

# 1. Create Grafana Dashboard for ML Pipeline
echo ""
echo "[1/3] Creating Grafana ML Pipeline Dashboard..."

cat <<'DASHBOARD' | kubectl create configmap ml-pipeline-dashboard -n monitoring --from-file=dashboard.json=/dev/stdin --dry-run=client -o yaml | kubectl apply -f -
{
  "dashboard": {
    "title": "ML Pipeline Monitoring",
    "uid": "ml-pipeline-monitoring",
    "tags": ["ml", "pipeline", "tekton"],
    "timezone": "browser",
    "schemaVersion": 16,
    "version": 1,
    "refresh": "5s",
    "panels": [
      {
        "id": 1,
        "title": "Pipeline Runs (Last 24h)",
        "type": "stat",
        "gridPos": {"h": 8, "w": 6, "x": 0, "y": 0},
        "targets": [{
          "expr": "count(kube_pod_labels{namespace=\"ml-pipeline\",label_tekton_dev_pipelineRun!=\"\"})",
          "legendFormat": "Total Runs"
        }],
        "fieldConfig": {
          "defaults": {
            "color": {"mode": "thresholds"},
            "thresholds": {
              "mode": "absolute",
              "steps": [
                {"value": 0, "color": "green"},
                {"value": 10, "color": "yellow"},
                {"value": 20, "color": "red"}
              ]
            }
          }
        }
      },
      {
        "id": 2,
        "title": "Success Rate",
        "type": "gauge",
        "gridPos": {"h": 8, "w": 6, "x": 6, "y": 0},
        "targets": [{
          "expr": "(count(kube_pod_status_phase{namespace=\"ml-pipeline\",phase=\"Succeeded\"}) or vector(0)) / (count(kube_pod_status_phase{namespace=\"ml-pipeline\"}) or vector(1)) * 100",
          "legendFormat": "Success %"
        }],
        "fieldConfig": {
          "defaults": {
            "unit": "percent",
            "min": 0,
            "max": 100,
            "thresholds": {
              "mode": "absolute",
              "steps": [
                {"value": 0, "color": "red"},
                {"value": 70, "color": "yellow"},
                {"value": 90, "color": "green"}
              ]
            }
          }
        }
      },
      {
        "id": 3,
        "title": "Active Pipeline Pods",
        "type": "stat",
        "gridPos": {"h": 8, "w": 6, "x": 12, "y": 0},
        "targets": [{
          "expr": "count(kube_pod_status_phase{namespace=\"ml-pipeline\",phase=\"Running\"})",
          "legendFormat": "Running"
        }]
      },
      {
        "id": 4,
        "title": "Failed Pipelines",
        "type": "stat",
        "gridPos": {"h": 8, "w": 6, "x": 18, "y": 0},
        "targets": [{
          "expr": "count(kube_pod_status_phase{namespace=\"ml-pipeline\",phase=\"Failed\"})",
          "legendFormat": "Failed"
        }],
        "fieldConfig": {
          "defaults": {
            "color": {"mode": "thresholds"},
            "thresholds": {
              "mode": "absolute",
              "steps": [
                {"value": 0, "color": "green"},
                {"value": 1, "color": "yellow"},
                {"value": 5, "color": "red"}
              ]
            }
          }
        }
      },
      {
        "id": 5,
        "title": "CPU Usage (ml-pipeline namespace)",
        "type": "graph",
        "gridPos": {"h": 9, "w": 12, "x": 0, "y": 8},
        "targets": [{
          "expr": "sum(rate(container_cpu_usage_seconds_total{namespace=\"ml-pipeline\"}[5m])) by (pod)",
          "legendFormat": "{{pod}}"
        }],
        "yaxes": [
          {"format": "short", "label": "CPU Cores"},
          {"format": "short"}
        ]
      },
      {
        "id": 6,
        "title": "Memory Usage (ml-pipeline namespace)",
        "type": "graph",
        "gridPos": {"h": 9, "w": 12, "x": 12, "y": 8},
        "targets": [{
          "expr": "sum(container_memory_usage_bytes{namespace=\"ml-pipeline\"}) by (pod)",
          "legendFormat": "{{pod}}"
        }],
        "yaxes": [
          {"format": "bytes", "label": "Memory"},
          {"format": "short"}
        ]
      },
      {
        "id": 7,
        "title": "Pipeline Execution Timeline",
        "type": "table",
        "gridPos": {"h": 9, "w": 24, "x": 0, "y": 17},
        "targets": [{
          "expr": "kube_pod_info{namespace=\"ml-pipeline\"}",
          "format": "table",
          "instant": true
        }],
        "transformations": [
          {
            "id": "organize",
            "options": {
              "excludeByName": {},
              "indexByName": {},
              "renameByName": {
                "pod": "Pipeline Run",
                "node": "Node",
                "created_by_name": "Created By"
              }
            }
          }
        ]
      }
    ],
    "time": {
      "from": "now-6h",
      "to": "now"
    },
    "timepicker": {
      "refresh_intervals": ["5s", "10s", "30s", "1m", "5m"]
    }
  }
}
DASHBOARD

# Label the ConfigMap so Grafana picks it up
kubectl label configmap ml-pipeline-dashboard -n monitoring grafana_dashboard=1 --overwrite

echo "✅ Grafana dashboard created"

# 2. Create ArgoCD Application
echo ""
echo "[2/3] Creating ArgoCD Application..."

cat <<EOF | kubectl apply -f -
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: ml-pipeline
  namespace: argocd
  labels:
    app: ml-pipeline
spec:
  project: default
  source:
    repoURL: https://github.com/almightymoon/Pipeline.git
    targetRevision: main
    path: k8s
  destination:
    server: https://kubernetes.default.svc
    namespace: ml-pipeline
  syncPolicy:
    automated:
      prune: false
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
  info:
    - name: 'Jira Project'
      value: 'https://faniqueprimus.atlassian.net/browse/KAN'
    - name: 'Grafana Dashboard'
      value: 'http://213.109.162.134:30102/d/ml-pipeline-monitoring'
EOF

echo "✅ ArgoCD application created"

# 3. Create Enhanced Jira Integration with Pipeline Events
echo ""
echo "[3/3] Creating Enhanced Jira Integration..."

# Create pipeline start notification task
cat <<'EOF' | kubectl apply -f -
apiVersion: tekton.dev/v1beta1
kind: Task
metadata:
  name: jira-pipeline-started
  namespace: ml-pipeline
spec:
  params:
    - name: pipeline-name
      type: string
    - name: git-url
      type: string
    - name: git-revision
      type: string
  steps:
    - name: notify-start
      image: python:3.9-slim
      script: |
        #!/usr/bin/env python3
        import os, json
        from urllib import request
        from base64 import b64encode
        
        jira_url = os.environ["JIRA_URL"].rstrip("/")
        auth = b64encode(f"{os.environ['JIRA_USERNAME']}:{os.environ['JIRA_API_TOKEN']}".encode()).decode()
        
        data = {
            "fields": {
                "project": {"key": os.environ["JIRA_PROJECT"]},
                "summary": f"🚀 Pipeline Started: $(params.pipeline-name)",
                "description": f"""Pipeline execution started.
                
*Details:*
- Pipeline: $(params.pipeline-name)
- Repository: $(params.git-url)
- Branch: $(params.git-revision)
- Status: IN PROGRESS

*Monitor:*
- Grafana: http://213.109.162.134:30102
- ArgoCD: http://213.109.162.134:32146
""",
                "issuetype": {"name": "Task"},
                "priority": {"name": "Low"},
                "labels": ["pipeline", "automated", "in-progress"]
            }
        }
        
        req = request.Request(
            f"{jira_url}/rest/api/2/issue",
            data=json.dumps(data).encode(),
            headers={"Authorization": f"Basic {auth}", "Content-Type": "application/json"},
            method="POST"
        )
        
        try:
            with request.urlopen(req) as resp:
                issue = json.loads(resp.read())
                print(f"✅ Jira issue created: {issue['key']}")
                print(f"URL: {jira_url}/browse/{issue['key']}")
                # Save issue key for later updates
                with open("/tekton/results/issue-key", "w") as f:
                    f.write(issue['key'])
        except Exception as e:
            print(f"⚠️  Warning: Could not create Jira issue: {e}")
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
  results:
    - name: issue-key
      description: Created Jira issue key
---
apiVersion: tekton.dev/v1beta1
kind: Task
metadata:
  name: jira-report-bugs
  namespace: ml-pipeline
spec:
  params:
    - name: pipeline-name
      type: string
    - name: test-results
      type: string
    - name: failed-tests
      type: string
  steps:
    - name: report-bugs
      image: python:3.9-slim
      script: |
        #!/usr/bin/env python3
        import os, json
        from urllib import request
        from base64 import b64encode
        
        jira_url = os.environ["JIRA_URL"].rstrip("/")
        auth = b64encode(f"{os.environ['JIRA_USERNAME']}:{os.environ['JIRA_API_TOKEN']}".encode()).decode()
        
        failed_tests = "$(params.failed-tests)"
        
        if failed_tests and failed_tests != "0":
            data = {
                "fields": {
                    "project": {"key": os.environ["JIRA_PROJECT"]},
                    "summary": f"🐛 Test Failures in $(params.pipeline-name)",
                    "description": f"""Test failures detected in pipeline execution.

*Test Results:*
$(params.test-results)

*Failed Tests:* {failed_tests}

*Action Required:*
- Review test logs
- Fix failing tests
- Re-run pipeline

*Pipeline:* $(params.pipeline-name)
*Dashboards:*
- Grafana: http://213.109.162.134:30102
- ArgoCD: http://213.109.162.134:32146
""",
                    "issuetype": {"name": "Bug"},
                    "priority": {"name": "High"},
                    "labels": ["bug", "test-failure", "automated"]
                }
            }
            
            req = request.Request(
                f"{jira_url}/rest/api/2/issue",
                data=json.dumps(data).encode(),
                headers={"Authorization": f"Basic {auth}", "Content-Type": "application/json"},
                method="POST"
            )
            
            try:
                with request.urlopen(req) as resp:
                    issue = json.loads(resp.read())
                    print(f"🐛 Bug reported: {issue['key']}")
                    print(f"URL: {jira_url}/browse/{issue['key']}")
            except Exception as e:
                print(f"⚠️  Could not create bug: {e}")
        else:
            print("✅ No bugs to report - all tests passed!")
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

echo "✅ Jira tasks created"

# 4. Update enhanced pipeline with full Jira integration
echo ""
echo "[4/4] Updating pipeline with complete Jira integration..."

cat <<'EOF' | kubectl apply -f -
apiVersion: tekton.dev/v1beta1
kind: Pipeline
metadata:
  name: full-integrated-pipeline
  namespace: ml-pipeline
  annotations:
    description: "Complete pipeline with Grafana, ArgoCD, and Jira integration"
spec:
  description: "ML Pipeline with full observability and issue tracking"
  workspaces:
    - name: shared-data
  params:
    - name: git-url
      type: string
      default: "https://github.com/almightymoon/Pipeline.git"
    - name: git-revision
      type: string
      default: "main"
    - name: image-registry
      type: string
      default: "harbor.example.com/ml-team"
    - name: image-tag
      type: string
      default: "latest"
    - name: project-type
      type: string
      default: "python"
  
  tasks:
    # STEP 1: Notify Jira - Pipeline Started
    - name: jira-notify-start
      taskRef:
        name: jira-pipeline-started
      params:
        - name: pipeline-name
          value: "$(context.pipelineRun.name)"
        - name: git-url
          value: "$(params.git-url)"
        - name: git-revision
          value: "$(params.git-revision)"
    
    # STEP 2: Clone Repository
    - name: git-clone
      runAfter: [jira-notify-start]
      taskRef:
        name: enhanced-git-clone
      params:
        - name: url
          value: "$(params.git-url)"
        - name: revision
          value: "$(params.git-revision)"
      workspaces:
        - name: output
          workspace: shared-data
    
    # STEP 3: Build
    - name: build-image
      runAfter: [git-clone]
      taskRef:
        name: enhanced-build
      params:
        - name: image
          value: "$(params.image-registry):$(params.image-tag)"
        - name: project-type
          value: "$(params.project-type)"
      workspaces:
        - name: source
          workspace: shared-data
    
    # STEP 4: Test & Report Bugs
    - name: test-application
      runAfter: [build-image]
      taskRef:
        name: enhanced-test
      params:
        - name: project-type
          value: "$(params.project-type)"
      workspaces:
        - name: source
          workspace: shared-data
    
    # STEP 5: Report Test Bugs to Jira
    - name: jira-report-bugs
      runAfter: [test-application]
      taskRef:
        name: jira-report-bugs
      params:
        - name: pipeline-name
          value: "$(context.pipelineRun.name)"
        - name: test-results
          value: "$(tasks.test-application.results.test-results)"
        - name: failed-tests
          value: "1"  # From test results
    
    # STEP 6: Send Metrics
    - name: send-metrics
      runAfter: [test-application]
      taskRef:
        name: send-metrics
      params:
        - name: pipeline-name
          value: "$(context.pipelineRun.name)"
        - name: status
          value: "success"
        - name: duration
          value: "60"
  
  finally:
    # Always run: Update Jira on completion
    - name: jira-update-success
      when:
        - input: "$(tasks.status)"
          operator: notin
          values: ["Failed"]
      taskRef:
        name: jira-notify
      params:
        - name: summary
          value: "✅ Pipeline $(context.pipelineRun.name) Completed Successfully"
        - name: description
          value: |
            Pipeline completed successfully!
            
            Results:
            - Tests: $(tasks.test-application.results.test-results)
            - Coverage: $(tasks.test-application.results.coverage)%
            - Commit: $(tasks.git-clone.results.commit)
            
            View details:
            - Grafana: http://213.109.162.134:30102
            - ArgoCD: http://213.109.162.134:32146
        - name: priority
          value: "Low"
    
    # Notify on failure
    - name: jira-report-failure
      when:
        - input: "$(tasks.status)"
          operator: in
          values: ["Failed"]
      taskRef:
        name: jira-notify
      params:
        - name: summary
          value: "❌ URGENT: Pipeline $(context.pipelineRun.name) FAILED"
        - name: description
          value: |
            Pipeline execution FAILED - immediate attention required!
            
            Failed Tasks: Check logs
            
            Investigation steps:
            1. Check Grafana for resource issues
            2. Review logs: tkn pipelinerun logs $(context.pipelineRun.name) -n ml-pipeline
            3. Verify ArgoCD sync status
            
            Dashboards:
            - Grafana: http://213.109.162.134:30102
            - ArgoCD: http://213.109.162.134:32146
        - name: priority
          value: "Critical"
EOF

echo "✅ Full integrated pipeline created"

echo ""
echo "=========================================="
echo "✅ Dashboard Setup Complete!"
echo "=========================================="
echo ""
echo "Created:"
echo "  ✓ Grafana ML Pipeline Dashboard"
echo "  ✓ ArgoCD Application (ml-pipeline)"
echo "  ✓ Jira pipeline-started notifications"
echo "  ✓ Jira bug reporting on test failures"
echo "  ✓ Jira success/failure updates"
echo ""
echo "Access:"
echo "  Grafana: http://213.109.162.134:30102"
echo "  ArgoCD:  http://213.109.162.134:32146"
echo "  Jira:    https://faniqueprimus.atlassian.net/browse/KAN"
echo ""

