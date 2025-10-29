#!/usr/bin/env python3
"""
Update the Grafana dashboard with improved queries that work with Pushgateway metrics
This script regenerates the dashboard with better Prometheus queries
"""

import os
import sys
import yaml

# Import the dashboard creation function
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from complete_pipeline_solution import create_enhanced_dashboard_for_repo, read_current_repo

def main():
    """Update dashboard for current repository"""
    print("🔄 Updating Grafana dashboard with improved queries...")
    
    # Read repository from config
    repo_info = read_current_repo()
    repo_name = repo_info.get('name', 'my-qaicb-repo')
    
    print(f"📊 Updating dashboard for: {repo_name}")
    
    # Regenerate dashboard with improved queries
    success = create_enhanced_dashboard_for_repo(repo_name)
    
    if success:
        print(f"\n✅ Dashboard updated successfully!")
        print(f"📈 Refresh your Grafana dashboard to see the improved queries")
        print(f"🔍 The new queries use last_over_time() to handle Pushgateway metrics better")
    else:
        print("\n❌ Failed to update dashboard")

if __name__ == "__main__":
    main()

