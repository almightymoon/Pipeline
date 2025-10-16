#!/bin/bash
# ===========================================================
# Create SonarQube Metrics Dashboard via Grafana API
# ===========================================================

echo "📊 Creating SonarQube Metrics Dashboard in Grafana"
echo "=================================================="
echo ""

GRAFANA_URL="http://213.109.162.134:30102"
GRAFANA_USER="admin"
GRAFANA_PASS="admin123"

echo "🔍 Checking Grafana connectivity..."
if curl -s -u "$GRAFANA_USER:$GRAFANA_PASS" "$GRAFANA_URL/api/health" | grep -q "ok"; then
    echo "✅ Grafana is accessible"
else
    echo "❌ Grafana is not accessible"
    exit 1
fi

echo ""
echo "📤 Creating SonarQube metrics dashboard..."

# Create a simple dashboard JSON
cat > /tmp/sonarqube-dashboard.json << 'EOF'
{
  "dashboard": {
    "id": null,
    "title": "SonarQube Metrics - my-qaicb-repo",
    "tags": ["sonarqube", "code-quality"],
    "timezone": "browser",
    "panels": [
      {
        "id": 1,
        "title": "SonarQube Bugs",
        "type": "stat",
        "targets": [
          {
            "expr": "sonarqube_bugs{repository=\"my-qaicb-repo\"}",
            "refId": "A"
          }
        ],
        "gridPos": {"h": 8, "w": 6, "x": 0, "y": 0},
        "fieldConfig": {
          "defaults": {
            "color": {"mode": "thresholds"},
            "thresholds": {
              "steps": [
                {"color": "green", "value": null},
                {"color": "yellow", "value": 5},
                {"color": "red", "value": 10}
              ]
            }
          }
        }
      },
      {
        "id": 2,
        "title": "SonarQube Vulnerabilities",
        "type": "stat",
        "targets": [
          {
            "expr": "sonarqube_vulnerabilities{repository=\"my-qaicb-repo\"}",
            "refId": "A"
          }
        ],
        "gridPos": {"h": 8, "w": 6, "x": 6, "y": 0},
        "fieldConfig": {
          "defaults": {
            "color": {"mode": "thresholds"},
            "thresholds": {
              "steps": [
                {"color": "green", "value": null},
                {"color": "yellow", "value": 1},
                {"color": "red", "value": 5}
              ]
            }
          }
        }
      },
      {
        "id": 3,
        "title": "SonarQube Code Smells",
        "type": "stat",
        "targets": [
          {
            "expr": "sonarqube_code_smells{repository=\"my-qaicb-repo\"}",
            "refId": "A"
          }
        ],
        "gridPos": {"h": 8, "w": 6, "x": 12, "y": 0},
        "fieldConfig": {
          "defaults": {
            "color": {"mode": "thresholds"},
            "thresholds": {
              "steps": [
                {"color": "green", "value": null},
                {"color": "yellow", "value": 10},
                {"color": "red", "value": 50}
              ]
            }
          }
        }
      },
      {
        "id": 4,
        "title": "SonarQube Security Hotspots",
        "type": "stat",
        "targets": [
          {
            "expr": "sonarqube_security_hotspots{repository=\"my-qaicb-repo\"}",
            "refId": "A"
          }
        ],
        "gridPos": {"h": 8, "w": 6, "x": 18, "y": 0},
        "fieldConfig": {
          "defaults": {
            "color": {"mode": "thresholds"},
            "thresholds": {
              "steps": [
                {"color": "green", "value": null},
                {"color": "yellow", "value": 5},
                {"color": "red", "value": 20}
              ]
            }
          }
        }
      },
      {
        "id": 5,
        "title": "SonarQube Test Coverage",
        "type": "stat",
        "targets": [
          {
            "expr": "sonarqube_coverage{repository=\"my-qaicb-repo\"}",
            "refId": "A"
          }
        ],
        "gridPos": {"h": 8, "w": 6, "x": 0, "y": 8},
        "fieldConfig": {
          "defaults": {
            "color": {"mode": "thresholds"},
            "thresholds": {
              "steps": [
                {"color": "red", "value": null},
                {"color": "yellow", "value": 50},
                {"color": "green", "value": 80}
              ]
            },
            "unit": "percent"
          }
        }
      },
      {
        "id": 6,
        "title": "Issues by Severity",
        "type": "timeseries",
        "targets": [
          {
            "expr": "sonarqube_issues_by_severity{repository=\"my-qaicb-repo\"}",
            "refId": "A"
          }
        ],
        "gridPos": {"h": 8, "w": 18, "x": 6, "y": 8}
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

# Upload dashboard to Grafana
DASHBOARD_RESPONSE=$(curl -s -X POST \
  -H "Content-Type: application/json" \
  -u "$GRAFANA_USER:$GRAFANA_PASS" \
  -d @/tmp/sonarqube-dashboard.json \
  "$GRAFANA_URL/api/dashboards/db")

echo "Dashboard creation response: $DASHBOARD_RESPONSE"

if echo "$DASHBOARD_RESPONSE" | grep -q '"status":"success"'; then
    echo "✅ SonarQube metrics dashboard created successfully!"
    
    # Extract dashboard URL
    DASHBOARD_URL=$(echo "$DASHBOARD_RESPONSE" | grep -o '"url":"[^"]*"' | cut -d'"' -f4)
    if [ -n "$DASHBOARD_URL" ]; then
        echo "🌐 Dashboard URL: $GRAFANA_URL$DASHBOARD_URL"
    fi
else
    echo "❌ Failed to create dashboard"
    echo "Response: $DASHBOARD_RESPONSE"
fi

echo ""
echo "🔧 Next steps:"
echo "   1. Verify Prometheus is scraping metrics from Pushgateway"
echo "   2. Check that SonarQube metrics are appearing in Prometheus"
echo "   3. View the dashboard at: $GRAFANA_URL/dashboards"
echo ""
echo "📊 To check Prometheus metrics:"
echo "   curl -s http://213.109.162.134:30090/api/v1/query?query=sonarqube_bugs"
echo ""

