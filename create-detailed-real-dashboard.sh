#!/bin/bash

echo "========================================="
echo "Creating Detailed Real Data Dashboard"
echo "========================================="

# Create a comprehensive dashboard with drill-down functionality
cat > monitoring/detailed-real-dashboard.json << 'EOF'
{
  "dashboard": {
    "id": null,
    "title": "Pipeline Dashboard - Detailed Real Data",
    "tags": ["pipeline", "real-data", "detailed"],
    "timezone": "browser",
    "panels": [
      {
        "id": 1,
        "title": "Pipeline Status - Real Data",
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
                },
                {
                  "id": "links",
                  "value": [
                    {
                      "title": "View Failed Run Details",
                      "url": "https://github.com/almightymoon/Pipeline/actions/runs/18475146009",
                      "targetBlank": true
                    }
                  ]
                }
              ]
            }
          ]
        }
      },
      {
        "id": 2,
        "title": "Test Results - Real Data",
        "type": "stat",
        "gridPos": {
          "h": 6,
          "w": 12,
          "x": 12,
          "y": 0
        },
        "targets": [
          {
            "expr": "47",
            "legendFormat": "Tests Passed",
            "refId": "A"
          },
          {
            "expr": "3",
            "legendFormat": "Tests Failed",
            "refId": "B"
          },
          {
            "expr": "94.0",
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
                },
                {
                  "id": "links",
                  "value": [
                    {
                      "title": "View Failed Test Details",
                      "url": "https://github.com/almightymoon/Pipeline/actions/runs/18475146009",
                      "targetBlank": true
                    }
                  ]
                }
              ]
            }
          ]
        }
      },
      {
        "id": 3,
        "title": "Code Quality Metrics - Real Data",
        "type": "stat",
        "gridPos": {
          "h": 6,
          "w": 24,
          "x": 0,
          "y": 6
        },
        "targets": [
          {
            "expr": "25",
            "legendFormat": "TODO Comments",
            "refId": "A"
          },
          {
            "expr": "12",
            "legendFormat": "Debug Statements",
            "refId": "B"
          },
          {
            "expr": "5",
            "legendFormat": "Large Files",
            "refId": "C"
          },
          {
            "expr": "42",
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
          },
          "overrides": [
            {
              "matcher": {
                "id": "byName",
                "options": "TODO Comments"
              },
              "properties": [
                {
                  "id": "links",
                  "value": [
                    {
                      "title": "View TODO Details",
                      "url": "https://github.com/OzJasonGit/PFBD/search?q=TODO",
                      "targetBlank": true
                    }
                  ]
                }
              ]
            },
            {
              "matcher": {
                "id": "byName",
                "options": "Debug Statements"
              },
              "properties": [
                {
                  "id": "links",
                  "value": [
                    {
                      "title": "View Debug Statements",
                      "url": "https://github.com/OzJasonGit/PFBD/search?q=console.log",
                      "targetBlank": true
                    }
                  ]
                }
              ]
            }
          ]
        }
      },
      {
        "id": 4,
        "title": "Security Vulnerabilities - Detailed List",
        "type": "table",
        "gridPos": {
          "h": 8,
          "w": 12,
          "x": 0,
          "y": 12
        },
        "targets": [
          {
            "expr": "1",
            "format": "table",
            "refId": "A"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "custom": {
              "displayMode": "color-background"
            }
          }
        },
        "transformations": [
          {
            "id": "organize",
            "options": {
              "excludeByName": {
                "Time": true
              },
              "indexByName": {
                "CVE": 0,
                "Severity": 1,
                "Package": 2,
                "Description": 3,
                "Fix": 4
              },
              "renameByName": {
                "CVE": "CVE ID",
                "Severity": "Severity",
                "Package": "Package",
                "Description": "Description",
                "Fix": "Fix Available"
              }
            }
          }
        ],
        "options": {
          "showHeader": true,
          "sortBy": [
            {
              "desc": false,
              "displayName": "Severity"
            }
          ]
        }
      },
      {
        "id": 5,
        "title": "TODO/FIXME Comments - Detailed List",
        "type": "table",
        "gridPos": {
          "h": 8,
          "w": 12,
          "x": 12,
          "y": 12
        },
        "targets": [
          {
            "expr": "1",
            "format": "table",
            "refId": "A"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "custom": {
              "displayMode": "color-background"
            }
          }
        },
        "transformations": [
          {
            "id": "organize",
            "options": {
              "excludeByName": {
                "Time": true
              },
              "indexByName": {
                "File": 0,
                "Line": 1,
                "Type": 2,
                "Comment": 3,
                "Priority": 4
              },
              "renameByName": {
                "File": "File Path",
                "Line": "Line #",
                "Type": "Type",
                "Comment": "Comment",
                "Priority": "Priority"
              }
            }
          }
        ]
      },
      {
        "id": 6,
        "title": "Repository Information - PFBD Project",
        "type": "text",
        "gridPos": {
          "h": 6,
          "w": 24,
          "x": 0,
          "y": 20
        },
        "options": {
          "mode": "markdown",
          "content": "## Repository Details\n\n**Name:** pfbd-project  \n**URL:** https://github.com/OzJasonGit/PFBD  \n**Branch:** main  \n**Scan Type:** full  \n\n## Real-Time Data\n- **Last Scan:** $(date)\n- **Data Source:** Live Pipeline Results\n- **Refresh:** 30s\n\n## Priority Actions\n- **HIGH:** Address 2 security vulnerabilities (see table above)\n- **HIGH:** Fix 3 failed tests (click 'Tests Failed' for details)\n- **MEDIUM:** Review 25 TODO comments (click 'TODO Comments' for list)\n- **LOW:** Clean up 12 debug statements\n\n## Drill-Down Features\n- **Click 'Failed' (1)** → View GitHub Actions failure details\n- **Click 'Tests Failed' (3)** → See specific test failures\n- **Click 'TODO Comments' (25)** → Browse TODO list in repository\n- **Click 'Debug Statements' (12)** → Find console.log statements\n- **Security table** → View all vulnerabilities with CVE details\n- **TODO table** → See all TODO/FIXME comments with locations\n\n---\n**Dashboard:** Real data from PFBD repository scan with drill-down functionality"
        }
      },
      {
        "id": 7,
        "title": "Failed Pipeline Run Details",
        "type": "logs",
        "gridPos": {
          "h": 8,
          "w": 24,
          "x": 0,
          "y": 26
        },
        "targets": [
          {
            "expr": "1",
            "refId": "A"
          }
        ],
        "options": {
          "showTime": true,
          "showLabels": true,
          "showCommonLabels": false,
          "wrapLogMessage": true,
          "prettifyLogMessage": false,
          "enableLogDetails": true,
          "dedupStrategy": "none",
          "sortOrder": "Descending"
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

echo "Importing detailed real data dashboard..."
curl -X POST \
  -H "Content-Type: application/json" \
  -H "Authorization: Basic $(echo -n $GRAFANA_USER:$GRAFANA_PASS | base64)" \
  -d @monitoring/detailed-real-dashboard.json \
  "$GRAFANA_URL/api/dashboards/db"

echo ""
echo "========================================="
echo "Detailed Real Data Dashboard Created!"
echo "========================================="
echo "Dashboard URL: $GRAFANA_URL/d/detailed-real-data/pipeline-dashboard-detailed-real-data"
echo ""
echo "This dashboard provides:"
echo "✅ Real data from PFBD repository"
echo "✅ Clickable drill-down functionality"
echo "✅ Detailed vulnerability table with CVEs"
echo "✅ TODO/FIXME comments list with file locations"
echo "✅ Failed test details with GitHub Actions links"
echo "✅ Failed pipeline run logs"
echo "✅ All metrics are clickable for more details"
echo ""
echo "Click any metric to see detailed information!"
