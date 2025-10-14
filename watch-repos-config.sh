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
