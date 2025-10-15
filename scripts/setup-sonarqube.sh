#!/bin/bash
set -e

echo "========================================="
echo "SONARQUBE SETUP SCRIPT"
echo "========================================="

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker first."
    exit 1
fi

echo "✅ Docker is running"

# Create SonarQube data directory
echo "📁 Creating SonarQube data directory..."
mkdir -p sonarqube-data
mkdir -p sonarqube-logs
mkdir -p sonarqube-extensions

# Set proper permissions
chmod 777 sonarqube-data
chmod 777 sonarqube-logs
chmod 777 sonarqube-extensions

echo "✅ Directories created with proper permissions"

# Stop existing SonarQube container if running
echo "🛑 Stopping existing SonarQube container..."
docker stop sonarqube 2>/dev/null || true
docker rm sonarqube 2>/dev/null || true

# Start SonarQube container
echo "🚀 Starting SonarQube container..."
docker run -d \
  --name sonarqube \
  -p 30100:9000 \
  -e SONAR_ES_BOOTSTRAP_CHECKS_DISABLE=true \
  -e SONAR_JDBC_URL=jdbc:h2:tcp://localhost:9092/sonar \
  -e SONAR_JDBC_USERNAME=sonar \
  -e SONAR_JDBC_PASSWORD=sonar \
  -e SONAR_WEB_JAVAADDITIONALOPTS="-Xmx1g -XX:+UseG1GC" \
  -e SONAR_CE_JAVAADDITIONALOPTS="-Xmx512m -XX:+UseG1GC" \
  -v "$(pwd)/sonarqube-data:/opt/sonarqube/data" \
  -v "$(pwd)/sonarqube-logs:/opt/sonarqube/logs" \
  -v "$(pwd)/sonarqube-extensions:/opt/sonarqube/extensions" \
  sonarqube:10.3-community

echo "✅ SonarQube container started"

# Wait for SonarQube to be ready
echo "⏳ Waiting for SonarQube to be ready..."
for i in {1..60}; do
    if curl -s http://localhost:30100/api/system/status > /dev/null 2>&1; then
        echo "✅ SonarQube is ready!"
        break
    fi
    echo "⏳ Waiting... ($i/60)"
    sleep 10
done

# Check if SonarQube is accessible
if curl -s http://localhost:30100/api/system/status > /dev/null 2>&1; then
    echo "✅ SonarQube is accessible at http://localhost:30100"
    echo "🔑 Default credentials: admin/admin"
    echo "🌐 Access URL: http://213.109.162.134:30100"
else
    echo "❌ SonarQube is not accessible. Check logs with: docker logs sonarqube"
    exit 1
fi

echo "========================================="
echo "SONARQUBE SETUP COMPLETED"
echo "========================================="
echo "🌐 SonarQube URL: http://213.109.162.134:30100"
echo "🔑 Username: admin"
echo "🔑 Password: admin"
echo "📊 Dashboard: http://213.109.162.134:30100/dashboard"
echo "========================================="
