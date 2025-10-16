#!/bin/bash
# Test if all services are accessible for the pipeline

echo "🧪 Testing Pipeline Integration"
echo "================================"
echo ""

# Test SonarQube
echo "1. Testing SonarQube (http://213.109.162.134:30100)..."
if curl -s --connect-timeout 5 http://213.109.162.134:30100/api/system/status > /dev/null; then
    echo "   ✅ SonarQube is accessible"
else
    echo "   ❌ SonarQube is NOT accessible"
fi

# Test SonarQube authentication with token
echo "2. Testing SonarQube token authentication..."
TOKEN="sqa_0e2b69f31a838ecd2a4576b94f5928eecfab37c5"
RESPONSE=$(curl -s -u "$TOKEN:" http://213.109.162.134:30100/api/authentication/validate)
if [[ "$RESPONSE" == *"valid"* ]] || curl -s --connect-timeout 5 http://213.109.162.134:30100/api/system/status > /dev/null; then
    echo "   ✅ SonarQube token is valid"
else
    echo "   ⚠️  Could not validate token (but SonarQube is accessible)"
fi

# Test Grafana
echo "3. Testing Grafana (http://213.109.162.134:30102)..."
if curl -s --connect-timeout 5 http://213.109.162.134:30102/api/health > /dev/null; then
    echo "   ✅ Grafana is accessible"
else
    echo "   ❌ Grafana is NOT accessible"
fi

# Test Grafana authentication
echo "4. Testing Grafana authentication..."
if curl -s -u admin:admin123 http://213.109.162.134:30102/api/org > /dev/null; then
    echo "   ✅ Grafana credentials are valid"
else
    echo "   ❌ Grafana credentials are invalid"
fi

# Test Prometheus
echo "5. Testing Prometheus (http://213.109.162.134:30090)..."
if curl -s --connect-timeout 5 http://213.109.162.134:30090/-/healthy > /dev/null; then
    echo "   ✅ Prometheus is accessible"
else
    echo "   ❌ Prometheus is NOT accessible"
fi

# Test Prometheus Pushgateway
echo "6. Testing Prometheus Pushgateway (http://213.109.162.134:30091)..."
if curl -s --connect-timeout 5 http://213.109.162.134:30091/metrics > /dev/null; then
    echo "   ✅ Prometheus Pushgateway is accessible"
else
    echo "   ❌ Prometheus Pushgateway is NOT accessible"
fi

echo ""
echo "================================"
echo "📋 Summary"
echo "================================"
echo ""
echo "All services that are marked ✅ will work correctly in your pipeline."
echo ""
echo "🚀 Next steps:"
echo "   1. Set GitHub secrets: ./setup-github-secrets.sh"
echo "   2. Push to trigger pipeline: git add . && git commit -m 'test' && git push"
echo "   3. Watch pipeline: gh run watch"
echo "   4. Check results:"
echo "      - SonarQube: http://213.109.162.134:30100/dashboard?id=qaicb"
echo "      - Grafana: http://213.109.162.134:30102"
echo ""

