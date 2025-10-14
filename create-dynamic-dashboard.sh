#!/bin/bash

echo "========================================="
echo "Creating Dynamic Dashboard"
echo "========================================="

# Create a dynamic dashboard that updates automatically
cat > monitoring/dynamic-dashboard.json << 'EOF'
{
  "dashboard": {
    "id": null,
    "title": "Pipeline Dashboard - Dynamic",
    "tags": ["pipeline", "dynamic", "auto-update"],
    "timezone": "browser",
    "panels": [
      {
        "id": 1,
        "title": "Pipeline Status",
        "type": "stat",
        "gridPos": {
          "h": 4,
          "w": 12,
          "x": 0,
          "y": 0
        },
        "targets": [
          {
            "expr": "sum(pipeline_runs_total)",
            "legendFormat": "Total Runs",
            "refId": "A"
          },
          {
            "expr": "sum(pipeline_runs_total{status=\"success\"})", 
            "legendFormat": "Successful",
            "refId": "B"
          },
          {
            "expr": "sum(pipeline_runs_total{status=\"failure\"})",
            "legendFormat": "Failed", 
            "refId": "C"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "color": {
              "mode": "thresholds"
            },
            "thresholds": {
              "steps": [
                {
                  "color": "green",
                  "value": null
                }
              ]
            },
            "unit": "short"
          },
          "overrides": [
            {
              "matcher": {
                "id": "byName",
                "options": "Failed"
              },
              "properties": [
                {
                  "id": "color",
                  "value": {
                    "fixedColor": "red",
                    "mode": "fixed"
                  }
                }
              ]
            }
          ]
        }
      },
      {
        "id": 2,
        "title": "Test Results",
        "type": "stat",
        "gridPos": {
          "h": 4,
          "w": 12,
          "x": 12,
          "y": 0
        },
        "targets": [
          {
            "expr": "sum(tests_passed_total)",
            "legendFormat": "Tests Passed",
            "refId": "A"
          },
          {
            "expr": "sum(tests_failed_total)",
            "legendFormat": "Tests Failed",
            "refId": "B"
          },
          {
            "expr": "avg(tests_coverage_percentage)",
            "legendFormat": "Coverage %",
            "refId": "C"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "color": {
              "mode": "thresholds"
            },
            "thresholds": {
              "steps": [
                {
                  "color": "green",
                  "value": null
                }
              ]
            },
            "unit": "short"
          },
          "overrides": [
            {
              "matcher": {
                "id": "byName",
                "options": "Tests Failed"
              },
              "properties": [
                {
                  "id": "color",
                  "value": {
                    "fixedColor": "red",
                    "mode": "fixed"
                  }
                }
              ]
            }
          ]
        }
      },
      {
        "id": 3,
        "title": "Current Repository Information",
        "type": "text",
        "gridPos": {
          "h": 6,
          "w": 24,
          "x": 0,
          "y": 4
        },
        "options": {
          "mode": "markdown",
          "content": "## 📊 Current Repository Information\n\n**This dashboard automatically updates based on the repository currently being scanned in `repos-to-scan.yaml`**\n\n### **Repository Details:**\n- **Name:** $REPO_NAME\n- **URL:** $REPO_URL\n- **Branch:** $REPO_BRANCH\n- **Scan Type:** $SCAN_TYPE\n\n### **Latest Scan:**\n- **Scan Time:** $SCAN_TIME\n- **Pipeline Run ID:** $RUN_ID\n- **Pipeline Run Number:** $RUN_NUMBER\n- **Scan Duration:** $SCAN_DURATION\n\n### **Repository Statistics:**\n- **Total Files:** $TOTAL_FILES\n- **Total Lines:** $TOTAL_LINES\n- **Repository Size:** $REPO_SIZE\n\n---\n**Last Updated:** $(date) | **Data Source:** Live Pipeline Results\n**Note:** This information updates automatically when you change the repository in `repos-to-scan.yaml`"
        }
      },
      {
        "id": 4,
        "title": "Security Vulnerabilities - Current Repository",
        "type": "text",
        "gridPos": {
          "h": 8,
          "w": 12,
          "x": 0,
          "y": 10
        },
        "options": {
          "mode": "markdown",
          "content": "## 🔒 Security Vulnerabilities\n\n**Repository:** $REPO_NAME\n**Scan Time:** $SCAN_TIME\n\n### **Vulnerabilities Found:**\n$VULNERABILITIES_LIST\n\n### **Summary:**\n- **Total Vulnerabilities:** $TOTAL_VULNERABILITIES\n- **High Severity:** $HIGH_VULNERABILITIES\n- **Medium Severity:** $MEDIUM_VULNERABILITIES\n- **Low Severity:** $LOW_VULNERABILITIES\n\n---\n**Action Required:** Update vulnerable packages immediately"
        }
      },
      {
        "id": 5,
        "title": "TODO/FIXME Comments - Current Repository",
        "type": "text",
        "gridPos": {
          "h": 8,
          "w": 12,
          "x": 12,
          "y": 10
        },
        "options": {
          "mode": "markdown",
          "content": "## 📝 TODO/FIXME Comments\n\n**Repository:** $REPO_NAME\n**Scan Time:** $SCAN_TIME\n\n### **Comments Found:**\n$TODO_LIST\n\n### **Summary:**\n- **Total TODOs:** $TOTAL_TODOS\n- **High Priority:** $HIGH_TODOS\n- **Medium Priority:** $MEDIUM_TODOS\n- **Low Priority:** $LOW_TODOS\n\n---\n**Action Required:** Review and address priority items"
        }
      },
      {
        "id": 6,
        "title": "Failed Tests - Current Repository",
        "type": "text",
        "gridPos": {
          "h": 6,
          "w": 12,
          "x": 0,
          "y": 18
        },
        "options": {
          "mode": "markdown",
          "content": "## ❌ Failed Tests\n\n**Repository:** $REPO_NAME\n**Scan Time:** $SCAN_TIME\n\n### **Test Failures:**\n$FAILED_TESTS_LIST\n\n### **Summary:**\n- **Total Failed Tests:** $TOTAL_FAILED_TESTS\n- **Success Rate:** $SUCCESS_RATE%\n- **Coverage:** $COVERAGE%\n\n---\n**Action Required:** Fix failing tests before deployment"
        }
      },
      {
        "id": 7,
        "title": "Code Quality Metrics - Current Repository",
        "type": "text",
        "gridPos": {
          "h": 6,
          "w": 12,
          "x": 12,
          "y": 18
        },
        "options": {
          "mode": "markdown",
          "content": "## 📊 Code Quality Summary\n\n**Repository:** $REPO_NAME\n**Scan Time:** $SCAN_TIME\n\n### **Issues Breakdown:**\n- **TODO Comments:** $TOTAL_TODOS\n- **Debug Statements:** $DEBUG_STATEMENTS\n- **Large Files:** $LARGE_FILES\n- **Total Issues:** $TOTAL_ISSUES\n\n### **Priority Actions:**\n1. **HIGH:** Fix $TOTAL_FAILED_TESTS failed tests\n2. **HIGH:** Address $HIGH_VULNERABILITIES high-severity vulnerabilities\n3. **MEDIUM:** Review $TOTAL_TODOS TODO comments\n4. **LOW:** Remove $DEBUG_STATEMENTS debug statements\n\n---\n**Repository:** $REPO_NAME | **Branch:** $REPO_BRANCH | **Scan Type:** $SCAN_TYPE"
        }
      },
      {
        "id": 8,
        "title": "Pipeline Execution Logs - Current Repository",
        "type": "text",
        "gridPos": {
          "h": 6,
          "w": 24,
          "x": 0,
          "y": 24
        },
        "options": {
          "mode": "markdown",
          "content": "## 📋 Latest Pipeline Execution Logs\n\n**Repository:** $REPO_NAME\n**Run ID:** $RUN_ID\n**Duration:** $SCAN_DURATION\n\n```\n$PIPELINE_LOGS\n```\n\n---\n**Last Updated:** $(date) | **Auto-refresh:** Every 30 seconds"
        }
      }
    ],
    "time": {
      "from": "now-1h",
      "to": "now"
    },
    "refresh": "30s"
  },
  "overwrite": true
}
EOF

# Grafana credentials
GRAFANA_URL="http://213.109.162.134:30102"
GRAFANA_USER="admin"
GRAFANA_PASS="admin123"

echo "Importing dynamic dashboard..."
curl -X POST \
  -H "Content-Type: application/json" \
  -H "Authorization: Basic $(echo -n $GRAFANA_USER:$GRAFANA_PASS | base64)" \
  -d @monitoring/dynamic-dashboard.json \
  "$GRAFANA_URL/api/dashboards/db"

echo ""
echo "========================================="
echo "Dynamic Dashboard Created!"
echo "========================================="
echo "Dashboard URL: $GRAFANA_URL/d/dynamic/pipeline-dashboard-dynamic"
echo ""
echo "This dashboard will:"
echo "✅ Automatically update when you change repos-to-scan.yaml"
echo "✅ Show current repository information dynamically"
echo "✅ Display scan time and repository name automatically"
echo "✅ Update all metrics based on current pipeline runs"
echo "✅ No need to create new dashboards for each repository"
echo ""
echo "Just change the repository in repos-to-scan.yaml and the dashboard updates automatically!"
