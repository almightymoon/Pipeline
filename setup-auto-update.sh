#!/bin/bash

echo "========================================="
echo "Setting Up Automatic Dashboard Updates"
echo "========================================="

# Make sure the change script is executable
chmod +x change-repo-and-update-dashboard.sh

# Create a simple file watcher script
cat > watch-repos-config.sh << 'EOF'
#!/bin/bash

echo "========================================="
echo "Watching repos-to-scan.yaml for changes"
echo "========================================="

# Function to update dashboard
update_dashboard() {
    echo "🔄 repos-to-scan.yaml changed - updating dashboard..."
    ./change-repo-and-update-dashboard.sh
    echo "✅ Dashboard updated automatically!"
}

# Watch the file for changes
echo "👀 Watching repos-to-scan.yaml for changes..."
echo "Press Ctrl+C to stop watching"

# Use inotifywait if available, otherwise use a simple polling method
if command -v inotifywait >/dev/null 2>&1; then
    echo "Using inotifywait for file watching..."
    while inotifywait -e modify repos-to-scan.yaml 2>/dev/null; do
        update_dashboard
    done
else
    echo "inotifywait not available, using polling method..."
    LAST_MODIFIED=$(stat -c %Y repos-to-scan.yaml 2>/dev/null || echo "0")
    
    while true; do
        sleep 2
        CURRENT_MODIFIED=$(stat -c %Y repos-to-scan.yaml 2>/dev/null || echo "0")
        
        if [ "$CURRENT_MODIFIED" != "$LAST_MODIFIED" ]; then
            update_dashboard
            LAST_MODIFIED=$CURRENT_MODIFIED
        fi
    done
fi
EOF

chmod +x watch-repos-config.sh

echo ""
echo "✅ Automatic update system set up!"
echo ""
echo "📋 Available methods:"
echo ""
echo "1. 🎯 Git Hook (Automatic on commit):"
echo "   - Changes to repos-to-scan.yaml are detected automatically"
echo "   - Dashboard updates after you commit changes"
echo "   - Just run: git add . && git commit -m 'Update repo' && git push"
echo ""
echo "2. 👀 File Watcher (Real-time):"
echo "   - Watches repos-to-scan.yaml for changes"
echo "   - Updates dashboard immediately when you save the file"
echo "   - Run: ./watch-repos-config.sh"
echo ""
echo "3. 🔧 Manual Update:"
echo "   - Run: ./change-repo-and-update-dashboard.sh"
echo ""
echo "🎉 Choose your preferred method!"
