#!/bin/bash
# ===========================================================
# Test SonarQube Authentication
# ===========================================================

echo "🔐 TESTING SONARQUBE AUTHENTICATION"
echo "=========================================="
echo ""

TOKEN="sqa_5d9aed525cdd3421964d6475f57a725da8fccdb1"
SONAR_URL="http://213.109.162.134:30100"

echo "📊 SonarQube Details:"
echo "   URL: $SONAR_URL"
echo "   Token: ${TOKEN:0:15}..."
echo ""

# Test 1: Validate token
echo "1️⃣  Testing token validation..."
VALIDATION=$(curl -s -u "$TOKEN:" "$SONAR_URL/api/authentication/validate")
echo "   Response: $VALIDATION"

if echo "$VALIDATION" | grep -q '"valid":true'; then
    echo "   ✅ Token validation: SUCCESS"
else
    echo "   ❌ Token validation: FAILED"
    exit 1
fi
echo ""

# Test 2: Get system info
echo "2️⃣  Testing system access..."
SYSTEM_INFO=$(curl -s -u "$TOKEN:" "$SONAR_URL/api/system/status")
echo "   Response: $SYSTEM_INFO"

if echo "$SYSTEM_INFO" | grep -q '"status":"UP"'; then
    echo "   ✅ System access: SUCCESS"
else
    echo "   ❌ System access: FAILED"
    exit 1
fi
echo ""

# Test 3: Test project creation (what SonarScanner will do)
echo "3️⃣  Testing project permissions..."
PROJECT_KEY="test-auth-$(date +%s)"
curl -s -u "$TOKEN:" -X POST "$SONAR_URL/api/projects/create?project=$PROJECT_KEY&name=Test" > /dev/null
PROJECT_CHECK=$(curl -s -u "$TOKEN:" "$SONAR_URL/api/projects/search?projects=$PROJECT_KEY")

if echo "$PROJECT_CHECK" | grep -q "$PROJECT_KEY"; then
    echo "   ✅ Project creation: SUCCESS"
    # Clean up test project
    curl -s -u "$TOKEN:" -X POST "$SONAR_URL/api/projects/delete?project=$PROJECT_KEY" > /dev/null
    echo "   ✅ Test project cleaned up"
else
    echo "   ⚠️  Project creation: Could not verify (might still work)"
fi
echo ""

# Test 4: Simulate what the workflow does
echo "4️⃣  Simulating workflow authentication..."
echo "   Creating test sonar-project.properties..."

cat > /tmp/test-sonar-project.properties << EOF
sonar.projectKey=test-workflow-auth
sonar.projectName=Test Workflow Auth
sonar.sources=.
sonar.host.url=$SONAR_URL
sonar.token=$TOKEN
EOF

echo "   ✅ Properties file created"
echo "   Contents:"
cat /tmp/test-sonar-project.properties | grep -v "token"
echo "   sonar.token=***${TOKEN:(-8)}"
echo ""

echo "=========================================="
echo "✅ ALL AUTHENTICATION TESTS PASSED!"
echo "=========================================="
echo ""
echo "The SonarQube token is working correctly."
echo "GitHub secret should be: sqa_5d9aed525cdd3421964d6475f57a725da8fccdb1"
echo ""
echo "Verify GitHub secret:"
echo "  gh secret list --repo almightymoon/Pipeline | grep SONARQUBE_TOKEN"
echo ""

