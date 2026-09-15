#!/usr/bin/env bash
set -euo pipefail

CLUSTER="${CLUSTER:-pipeline-demo}"
REGISTRY_NAME="${REGISTRY_NAME:-pipeline-registry}"

if kind get clusters 2>/dev/null | grep -qx "$CLUSTER"; then
  echo "→ Deleting kind cluster '${CLUSTER}'"
  kind delete cluster --name "$CLUSTER"
fi

if docker ps -a --format '{{.Names}}' | grep -qx "$REGISTRY_NAME"; then
  echo "→ Removing local registry '${REGISTRY_NAME}'"
  docker rm -f "$REGISTRY_NAME" >/dev/null
fi

echo "✓ Cluster and registry removed"
