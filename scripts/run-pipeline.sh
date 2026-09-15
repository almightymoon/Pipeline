#!/usr/bin/env bash
# Submit Tekton PipelineRun for source validation gates
set -euo pipefail

ROOT="${ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
CLUSTER="${CLUSTER:-pipeline-demo}"
CTX="kind-${CLUSTER}"
IMAGE="${IMAGE:-localhost:5001/demo-app}"
kubectl config use-context "$CTX" >/dev/null

RUN_NAME="demo-secure-pipeline-$(date +%s)"
NODE="$(kind get nodes --name "$CLUSTER" | head -n1)"

echo "→ Syncing repository sources onto kind node ${NODE}"
docker exec "$NODE" rm -rf /pipeline-src
docker exec "$NODE" mkdir -p /pipeline-src/examples /pipeline-src/security /pipeline-src/charts /pipeline-src/tests /pipeline-src/gitops /pipeline-src/platform
docker cp "$ROOT/examples/demo-app/." "$NODE:/pipeline-src/examples/demo-app/"
docker cp "$ROOT/security/scanning/." "$NODE:/pipeline-src/security/scanning/"
docker cp "$ROOT/charts/demo-app/." "$NODE:/pipeline-src/charts/demo-app/"
docker cp "$ROOT/gitops/." "$NODE:/pipeline-src/gitops/"
docker cp "$ROOT/platform/." "$NODE:/pipeline-src/platform/"
docker cp "$ROOT/tests/negative/." "$NODE:/pipeline-src/tests/negative/"

# Tekton workspaces cannot bind hostPath directly — expose via PV/PVC
kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pipeline-src-pv
spec:
  capacity:
    storage: 2Gi
  accessModes: ["ReadWriteOnce"]
  persistentVolumeReclaimPolicy: Retain
  storageClassName: pipeline-src
  hostPath:
    path: /pipeline-src
    type: Directory
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pipeline-source
  namespace: pipeline-ci
spec:
  accessModes: ["ReadWriteOnce"]
  storageClassName: pipeline-src
  resources:
    requests:
      storage: 2Gi
EOF

kubectl apply -f - <<EOF
apiVersion: tekton.dev/v1
kind: PipelineRun
metadata:
  name: ${RUN_NAME}
  namespace: pipeline-ci
  labels:
    app.kubernetes.io/part-of: pipeline-demo
    pipeline.devops/demo: "true"
spec:
  pipelineRef:
    name: secure-ci
  timeouts:
    pipeline: "30m"
    tasks: "15m"
  taskRunSpecs:
  - pipelineTaskName: gitleaks
    serviceAccountName: tekton-gitleaks
  - pipelineTaskName: sca
    serviceAccountName: tekton-scan
  - pipelineTaskName: iac-scan
    serviceAccountName: tekton-scan
  - pipelineTaskName: unit-test
    serviceAccountName: tekton-test
  workspaces:
  - name: source
    persistentVolumeClaim:
      claimName: pipeline-source
  - name: reports
    emptyDir: {}
  params:
  - name: image
    value: "${IMAGE}"
  - name: source-subdir
    value: "examples/demo-app"
  - name: git-url
    value: ""
  - name: verify-signature
    value: "false"
EOF

echo "→ Waiting for PipelineRun/${RUN_NAME}"
if ! kubectl -n pipeline-ci wait --for=condition=Succeeded "pipelinerun/${RUN_NAME}" --timeout=25m; then
  echo "Pipeline failed:"
  kubectl -n pipeline-ci describe "pipelinerun/${RUN_NAME}" || true
  kubectl -n pipeline-ci logs -l "tekton.dev/pipelineRun=${RUN_NAME}" --all-containers --tail=80 || true
  exit 1
fi

echo "✓ PipelineRun ${RUN_NAME} succeeded"
