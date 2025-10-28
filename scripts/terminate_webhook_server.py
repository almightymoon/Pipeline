#!/usr/bin/env python3
"""
Simple webhook server to trigger GitHub Actions workflow
Run this on your VPS or a server that can be accessed from the internet
"""
import os
import sys
import json
import requests
from flask import Flask, request, jsonify
from flask_cors import CORS

app = Flask(__name__)
CORS(app)

# GitHub configuration
GITHUB_TOKEN = os.environ.get('GITHUB_TOKEN', '')
GITHUB_OWNER = 'almightymoon'
GITHUB_REPO = 'Pipeline'

def trigger_termination(repository, deployment, namespace):
    """Trigger the GitHub Actions workflow"""
    
    url = f'https://api.github.com/repos/{GITHUB_OWNER}/{GITHUB_REPO}/dispatches'
    
    headers = {
        'Accept': 'application/vnd.github+json',
        'Authorization': f'Bearer {GITHUB_TOKEN}',
        'X-GitHub-Api-Version': '2022-11-28'
    }
    
    payload = {
        'event_type': 'terminate_deployment',
        'client_payload': {
            'repository': repository,
            'deployment': deployment,
            'namespace': namespace
        }
    }
    
    try:
        response = requests.post(url, headers=headers, json=payload)
        
        if response.status_code == 204:
            return True, "Workflow triggered successfully"
        else:
            return False, f"Failed to trigger workflow: {response.status_code} - {response.text}"
    
    except Exception as e:
        return False, f"Error: {str(e)}"

@app.route('/terminate', methods=['GET', 'POST'])
def terminate():
    """Handle termination requests"""
    
    # Get parameters from query string or JSON body
    if request.method == 'GET':
        repository = request.args.get('repository')
        deployment = request.args.get('deployment')
        namespace = request.args.get('namespace', 'pipeline-apps')
    else:
        data = request.get_json() or {}
        repository = data.get('repository')
        deployment = data.get('deployment')
        namespace = data.get('namespace', 'pipeline-apps')
    
    # Validate required parameters
    if not repository or not deployment:
        return jsonify({
            'success': False,
            'error': 'Missing required parameters: repository and deployment'
        }), 400
    
    # Trigger GitHub Actions workflow
    success, message = trigger_termination(repository, deployment, namespace)
    
    if success:
        return jsonify({
            'success': True,
            'message': message,
            'repository': repository,
            'deployment': deployment,
            'namespace': namespace,
            'status': 'termination_triggered'
        }), 200
    else:
        return jsonify({
            'success': False,
            'error': message
        }), 500

@app.route('/health', methods=['GET'])
def health():
    """Health check endpoint"""
    return jsonify({'status': 'healthy'}), 200

@app.route('/', methods=['GET'])
def index():
    """Info endpoint"""
    return jsonify({
        'service': 'GitHub Actions Workflow Trigger',
        'version': '1.0.0',
        'endpoints': {
            'terminate': '/terminate?repository=REPO&deployment=DEPLOYMENT&namespace=NS',
            'health': '/health'
        }
    }), 200

if __name__ == '__main__':
    # Check for GitHub token
    if not GITHUB_TOKEN:
        print("ERROR: GITHUB_TOKEN environment variable not set")
        print("Set it with: export GITHUB_TOKEN=your_token")
        sys.exit(1)
    
    port = int(os.environ.get('PORT', 5000))
    print(f"Starting termination webhook server on port {port}")
    print(f"GitHub Token: {'Set' if GITHUB_TOKEN else 'NOT SET'}")
    
    app.run(host='0.0.0.0', port=port, debug=False)

