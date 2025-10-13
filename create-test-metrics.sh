#!/bin/bash

echo "========================================="
echo "Creating Test Metrics for Dashboard"
echo "========================================="

# Grafana credentials
GRAFANA_URL="http://213.109.162.134:30102"
GRAFANA_USER="admin"
GRAFANA_PASS="admin123"

# Create a simple test dashboard with hardcoded data
cat > monitoring/test-metrics-dashboard.json << 'EOF'
{
  "dashboard": {
    "id": null,
    "title": "Pipeline Dashboard - Test Data",
    "tags": ["pipeline", "test-data"],
    "timezone": "browser",
    "panels": [
      {
        "id": 1,
        "title": "Pipeline Status - Test Data",
        "type": "stat",
        "gridPos": {
          "h": 6,
          "w": 12,
          "x": 0,
          "y": 0
        },
        "targets": [
          {
            "expr": "3",
            "legendFormat": "Total Runs",
            "refId": "A"
          },
          {
            "expr": "2", 
            "legendFormat": "Successful",
            "refId": "B"
          },
          {
            "expr": "1",
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
        "title": "Test Results - Test Data",
        "type": "stat",
        "gridPos": {
          "h": 6,
          "w": 12,
          "x": 12,
          "y": 0
        },
        "targets": [
          {
            "expr": "45",
            "legendFormat": "Tests Passed",
            "refId": "A"
          },
          {
            "expr": "2",
            "legendFormat": "Tests Failed",
            "refId": "B"
          },
          {
            "expr": "92.5",
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
            },
            {
              "matcher": {
                "id": "byName",
                "options": "Coverage %"
              },
              "properties": [
                {
                  "id": "unit",
                  "value": "percent"
                },
                {
                  "id": "color",
                  "value": {
                    "fixedColor": "blue",
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
        "title": "Code Quality Metrics - Test Data",
        "type": "stat",
        "gridPos": {
          "h": 6,
          "w": 24,
          "x": 0,
          "y": 6
        },
        "targets": [
          {
            "expr": "23",
            "legendFormat": "TODO Comments",
            "refId": "A"
          },
          {
            "expr": "8",
            "legendFormat": "Debug Statements",
            "refId": "B"
          },
          {
            "expr": "3",
            "legendFormat": "Large Files",
            "refId": "C"
          },
          {
            "expr": "34",
            "legendFormat": "Total Issues",
            "refId": "D"
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
                  "value": 0
                },
                {
                  "color": "yellow",
                  "value": 10
                },
                {
                  "color": "red",
                  "value": 20
                }
              ]
            },
            "unit": "short"
          }
        }
      },
      {
        "id": 4,
        "title": "Security Scan Results - Test Data",
        "type": "stat",
        "gridPos": {
          "h": 6,
          "w": 12,
          "x": 0,
          "y": 12
        },
        "targets": [
          {
            "expr": "3",
            "legendFormat": "Vulnerabilities",
            "refId": "A"
          },
          {
            "expr": "0",
            "legendFormat": "Secrets Found",
            "refId": "B"
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
                  "value": 0
                },
                {
                  "color": "yellow",
                  "value": 1
                },
                {
                  "color": "red",
                  "value": 5
                }
              ]
            },
            "unit": "short"
          }
        }
      },
      {
        "id": 5,
        "title": "Repository Information - PFBD Project",
        "type": "text",
        "gridPos": {
          "h": 6,
          "w": 12,
          "x": 12,
          "y": 12
        },
        "options": {
          "mode": "markdown",
          "content": "## Repository Details\n\n**Name:** pfbd-project  \n**URL:** https://github.com/OzJasonGit/PFBD  \n**Branch:** main  \n**Scan Type:** full  \n\n## Real-Time Data\n- **Last Scan:** $(date)\n- **Data Source:** Test Data\n- **Refresh:** 30s\n\n## Priority Actions\n- **HIGH:** Address 3 security vulnerabilities\n- **HIGH:** Fix 2 failed tests\n- **MEDIUM:** Improve code quality (34 issues)\n\n---\n**Dashboard:** Test data for PFBD repository"
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

echo "Importing test metrics dashboard..."
curl -X POST \
  -H "Content-Type: application/json" \
  -H "Authorization: Basic $(echo -n $GRAFANA_USER:$GRAFANA_PASS | base64)" \
  -d @monitoring/test-metrics-dashboard.json \
  "$GRAFANA_URL/api/dashboards/db"

echo ""
echo "========================================="
echo "Test Metrics Dashboard Created!"
echo "========================================="
echo "Dashboard URL: $GRAFANA_URL/d/test-metrics/pipeline-dashboard-test-data"
echo ""
echo "This dashboard shows test data for the PFBD repository:"
echo "✅ Total Runs: 3 (2 successful, 1 failed)"
echo "✅ Tests: 45 passed, 2 failed, 92.5% coverage"
echo "✅ Code Quality: 23 TODOs, 8 debug statements, 3 large files"
echo "✅ Security: 3 vulnerabilities, 0 secrets found"
echo "✅ Repository: pfbd-project (https://github.com/OzJasonGit/PFBD)"
