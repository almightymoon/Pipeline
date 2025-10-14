# 🚀 K3s Kubernetes Cluster Setup Guide

## Overview

This guide will help you set up a production-ready K3s Kubernetes cluster on your VPS (213.109.162.134) for automated Docker deployments from your CI/CD pipeline.

## 📋 Prerequisites

- **VPS:** Ubuntu/Debian Linux server with root access
- **VPS IP:** 213.109.162.134
- **SSH Access:** Password or SSH key-based authentication
- **Minimum Resources:** 2GB RAM, 2 CPU cores, 20GB storage
- **Local Machine:** macOS/Linux with SSH client

## 🚀 Quick Start

### Automated Setup (Recommended)

Run the automated setup script from your local machine:

```bash
cd /Users/moon/Documents/pipeline

# Set your VPS credentials (optional, defaults to root@213.109.162.134)
export VPS_IP="213.109.162.134"
export VPS_USER="root"

# Run the setup script
./scripts/setup-k3s-cluster.sh
```

The script will:
1. ✅ Prepare the system (install dependencies, configure kernel)
2. ✅ Install K3s Kubernetes
3. ✅ Configure kubectl
4. ✅ Install Helm package manager
5. ✅ Create necessary namespaces
6. ✅ Install NGINX Ingress Controller
7. ✅ Install Metrics Server for monitoring
8. ✅ Download kubeconfig for GitHub Actions

**Time Required:** ~5-10 minutes

---

## 📝 Manual Setup (Alternative)

If you prefer to set up manually or troubleshoot:

### Step 1: Connect to VPS

```bash
ssh root@213.109.162.134
```

### Step 2: System Preparation

```bash
# Update system
apt-get update && apt-get upgrade -y

# Install required packages
apt-get install -y curl wget git ca-certificates

# Disable swap (required for Kubernetes)
swapoff -a
sed -i '/ swap / s/^/#/' /etc/fstab

# Load kernel modules
cat <<EOF | tee /etc/modules-load.d/k3s.conf
br_netfilter
overlay
ip_vs
ip_vs_rr
ip_vs_wrr
ip_vs_sh
nf_conntrack
EOF

modprobe br_netfilter overlay ip_vs ip_vs_rr ip_vs_wrr ip_vs_sh nf_conntrack

# Configure sysctl
cat <<EOF | tee /etc/sysctl.d/k3s.conf
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
net.ipv6.conf.all.forwarding = 1
vm.swappiness = 0
EOF

sysctl --system
```

### Step 3: Install K3s

```bash
# Install K3s with custom configuration
curl -sfL https://get.k3s.io | sh -s - \
    --write-kubeconfig-mode 644 \
    --disable traefik \
    --node-external-ip 213.109.162.134 \
    --bind-address 213.109.162.134 \
    --advertise-address 213.109.162.134 \
    --tls-san 213.109.162.134 \
    --node-name k3s-master

# Wait for K3s to start
sleep 10

# Check status
systemctl status k3s
kubectl get nodes
```

### Step 4: Configure kubectl

```bash
# Setup kubectl config
mkdir -p ~/.kube
cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
chmod 600 ~/.kube/config

# Update server address
sed -i "s/127.0.0.1/213.109.162.134/g" ~/.kube/config

# Test connection
kubectl get nodes
kubectl get pods -A
```

### Step 5: Install Helm

```bash
# Install Helm 3
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Add repositories
helm repo add stable https://charts.helm.sh/stable
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
```

### Step 6: Create Namespaces

```bash
# Create pipeline namespaces
kubectl create namespace pipeline-apps
kubectl create namespace ml-pipeline
kubectl create namespace monitoring
kubectl create namespace ingress-nginx

# Label namespaces
kubectl label namespace pipeline-apps environment=production
kubectl label namespace ml-pipeline environment=production
```

### Step 7: Install NGINX Ingress

```bash
# Install NGINX Ingress Controller
helm upgrade --install ingress-nginx ingress-nginx \
    --repo https://kubernetes.github.io/ingress-nginx \
    --namespace ingress-nginx \
    --create-namespace \
    --set controller.service.type=NodePort \
    --set controller.service.nodePorts.http=30080 \
    --set controller.service.nodePorts.https=30443 \
    --wait
```

### Step 8: Install Metrics Server

```bash
# Install Metrics Server
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Patch for K3s compatibility
kubectl patch deployment metrics-server -n kube-system --type='json' \
    -p='[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--kubelet-insecure-tls"}]'
```

---

## 🔐 GitHub Actions Integration

### Step 1: Get Kubeconfig

From your **local machine**:

```bash
# Download kubeconfig from VPS
scp root@213.109.162.134:/etc/rancher/k3s/k3s.yaml ~/.kube/config-vps

# Update server address (on macOS)
sed -i '' "s/127.0.0.1/213.109.162.134/g" ~/.kube/config-vps

# On Linux, use:
# sed -i "s/127.0.0.1/213.109.162.134/g" ~/.kube/config-vps

# Base64 encode for GitHub Secret
cat ~/.kube/config-vps | base64 > ~/.kube/kubeconfig-base64.txt
```

### Step 2: Add GitHub Secret

Using GitHub CLI (recommended):

```bash
gh secret set KUBECONFIG < ~/.kube/kubeconfig-base64.txt
```

Or manually:
1. Go to your GitHub repository
2. Navigate to **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Name: `KUBECONFIG`
5. Value: Paste the base64-encoded content from `kubeconfig-base64.txt`
6. Click **Add secret**

### Step 3: Update Workflow

Your workflow should already have the deployment step configured. Verify it uses the secret:

```yaml
- name: Deploy to Kubernetes
  env:
    KUBECONFIG_DATA: ${{ secrets.KUBECONFIG }}
  run: |
    echo "$KUBECONFIG_DATA" | base64 -d > /tmp/kubeconfig
    export KUBECONFIG=/tmp/kubeconfig
    kubectl get nodes
```

---

## ✅ Verification

### Check Cluster Status

```bash
ssh root@213.109.162.134

# View nodes
kubectl get nodes -o wide

# View all pods
kubectl get pods -A

# View services
kubectl get svc -A

# View namespaces
kubectl get namespaces

# Check cluster info
kubectl cluster-info
```

### Test Deployment

Create a test deployment:

```bash
# Create a test pod
kubectl run test-nginx --image=nginx:latest -n pipeline-apps

# Expose it as NodePort
kubectl expose pod test-nginx --type=NodePort --port=80 -n pipeline-apps

# Get the NodePort
kubectl get svc test-nginx -n pipeline-apps

# Access it (replace <NODE_PORT> with actual port)
curl http://213.109.162.134:<NODE_PORT>

# Cleanup
kubectl delete pod test-nginx -n pipeline-apps
kubectl delete svc test-nginx -n pipeline-apps
```

---

## 🔧 Configuration

### NodePort Range

By default, K3s uses NodePort range **30000-32767**. Your applications will be accessible at:
- `http://213.109.162.134:<NodePort>`

### Ingress Access

With NGINX Ingress Controller:
- **HTTP:** `http://213.109.162.134:30080`
- **HTTPS:** `https://213.109.162.134:30443`

### Resource Limits

Edit `/etc/rancher/k3s/config.yaml` to set cluster-wide limits:

```yaml
# Resource reservations
kubelet-arg:
  - "kube-reserved=cpu=200m,memory=512Mi"
  - "system-reserved=cpu=200m,memory=512Mi"
```

---

## 📊 Monitoring

### View Cluster Resources

```bash
# Node resources
kubectl top nodes

# Pod resources
kubectl top pods -A

# Describe node
kubectl describe node k3s-master

# View events
kubectl get events -A --sort-by='.lastTimestamp'
```

### Check Logs

```bash
# K3s service logs
journalctl -u k3s -f

# Pod logs
kubectl logs <pod-name> -n <namespace>

# Follow logs
kubectl logs -f <pod-name> -n <namespace>
```

---

## 🛠️ Troubleshooting

### Common Issues

#### 1. Can't Connect to Cluster from GitHub Actions

**Error:** `Unable to connect to the server`

**Solution:**
- Verify kubeconfig is base64 encoded: `cat ~/.kube/config-vps | base64 | wc -c`
- Check the secret is added to GitHub: `gh secret list`
- Ensure VPS IP is accessible from GitHub Actions runners
- Test connection locally: `export KUBECONFIG=~/.kube/config-vps && kubectl get nodes`

#### 2. Pods Stuck in Pending

**Error:** `0/1 nodes are available: 1 Insufficient memory/cpu`

**Solution:**
```bash
# Check node resources
kubectl describe node k3s-master

# Check pod resource requests
kubectl describe pod <pod-name> -n <namespace>

# Adjust pod resources in deployment
```

#### 3. NodePort Not Accessible

**Error:** Can't access `http://213.109.162.134:<NodePort>`

**Solution:**
```bash
# Check firewall rules
ufw status

# Allow NodePort range
ufw allow 30000:32767/tcp

# Check service
kubectl get svc -n <namespace>
kubectl describe svc <service-name> -n <namespace>

# Check if pod is running
kubectl get pods -n <namespace>
```

#### 4. Metrics Server Not Working

**Error:** `error: Metrics API not available`

**Solution:**
```bash
# Check metrics-server pod
kubectl get pods -n kube-system | grep metrics-server

# View logs
kubectl logs -n kube-system deployment/metrics-server

# Restart metrics-server
kubectl rollout restart deployment metrics-server -n kube-system
```

#### 5. K3s Not Starting

**Error:** `Failed to start k3s.service`

**Solution:**
```bash
# Check logs
journalctl -u k3s -n 100 --no-pager

# Check system resources
free -h
df -h

# Restart K3s
systemctl restart k3s
systemctl status k3s
```

---

## 🔄 Maintenance

### Update K3s

```bash
# Check current version
k3s --version

# Update K3s
curl -sfL https://get.k3s.io | sh -

# Restart service
systemctl restart k3s
```

### Backup

```bash
# Backup etcd data
cp -r /var/lib/rancher/k3s/server /backup/k3s-$(date +%Y%m%d)

# Backup kubeconfig
cp /etc/rancher/k3s/k3s.yaml /backup/kubeconfig-$(date +%Y%m%d)
```

### Clean Up Resources

```bash
# Delete old pods
kubectl delete pod --field-selector=status.phase=Succeeded -A
kubectl delete pod --field-selector=status.phase=Failed -A

# Clean up old images
crictl rmi --prune

# Check disk usage
df -h /var/lib/rancher
```

---

## 🚀 Next Steps

After setting up your cluster:

1. **Test the Pipeline:**
   ```bash
   # Trigger a workflow run
   gh workflow run scan-external-repos.yml
   ```

2. **Monitor Deployments:**
   ```bash
   watch kubectl get pods -n pipeline-apps
   ```

3. **Access Deployed Apps:**
   - Check NodePort: `kubectl get svc -n pipeline-apps`
   - Access: `http://213.109.162.134:<NodePort>`

4. **View Logs:**
   ```bash
   kubectl logs -f deployment/<deployment-name> -n pipeline-apps
   ```

5. **Scale Deployments:**
   ```bash
   kubectl scale deployment <deployment-name> --replicas=3 -n pipeline-apps
   ```

---

## 📚 Additional Resources

- [K3s Documentation](https://docs.k3s.io/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Helm Documentation](https://helm.sh/docs/)
- [NGINX Ingress Controller](https://kubernetes.github.io/ingress-nginx/)
- [Kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)

---

## ✅ Success Checklist

- [ ] K3s installed and running
- [ ] kubectl configured and working
- [ ] Helm installed
- [ ] Namespaces created (pipeline-apps, ml-pipeline, monitoring)
- [ ] NGINX Ingress Controller deployed
- [ ] Metrics Server installed
- [ ] Kubeconfig added to GitHub Secrets
- [ ] Test deployment successful
- [ ] NodePort accessible from outside
- [ ] Pipeline can deploy to cluster

---

## 🎉 You're All Set!

Your K3s Kubernetes cluster is now ready for automated Docker deployments from your CI/CD pipeline! 

**Test it out:**
```bash
# Run a pipeline to deploy example-voting-app
gh workflow run scan-external-repos.yml
```

**Happy Kubernetes-ing! 🚀**

