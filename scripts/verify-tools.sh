#!/usr/bin/env bash
# Verify required CLIs for the selected profile.
set -euo pipefail

PROFILE="${PROFILE:-minimal}"
missing=()

need() {
  if ! command -v "$1" >/dev/null 2>&1; then
    missing+=("$1")
  fi
}

need docker
need kubectl
need kind
need helm
need cosign
need syft
need trivy
need gitleaks

if [[ "$PROFILE" == "full" ]]; then
  need jq
fi

# Optional but recommended
optional=()
for c in ruff kubeconform checkov yq; do
  if ! command -v "$c" >/dev/null 2>&1; then
    optional+=("$c")
  fi
done

if ((${#missing[@]})); then
  echo "Missing required tools: ${missing[*]}"
  echo ""
  echo "Install hints (macOS / Homebrew):"
  echo "  brew install docker kind kubectl helm cosign syft trivy gitleaks jq"
  echo "  brew install ruff kubeconform checkov yq   # recommended"
  echo ""
  echo "Or see docs/getting-started.md"
  exit 1
fi

if ! docker info >/dev/null 2>&1; then
  echo "Docker daemon is not running. Start Docker Desktop / colima / orbstack and retry."
  exit 1
fi

echo "✓ Required tools present for profile=${PROFILE}"
if ((${#optional[@]})); then
  echo "  Optional missing (lint may skip): ${optional[*]}"
fi
