#!/usr/bin/env python3
"""
Create Jira issue for Docker image deployments with endpoints
"""
import os
import sys
import requests
import yaml
from datetime import datetime

def read_deployment_config(config_path):
    """Read the images-to-deploy.yaml configuration"""
    try:
        with open(config_path, 'r') as f:
            data = yaml.safe_load(f)
        
        if data and 'images' in data:
            # Filter out commented entries (None or empty)
            active_images = [img for img in data['images'] if img and 'image' in img and img['image']]
            return active_images
        
        return []
    except Exception as e:
        print(f"Warning: Could not read deployment config: {e}")
        return []

def get_deployment_endpoints(config_path):
    """Read deployment endpoints from file"""
    endpoints = {}
    endpoints_file = config_path.replace('images-to-deploy.yaml', 'endpoints.txt')
    
    try:
        with open(endpoints_file, 'r') as f:
            for line in f:
                if ':' in line:
                    parts = line.strip().split(':')
                    if len(parts) == 2:
                        endpoints[parts[0]] = parts[1]
    except Exception as e:
        print(f"Could not read endpoints: {e}")
    
    return endpoints

def format_jira_description(images, endpoints, vps_ip, namespace):
    """Create Jira issue description"""
    
    current_time = datetime.now().strftime("%Y-%m-%d %H:%M:%S UTC")
    
    description = f"""
🚀 *DOCKER IMAGE DEPLOYMENT REPORT*

*Deployment Information:*
• Deployment Time: {current_time}
• Environment: Production/Staging
• Namespace: {namespace}
• VPS IP: {vps_ip}

*📦 DEPLOYED IMAGES:*
"""
    
    # Add each image deployment details
    for idx, image in enumerate(images, 1):
        image_name = image.get('image', 'Unknown')
        friendly_name = image.get('name', 'Unnamed')
        port = image.get('port', '80')
        node_port = image.get('node_port', 'N/A')
        replicas = image.get('replicas', 1)
        
        # Try to get endpoint from endpoints file
        endpoint_url = f"http://{vps_ip}:{node_port}" if node_port != 'N/A' else "N/A"
        # Compute deployment identifiers
        deployment_name = f"{friendly_name}-deployment"
        terminate_url = (
            f"https://github.com/almightymoon/Pipeline/actions/workflows/terminate-deployment.yml"
            f"?repository={friendly_name}&deployment={deployment_name}&namespace={namespace}"
        )
        
        description += f"""
*{idx}. {friendly_name}*
• Image: `{image_name}`
• Container Port: {port}
• Node Port: {node_port}
• Replicas: {replicas}
• Endpoint: {endpoint_url}
 • Terminate: [🛑 Terminate Deployment]({terminate_url})
• Status: ✅ Deployed

"""
    
    description += f"""
*🌐 ACCESS URLS:*
"""
    
    # Generate access URLs
    for image in images:
        friendly_name = image.get('name', 'Unnamed')
        node_port = image.get('node_port', 'N/A')
        
        if node_port != 'N/A':
            url = f"http://{vps_ip}:{node_port}"
            description += f"• {friendly_name}: [{url}]({url})\n"
    
    description += f"""

*🔍 KUBERNETES COMMANDS:*

*View deployments:*
```
kubectl get deployments -n {namespace}
```

*View services:*
```
kubectl get svc -n {namespace}
```

*View pods:*
```
kubectl get pods -n {namespace}
```

*Logs for a specific deployment:*
```
kubectl logs -f deployment/<deployment-name> -n {namespace}
```

*📊 MONITORING:*

*Check pod status:*
```
kubectl get pods -n {namespace} -o wide
```

*Describe a pod:*
```
kubectl describe pod <pod-name> -n {namespace}
```

*🔧 TROUBLESHOOTING:*

*Restart a deployment:*
```
kubectl rollout restart deployment/<deployment-name> -n {namespace}
```

*Rollback a deployment:*
```
kubectl rollout undo deployment/<deployment-name> -n {namespace}
```

*Delete a deployment:*
```
kubectl delete deployment <deployment-name> -n {namespace}
kubectl delete svc <service-name> -n {namespace}
```

*📝 DEPLOYMENT SUMMARY:*
• Total Images: {len(images)}
• Namespace: {namespace}
• VPS IP: {vps_ip}
• Deployment Status: ✅ Success
• All services accessible via NodePort

*Next Steps:*
1. Verify all endpoints are accessible
2. Monitor application logs for any issues
3. Set up health checks if needed
4. Configure ingress for custom domains (optional)
5. Set up monitoring and alerting

*Automated Deployment:*
This issue was automatically created by the Docker Image Deployment Pipeline.
Deployment completed at: {current_time}
"""
    
    return description

def create_jira_deployment_issue(jira_url=None, jira_email=None, jira_api_token=None, 
                                  jira_project_key=None, config_path=None, vps_ip=None, namespace=None):
    """Create Jira issue for deployment"""
    
    # Get environment variables if not provided
    jira_url = jira_url or os.environ.get('JIRA_URL', '').strip()
    jira_email = jira_email or os.environ.get('JIRA_EMAIL', '').strip()
    jira_api_token = jira_api_token or os.environ.get('JIRA_API_TOKEN', '').strip()
    jira_project_key = jira_project_key or os.environ.get('JIRA_PROJECT_KEY', '').strip()
    config_path = config_path or os.environ.get('CONFIG_PATH', 'images-to-deploy.yaml')
    vps_ip = vps_ip or os.environ.get('VPS_IP', '213.109.162.134')
    namespace = namespace or os.environ.get('NAMESPACE', 'default')
    
    # Validate required fields
    if not all([jira_url, jira_email, jira_api_token, jira_project_key, config_path]):
        print("Missing required Jira configuration:")
        print(f"  JIRA_URL: {'set' if jira_url else 'NOT SET'}")
        print(f"  JIRA_EMAIL: {'set' if jira_email else 'NOT SET'}")
        print(f"  JIRA_API_TOKEN: {'set' if jira_api_token else 'NOT SET'}")
        print(f"  JIRA_PROJECT_KEY: {'set' if jira_project_key else 'NOT SET'}")
        print(f"  CONFIG_PATH: {'set' if config_path else 'NOT SET'}")
        return 1
    
    # Read deployment configuration
    images = read_deployment_config(config_path)
    
    if not images:
        print("No images found to deploy in configuration")
        return 1
    
    # Get endpoints
    endpoints = get_deployment_endpoints(config_path)
    
    # Create summary
    summary = f"Docker Image Deployment - {len(images)} images deployed to {namespace}"
    
    # Create description
    description = format_jira_description(images, endpoints, vps_ip, namespace)
    
    # Add https:// if scheme is missing
    if not jira_url.startswith(('http://', 'https://')):
        jira_url = 'https://' + jira_url
    
    # Ensure URL ends with /rest/api/2/issue
    if not jira_url.endswith('/rest/api/2/issue'):
        if jira_url.endswith('/'):
            jira_url = jira_url + 'rest/api/2/issue'
        else:
            jira_url = jira_url + '/rest/api/2/issue'
    
    print(f"Creating Jira issue in project {jira_project_key}")
    print(f"Summary: {summary}")
    
    # Prepare the payload
    payload = {
        "fields": {
            "project": {
                "key": jira_project_key
            },
            "summary": summary,
            "description": description,
            "issuetype": {
                "name": "Task"
            }
        }
    }
    
    # Make the API call
    try:
        response = requests.post(
            jira_url,
            auth=(jira_email, jira_api_token),
            headers={
                'Content-Type': 'application/json',
                'Accept': 'application/json'
            },
            json=payload,
            timeout=30
        )
        
        if response.status_code in [200, 201]:
            issue_data = response.json()
            issue_key = issue_data.get('key', 'Unknown')
            print(f"✅ Successfully created Jira issue: {issue_key}")
            print(f"🔗 Issue URL: {jira_url.replace('/rest/api/2/issue', '/')}browse/{issue_key}")
            return 0
        else:
            print(f"❌ Failed to create Jira issue. Status code: {response.status_code}")
            print(f"Response: {response.text}")
            return 1
            
    except Exception as e:
        print(f"❌ Error creating Jira issue: {str(e)}")
        return 1

if __name__ == '__main__':
    sys.exit(create_jira_deployment_issue())

