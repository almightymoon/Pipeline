#!/usr/bin/env python3
"""
Integrated script: Creates dashboard and Jira issue for the scanned repository
This should be called at the end of your pipeline workflow
"""

import os
import sys
import subprocess

def main():
    """Main function to create dashboard and Jira issue"""
    
    print("=" * 80)
    print("PIPELINE COMPLETION - Creating Dashboard and Jira Issue")
    print("=" * 80)
    
    # Step 1: Create the dashboard with real-time metrics
    print("\n📊 Step 1: Creating repository-specific dashboard...")
    try:
        result = subprocess.run(
            ["python3", "scripts/create_repo_dashboard_and_jira.py"],
            check=True,
            capture_output=False
        )
        print("✅ Dashboard and Jira issue created successfully!")
        return 0
    except subprocess.CalledProcessError as e:
        print(f"⚠️ Error creating dashboard: {e}")
        print("⚠️ Falling back to legacy Jira creation...")
        
        # Fallback: Just create Jira issue with generated URL
        try:
            result = subprocess.run(
                ["python3", "scripts/create_jira_issue.py"],
                check=True,
                capture_output=False
            )
            print("✅ Jira issue created (dashboard creation recommended)")
            return 0
        except subprocess.CalledProcessError as e2:
            print(f"❌ Error creating Jira issue: {e2}")
            return 1

if __name__ == "__main__":
    sys.exit(main())

