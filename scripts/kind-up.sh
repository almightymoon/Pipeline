#!/usr/bin/env bash
# Create kind cluster with local registry (localhost:5001).
set -euo pipefail

ROOT="${ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
CLUSTER="${CLUSTER:-pipeline-demo}"
REGISTRY_NAME="${REGISTRY_NAME:-pipeline-registry}"
REGISTRY_PORT="${REGISTRY_PORT:-5001}"
STATE_DIR="${STATE_DIR:-$ROOT/.demo-state}"

mkdir -p "$STATE_DIR"

# Local registry
if ! docker ps --format '{{.Names}}' | grep -qx "$REGISTRY_NAME"; then
  if docker ps -a --format '{{.Names}}' | grep -qx "$REGISTRY_NAME"; then
    docker start "$REGISTRY_NAME" >/dev/null
  else
    echo "→ Starting local registry on localhost:${REGISTRY_PORT}"
    docker run -d --restart=always -p "127.0.0.1:${REGISTRY_PORT}:5000" --name "$REGISTRY_NAME" \
      registry:2 >/dev/null
  fi
fi

reg_ip="$(docker inspect -f '{{.NetworkSettings.IPAddress}}' "$REGISTRY_NAME")"

if kind get clusters 2>/dev/null | grep -qx "$CLUSTER"; then
  echo "✓ kind cluster '${CLUSTER}' already exists"
else
  echo "→ Creating kind cluster '${CLUSTER}'"
  cat <<EOF | kind create cluster --name "$CLUSTER" --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
containerdConfigPatches:
- |-
  [plugins."io.containerd.grpc.v1.cri".registry.mirrors."localhost:${REGISTRY_PORT}"]
    endpoint = ["http://${REGISTRY_NAME}:5000"]
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
  extraPortMappings:
  - containerPort: 30080
    hostPort: 8080
    protocol: TCP
  - containerPort: 30300
    hostPort: 3000
    protocol: TCP
  - containerPort: 30909
    hostPort: 9090
    protocol: TCP
EOF
fi

# Connect registry to kind network
if docker network inspect kind >/dev/null 2>&1; then
  docker network connect kind "$REGISTRY_NAME" 2>/dev/null || true
fi

# Document registry for nodes (kind docs pattern)
for node in $(kind get nodes --name "$CLUSTER"); do
  docker exec "$node" mkdir -p "/etc/containerd/certs.d/localhost:${REGISTRY_PORT}"
  cat <<EOF | docker exec -i "$node" tee "/etc/containerd/certs.d/localhost:${REGISTRY_PORT}/hosts.toml" >/dev/null
server = "http://${REGISTRY_NAME}:5000"

[host."http://${REGISTRY_NAME}:5000"]
  capabilities = ["pull", "resolve", "push"]
EOF
done

kubectl cluster-info --context "kind-${CLUSTER}" >/dev/null
echo "kind-${CLUSTER}" > "$STATE_DIR/kube-context"
echo "localhost:${REGISTRY_PORT}" > "$STATE_DIR/registry"
echo "✓ Cluster ready (context=kind-${CLUSTER}, registry=localhost:${REGISTRY_PORT}, registry_ip=${reg_ip})"
