# Docker Image Deployment Pipeline - Quick Start

## 🚀 Get Started in 5 Minutes

### Step 1: Add Your Docker Images

Edit `images-to-deploy.yaml`:

```yaml
images:
  - image: nginx:latest
    name: nginx-demo
    namespace: default
    port: 80
    node_port: 30080
    replicas: 1
    environment: staging
```

### Step 2: Commit and Push

```bash
git add images-to-deploy.yaml
git commit -m "Deploy nginx to VPS"
git push
```

### Step 3: Wait for Deployment

Check GitHub Actions tab for progress.

### Step 4: Access Your Application

Visit: `http://213.109.162.134:30080`

### Step 5: Check Jira

A new Jira issue will be created with:
- ✅ All deployed services
- 🌐 Access URLs
- 📊 Deployment status
- 🔧 Management commands

## Configuration Options

| Field | Description | Example |
|-------|-------------|---------|
| `image` | Docker Hub image | `nginx:latest` |
| `name` | Deployment name | `nginx-demo` |
| `namespace` | K8s namespace | `default` |
| `port` | Container port | `80` |
| `node_port` | External port (30000-32767) | `30080` |
| `replicas` | Number of pods | `1` |
| `environment` | Environment label | `staging` |

## Multiple Images Example

```yaml
images:
  - image: nginx:latest
    name: nginx-demo
    port: 80
    node_port: 30080
    
  - image: httpd:latest
    name: apache-demo
    port: 80
    node_port: 30081
    
  - image: node:18-alpine
    name: nodejs-demo
    port: 3000
    node_port: 30082
```

## Common Commands

```bash
# View deployments
kubectl get deployments -n <namespace>

# View services
kubectl get svc -n <namespace>

# View pods
kubectl get pods -n <namespace>

# Check logs
kubectl logs -f <pod-name> -n <namespace>

# Restart deployment
kubectl rollout restart deployment/<name> -n <namespace>
```

## Troubleshooting

**Deployment not working?**
```bash
kubectl get pods -n <namespace>
kubectl describe pod <pod-name> -n <namespace>
kubectl logs <pod-name> -n <namespace>
```

**Can't access application?**
```bash
# Check if service is running
kubectl get svc -n <namespace>

# Verify firewall
sudo ufw status
```

## Full Documentation

See [IMAGE_DEPLOYMENT_GUIDE.md](docs/IMAGE_DEPLOYMENT_GUIDE.md) for complete guide.

## GitHub Secrets Required

- `KUBECONFIG` - Base64 encoded kubeconfig
- `VPS_USER` - VPS SSH username
- `VPS_PASSWORD` - VPS SSH password
- `JIRA_URL` - Your Jira URL
- `JIRA_EMAIL` - Your Jira email
- `JIRA_API_TOKEN` - Jira API token
- `JIRA_PROJECT_KEY` - Jira project key (e.g., ML)

## Support

- 📚 Full Guide: [docs/IMAGE_DEPLOYMENT_GUIDE.md](docs/IMAGE_DEPLOYMENT_GUIDE.md)
- 🐛 Issues: Check GitHub Actions logs
- 📝 Jira: Check created issues for deployment details

