# Docker Image Deployment Pipeline Guide

## Overview

This guide explains how to deploy Docker images from Docker Hub to your VPS/Kubernetes cluster using the automated deployment pipeline.

## Features

- 📦 Deploy Docker images from Docker Hub or any public registry
- 🚀 Automated Kubernetes deployment
- 📝 Automatic Jira issue creation with deployment details and endpoints
- 🔍 Real-time deployment status monitoring
- 🌐 Automatic NodePort service configuration
- ⚙️ Configurable replicas, ports, and namespaces

## Prerequisites

1. **Kubernetes Cluster**: Access to a K3s or Kubernetes cluster
2. **Kubeconfig**: Valid kubeconfig file for cluster access
3. **Jira Integration**: Jira credentials configured in GitHub secrets
4. **VPS**: Running Kubernetes cluster with NodePort access

## Quick Start

### 1. Configure Images to Deploy

Edit `images-to-deploy.yaml` to add your Docker images:

```yaml
images:
  - image: nginx:latest
    name: nginx-web-server
    namespace: default
    port: 80
    node_port: 30080
    replicas: 1
    environment: staging
  
  - image: docker.io/yourusername/your-app:v1.0
    name: my-awesome-app
    namespace: production
    port: 8080
    node_port: 30081
    replicas: 3
    environment: production
```

### Configuration Fields

| Field | Description | Required | Example |
|-------|-------------|----------|---------|
| `image` | Full Docker Hub image path | Yes | `nginx:latest`, `docker.io/user/app:v1.0` |
| `name` | Friendly name for deployment | Yes | `nginx-web-server` |
| `namespace` | Kubernetes namespace | No | `default`, `production` |
| `port` | Container port | Yes | `80`, `8080`, `3000` |
| `node_port` | External NodePort (30000-32767) | No | `30080`, `30081` |
| `replicas` | Number of pod instances | No | `1`, `3` |
| `environment` | Environment label | No | `staging`, `production` |

### 2. Run the Deployment

#### Option A: Manual Trigger

```bash
# Trigger via GitHub Actions UI
# Go to Actions tab → "Deploy Docker Images" → "Run workflow"
```

#### Option B: Auto-deploy on Commit

Simply commit changes to `images-to-deploy.yaml`:

```bash
git add images-to-deploy.yaml
git commit -m "Add new Docker images for deployment"
git push
```

#### Option C: Scheduled Deployment

The pipeline runs daily at midnight UTC automatically.

### 3. Monitor Deployment

Check the GitHub Actions tab for deployment status and logs.

## Accessing Deployed Applications

Once deployed, your applications will be accessible via:

```
http://VPS_IP:node_port
```

Example:
- Nginx: `http://213.109.162.134:30080`
- Custom App: `http://213.109.162.134:30081`

## Jira Integration

### Automatic Issue Creation

The pipeline automatically creates a Jira issue with:

- ✅ Deployment summary
- 🌐 Access URLs for all deployed services
- 📊 Kubernetes resource details
- 🔍 Status and monitoring commands
- 🔧 Troubleshooting commands

### Issue Details

**Summary**: `Docker Image Deployment - X images deployed to [namespace]`

**Description Includes**:
- Deployment time and environment info
- List of all deployed images
- Access URLs for each service
- Kubernetes commands for management
- Monitoring and troubleshooting guides

## File Structure

```
.
├── images-to-deploy.yaml          # Configuration file
├── tekton/
│   ├── image-deployment-pipeline.yaml
│   └── tasks/
│       ├── read-images-config-task.yaml
│       ├── pull-docker-images-task.yaml
│       ├── deploy-images-to-k8s-task.yaml
│       ├── get-deployment-endpoints-task.yaml
│       ├── create-jira-deployment-issue-task.yaml
│       └── deployment-cleanup-task.yaml
├── .github/workflows/
│   └── deploy-docker-images.yml   # GitHub Actions workflow
└── scripts/
    └── create_deployment_jira_issue.py  # Jira integration script
```

## GitHub Secrets Configuration

Set these secrets in your repository:

```bash
# Kubernetes
KUBECONFIG              # Base64 encoded kubeconfig file

# VPS Access
VPS_USER                # SSH username
VPS_SSH_KEY             # Full PEM private key (multi-line)
VPS_SSH_PASSPHRASE      # Passphrase for the private key (if set)

# Jira Integration
JIRA_URL                # Your Jira URL (e.g., https://yourcompany.atlassian.net)
JIRA_EMAIL              # Your Jira email
JIRA_API_TOKEN          # Jira API token
JIRA_PROJECT_KEY        # Project key (e.g., ML, DEV)
```

### How to Get Jira API Token

1. Go to: https://id.atlassian.com/manage-profile/security/api-tokens
2. Click "Create API token"
3. Copy the generated token
4. Add to GitHub secrets as `JIRA_API_TOKEN`

## Pipeline Stages

### 1. Read Configuration
- Validates `images-to-deploy.yaml`
- Counts images to deploy
- Reports configuration status

### 2. Pull Docker Images
- Pulls images from Docker Hub
- Validates image availability
- Reports pull status

### 3. Deploy to Kubernetes
- Creates namespace if needed
- Deploys each image as a Kubernetes Deployment
- Creates Service with NodePort
- Sets up resource limits

### 4. Get Endpoints
- Retrieves deployment status
- Collects service endpoints
- Saves endpoint information

### 5. Create Jira Issue
- Generates deployment summary
- Includes all access URLs
- Creates Jira issue with details

### 6. Cleanup
- Removes temporary files
- Finalizes deployment report

## Managing Deployments

### View Deployments

```bash
# List all deployments
kubectl get deployments -n <namespace>

# List all services
kubectl get svc -n <namespace>

# List all pods
kubectl get pods -n <namespace>
```

### Check Pod Status

```bash
# Get detailed pod information
kubectl describe pod <pod-name> -n <namespace>

# View pod logs
kubectl logs -f <pod-name> -n <namespace>
```

### Restart Deployment

```bash
# Restart a deployment
kubectl rollout restart deployment/<deployment-name> -n <namespace>

# View rollout status
kubectl rollout status deployment/<deployment-name> -n <namespace>
```

### Update Deployment

```bash
# Update image version
kubectl set image deployment/<deployment-name> <container-name>=<new-image> -n <namespace>

# Or edit directly
kubectl edit deployment/<deployment-name> -n <namespace>
```

### Rollback Deployment

```bash
# Rollback to previous version
kubectl rollout undo deployment/<deployment-name> -n <namespace>

# Rollback to specific revision
kubectl rollout undo deployment/<deployment-name> --to-revision=<revision-number> -n <namespace>
```

### Delete Deployment

```bash
# Delete deployment and service
kubectl delete deployment/<deployment-name> -n <namespace>
kubectl delete svc/<service-name> -n <namespace>

# Or delete all deployments in namespace
kubectl delete all --all -n <namespace>
```

## Troubleshooting

### Deployment Fails

**Check pod status**:
```bash
kubectl get pods -n <namespace>
kubectl describe pod <pod-name> -n <namespace>
```

**View logs**:
```bash
kubectl logs <pod-name> -n <namespace>
kubectl logs <pod-name> -n <namespace> --previous  # Previous container logs
```

### Image Pull Errors

**Check image availability**:
```bash
docker pull <image-name>
```

**Authentication issues**:
- Use public images or configure image pull secrets
- Update image registry credentials if needed

### NodePort Not Accessible

**Check service**:
```bash
kubectl get svc -n <namespace>
kubectl describe svc <service-name> -n <namespace>
```

**Verify firewall**:
```bash
# On VPS
sudo ufw status
sudo netstat -tuln | grep <node_port>
```

### Jira Issue Not Created

**Check Jira credentials**:
```bash
# Verify secrets in GitHub
# Repository Settings → Secrets → Actions
```

**Test Jira API**:
```bash
# Test API connection
curl -u <email>:<token> https://your-domain.atlassian.net/rest/api/2/issue/<issue-key>
```

## Best Practices

### 1. Resource Management

Set appropriate resource limits in `images-to-deploy.yaml`:

```yaml
resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: 500m
    memory: 512Mi
```

### 2. Health Checks

Add health probes for production deployments:

```yaml
livenessProbe:
  httpGet:
    path: /health
    port: 80
  initialDelaySeconds: 30
  
readinessProbe:
  httpGet:
    path: /ready
    port: 80
  initialDelaySeconds: 5
```

### 3. Security

- Use specific image tags (avoid `:latest`)
- Scan images for vulnerabilities
- Use private registries for sensitive images
- Implement network policies

### 4. Monitoring

- Set up Prometheus metrics
- Configure logging to centralized system
- Create dashboards for each deployment
- Set up alerts for failures

## Advanced Configuration

### Custom Namespaces

Create separate namespaces for different environments:

```bash
# Create namespace
kubectl create namespace production

# Update images-to-deploy.yaml
namespace: production
```

### High Availability

Deploy multiple replicas:

```yaml
replicas: 3

# Add pod disruption budget
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: <deployment-name>-pdb
spec:
  minAvailable: 2
  selector:
    matchLabels:
      app: <deployment-name>
```

### Custom Resources

Add custom Kubernetes resources:

```yaml
# Add to deployment template
resources:
  requests:
    cpu: "500m"
    memory: "1Gi"
  limits:
    cpu: "2"
    memory: "4Gi"
```

## Examples

### Example 1: Simple Nginx Deployment

```yaml
images:
  - image: nginx:latest
    name: nginx
    namespace: default
    port: 80
    node_port: 30080
    replicas: 1
```

### Example 2: Node.js Application

```yaml
images:
  - image: node:18-alpine
    name: nodejs-app
    namespace: production
    port: 3000
    node_port: 30081
    replicas: 3
```

### Example 3: Multiple Environments

```yaml
images:
  - image: myapp:v1.0
    name: myapp-staging
    namespace: staging
    port: 8080
    node_port: 30100
    replicas: 1
    environment: staging
  
  - image: myapp:v1.0
    name: myapp-production
    namespace: production
    port: 8080
    node_port: 30101
    replicas: 3
    environment: production
```

## Support

For issues or questions:
1. Check the logs in GitHub Actions
2. Review Jira issues created by the pipeline
3. Consult the troubleshooting section
4. Open an issue in the repository

## Related Documentation

- [K3S Cluster Setup Guide](K3S_CLUSTER_SETUP.md)
- [Credentials Guide](CREDENTIALS_GUIDE.md)
- [Jira Setup Guide](JIRA_SETUP_GUIDE.md)
- [Complete Pipeline Guide](COMPLETE_PIPELINE_GUIDE.md)

