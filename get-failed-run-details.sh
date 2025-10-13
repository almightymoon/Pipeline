#!/bin/bash

# Get Failed Run Details Script
# This script shows you details about the failed pipeline run

echo "=========================================="
echo "🔍 Failed Run Investigation"
echo "=========================================="

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[ℹ]${NC} $1"
}

echo ""
echo "=========================================="
echo "📊 Current Pipeline Status"
echo "=========================================="

print_info "Based on your dashboard, you have:"
echo "  • Total Runs: 3"
echo "  • Successful: 2"
echo "  • Failed: 1"
echo "  • Tests Passed: 41"
echo "  • Tests Failed: 1"
echo "  • Coverage: 87.5%"

echo ""
echo "=========================================="
echo "🔍 Where to Find Failed Run Details"
echo "=========================================="

print_info "To investigate the failed run, check these sources:"

echo ""
echo "1. 🌐 GitHub Actions (Most Detailed):"
echo "   URL: https://github.com/almightymoon/Pipeline/actions"
echo "   • Shows all pipeline runs"
echo "   • Click on any failed run to see detailed logs"
echo "   • Look for red X marks indicating failures"

echo ""
echo "2. 📋 Jira Issues:"
echo "   URL: https://faniqueprimus.atlassian.net/jira/software/projects/KAN/boards/1"
echo "   • Check for issues created by the pipeline"
echo "   • Look for bug reports or failure notifications"

echo ""
echo "3. 📊 Grafana Logs (if configured):"
echo "   • Check the 'Failed Run Details' panel in your dashboard"
echo "   • Look for ERROR or FAILED log entries"

echo ""
echo "=========================================="
echo "🎯 Common Failure Reasons"
echo "=========================================="

print_warning "Based on your pipeline setup, common failure causes:"

echo ""
echo "1. 🔐 Authentication Issues:"
echo "   • Missing or invalid GitHub secrets"
echo "   • Expired API tokens"
echo "   • Wrong credentials"

echo ""
echo "2. 🏗️ Build Failures:"
echo "   • Docker build errors"
echo "   • Missing dependencies"
echo "   • Compilation errors"

echo ""
echo "3. 🧪 Test Failures:"
echo "   • Unit test failures"
echo "   • Integration test issues"
echo "   • Test environment problems"

echo ""
echo "4. 🔒 Security Scan Issues:"
echo "   • SonarQube connection problems"
echo "   • Trivy scan failures"
echo "   • Code quality threshold violations"

echo ""
echo "5. 🚀 Deployment Failures:"
echo "   • Kubernetes cluster issues"
echo "   • Missing resources"
echo "   • Configuration errors"

echo ""
echo "=========================================="
echo "🔧 Quick Investigation Steps"
echo "=========================================="

print_info "To quickly find the failure cause:"

echo ""
echo "1. 📱 Check GitHub Actions:"
echo "   • Go to: https://github.com/almightymoon/Pipeline/actions"
echo "   • Look for the most recent failed run (red X)"
echo "   • Click on it to see the failure details"

echo ""
echo "2. 🔍 Look for Error Patterns:"
echo "   • Authentication errors (401, 403)"
echo "   • Build failures (docker, npm, pip)"
echo "   • Test failures (pytest, jest)"
echo "   • Security scan issues (sonar, trivy)"

echo ""
echo "3. 📊 Check Recent Changes:"
echo "   • Review recent commits that might have caused the failure"
echo "   • Check if any dependencies or configurations changed"

echo ""
echo "=========================================="
echo "🚀 Next Steps"
echo "=========================================="

print_status "Recommended actions:"

echo ""
echo "1. ✅ Check GitHub Actions first (most detailed)"
echo "2. 🔍 Look for the specific error message"
echo "3. 🔧 Fix the underlying issue"
echo "4. 🚀 Re-run the pipeline"
echo "5. 📊 Monitor the dashboard for success"

echo ""
echo "💡 Pro Tip: The dashboard shows '1 failed run' but the detailed logs in GitHub Actions will tell you exactly what went wrong!"

echo ""
echo "=========================================="
