#!/bin/bash
# ===========================================================
# Test SonarQube Authentication Fix
# ===========================================================

set -e

echo "🔧 Testing SonarQube Authentication Fix"
echo "=========================================="
echo ""

TOKEN="sqa_5d9aed525cdd3421964d6475f57a725da8fccdb1"
SONAR_URL="http://213.109.162.134:30100"

echo "📊 SonarQube Details:"
echo "   URL: $SONAR_URL"
echo "   Token: ${TOKEN:0:15}..."
echo ""

# Test 1: Check SonarQube server status
echo "1️⃣  Checking SonarQube server status..."
SYSTEM_STATUS=$(curl -s "$SONAR_URL/api/system/status")
echo "   Response: $SYSTEM_STATUS"

if echo "$SYSTEM_STATUS" | grep -q '"status":"UP"'; then
    echo "   ✅ SonarQube server is UP"
else
    echo "   ❌ SonarQube server is DOWN"
    exit 1
fi
echo ""

# Test 2: Validate token
echo "2️⃣  Testing token validation..."
VALIDATION=$(curl -s -u "$TOKEN:" "$SONAR_URL/api/authentication/validate")
echo "   Response: $VALIDATION"

if echo "$VALIDATION" | grep -q '"valid":true'; then
    echo "   ✅ Token validation: SUCCESS"
else
    echo "   ❌ Token validation: FAILED"
    exit 1
fi
echo ""

# Test 3: Create a test directory and simulate a scan
echo "3️⃣  Simulating SonarQube scan..."
TEST_DIR="/tmp/sonarqube-test-$$"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

# Create a simple test file
cat > test.py << 'EOF'
def hello_world():
    print("Hello, World!")

if __name__ == "__main__":
    hello_world()
EOF

# Create sonar-project.properties with CORRECT authentication (sonar.login)
cat > sonar-project.properties << EOF
sonar.projectKey=test-auth-fix-$$
sonar.projectName=Test Auth Fix
sonar.projectVersion=1.0
sonar.sources=.
sonar.host.url=$SONAR_URL
sonar.login=$TOKEN
EOF

echo "   Created test project in: $TEST_DIR"
echo "   sonar-project.properties:"
cat sonar-project.properties | grep -v "login"
echo "   sonar.login=***${TOKEN:(-8)}"
echo ""

# Download sonar-scanner if not available
echo "4️⃣  Checking for sonar-scanner..."
if ! command -v sonar-scanner &> /dev/null; then
    echo "   📥 Downloading sonar-scanner..."
    wget -q https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-4.8.0.2856-linux.zip
    unzip -q sonar-scanner-cli-4.8.0.2856-linux.zip
    export PATH="$PATH:$TEST_DIR/sonar-scanner-4.8.0.2856-linux/bin"
    echo "   ✅ sonar-scanner downloaded and ready"
else
    echo "   ✅ sonar-scanner already available"
fi
echo ""

# Run the scan
echo "5️⃣  Running SonarQube scan with sonar.login (FIXED)..."
echo "   Command: sonar-scanner -Dsonar.projectKey=test-auth-fix-$$ -Dsonar.sources=. -Dsonar.host.url=$SONAR_URL -Dsonar.login=***"
echo ""

sonar-scanner \
  -Dsonar.projectKey=test-auth-fix-$$ \
  -Dsonar.sources=. \
  -Dsonar.host.url=$SONAR_URL \
  -Dsonar.login=$TOKEN \
  -Dsonar.scm.disabled=true

echo ""
echo "=========================================="
echo "✅ SONARQUBE AUTHENTICATION FIX VERIFIED!"
echo "=========================================="
echo ""
echo "The fix is working correctly:"
echo "   • Changed from: -Dsonar.token=\$TOKEN"
echo "   • Changed to:   -Dsonar.login=\$TOKEN"
echo ""
echo "📋 Summary of changes made:"
echo "   1. Updated .github/workflows/scan-external-repos.yml"
echo "      - Changed sonar.token to sonar.login in properties file"
echo "      - Changed -Dsonar.token to -Dsonar.login in command"
echo ""
echo "🚀 Next steps:"
echo "   1. Commit and push the changes:"
echo "      git add .github/workflows/scan-external-repos.yml"
echo "      git commit -m 'Fix: Use sonar.login instead of sonar.token for authentication'"
echo "      git push"
echo ""
echo "   2. The pipeline will now successfully authenticate with SonarQube!"
echo ""

# Cleanup
cd /
rm -rf "$TEST_DIR"
echo "🧹 Test directory cleaned up"
echo ""

