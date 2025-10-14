#!/bin/bash

# ===========================================================
# Save Scan Results Script
# ===========================================================
# This script saves scan results to files that can be read by the dashboard
# It should be run at the end of each pipeline stage

echo "============================================"
echo "💾 Saving Scan Results for Dashboard"
echo "============================================"

# Create results directory
mkdir -p /tmp/scan-results

# 1. Save Trivy security scan results
if [ -f "trivy-results.json" ]; then
    echo "📊 Saving Trivy security results..."
    cp trivy-results.json /tmp/scan-results/
    cp trivy-results.json /tmp/trivy-results.json
    echo "✅ Trivy results saved"
else
    echo "⚠️ No Trivy results found"
fi

# 2. Save quality analysis results
if [ -f "/tmp/quality-results.txt" ]; then
    echo "📊 Saving quality analysis results..."
    cp /tmp/quality-results.txt /tmp/scan-results/
    echo "✅ Quality results saved"
else
    echo "⚠️ No quality results found"
fi

# 3. Save test results
if [ -f "/tmp/test-results.json" ]; then
    echo "📊 Saving test results..."
    cp /tmp/test-results.json /tmp/scan-results/
    echo "✅ Test results saved"
else
    echo "⚠️ No test results found"
fi

# 4. Save secret detection results
if [ -f "/tmp/secrets-found.txt" ]; then
    echo "📊 Saving secret detection results..."
    cp /tmp/secrets-found.txt /tmp/scan-results/
    echo "✅ Secret detection results saved"
else
    echo "⚠️ No secret detection results found"
fi

# 5. Save SonarQube results if available
if [ -f "target/sonar/report-task.txt" ]; then
    echo "📊 Saving SonarQube results..."
    cp target/sonar/report-task.txt /tmp/scan-results/sonar-report.txt
    echo "✅ SonarQube results saved"
else
    echo "⚠️ No SonarQube results found"
fi

# 6. Create a summary file
echo "📊 Creating scan summary..."
cat > /tmp/scan-results/scan-summary.txt << EOF
Scan Results Summary
===================
Repository: $(echo $REPO_NAME || echo "unknown")
Scan Time: $(date -u +%Y-%m-%d\ %H:%M:%S\ UTC)
Pipeline Run: $(echo $GITHUB_RUN_NUMBER || echo "#1")

Files Generated:
- trivy-results.json (Security vulnerabilities)
- quality-results.txt (Code quality analysis)
- test-results.json (Test execution results)
- secrets-found.txt (Secret detection)
- sonar-report.txt (SonarQube analysis)

Dashboard Integration:
- These files will be read by the dashboard creation script
- Real-time metrics will be displayed in Grafana
- Jira issues will include actual scan data
EOF

echo "✅ Scan summary created"

# 7. List all saved files
echo ""
echo "📁 Saved scan result files:"
ls -la /tmp/scan-results/

echo ""
echo "============================================"
echo "✅ Scan results saved successfully!"
echo "📊 Dashboard will now show real-time data"
echo "============================================"
