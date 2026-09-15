# Profiles

## minimal

Laptop demonstration of the full **control plane story** without the heaviest operators.

Includes: kind, local registry, Tekton, Kyverno, Cosign/Syft/Trivy/Gitleaks, GitOps overlays.

## full

Adds: Argo CD, kube-prometheus-stack (Grafana/Prometheus NodePorts), Tekton Chains.

Requires roughly **12+ GB** RAM and more pull time on first bootstrap.
