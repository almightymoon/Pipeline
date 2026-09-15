# DevSecOps Pipeline — reproducible local platform
# Profiles: minimal (laptop) | full (enterprise-style)

SHELL := /bin/bash
.SHELLFLAGS := -eu -o pipefail -c
.DEFAULT_GOAL := help

ROOT        := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
PROFILE     ?= minimal
CLUSTER     ?= pipeline-demo
REGISTRY    ?= localhost:5001
IMAGE       ?= $(REGISTRY)/demo-app
STATE_DIR   := $(ROOT)/.demo-state
COSIGN_DIR  := $(ROOT)/.cosign
REPORTS     := $(ROOT)/reports

export PROFILE CLUSTER REGISTRY IMAGE STATE_DIR COSIGN_DIR REPORTS ROOT

.PHONY: help bootstrap demo test lint security destroy promote rollback \
        verify-tools kind-up kind-down install-platform run-pipeline \
        negative-tests clean

help: ## Show available targets
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage: make \033[36m<target>\033[0m PROFILE=minimal|full\n\n"} \
		/^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-18s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)
	@echo ""
	@echo "Profiles:"
	@echo "  minimal  kind + registry + Tekton + Kyverno + demo pipeline (~4–8 GB RAM)"
	@echo "  full     + Argo CD + Prometheus/Grafana + Tekton Chains (~12+ GB RAM)"
	@echo ""

verify-tools: ## Check local CLI prerequisites
	@$(ROOT)/scripts/verify-tools.sh

bootstrap: verify-tools ## Create cluster and install platform components
	@mkdir -p "$(STATE_DIR)" "$(REPORTS)" "$(COSIGN_DIR)"
	@$(ROOT)/scripts/bootstrap.sh

demo: ## End-to-end: bootstrap (if needed) → pipeline → deploy → smoke verify
	@$(ROOT)/scripts/demo.sh

test: ## Unit + integration + smoke tests (no cluster required for unit)
	@mkdir -p "$(REPORTS)"
	@$(ROOT)/scripts/test.sh

lint: ## Lint Python, shell, Helm, and Kubernetes manifests
	@$(ROOT)/scripts/lint.sh

security: ## Run secret, dependency, IaC, and policy checks locally
	@mkdir -p "$(REPORTS)"
	@$(ROOT)/scripts/security.sh

negative-tests: ## Prove gates fail on intentionally bad fixtures
	@$(ROOT)/scripts/negative-tests.sh

promote: ## Promote immutable digest through environments (ENV=qa|performance|production)
	@test -n "$(ENV)" || (echo "Usage: make promote ENV=qa|performance|production"; exit 1)
	@$(ROOT)/scripts/promote.sh "$(ENV)"

rollback: ## Roll back an environment to the previous GitOps digest (ENV=dev|qa|...)
	@test -n "$(ENV)" || (echo "Usage: make rollback ENV=dev"; exit 1)
	@$(ROOT)/scripts/rollback.sh "$(ENV)"

destroy: ## Tear down kind cluster, registry, and local demo state
	@$(ROOT)/scripts/destroy.sh

clean: ## Remove reports and generated state (keeps cluster)
	rm -rf "$(REPORTS)" "$(STATE_DIR)"
	@echo "Cleaned reports and demo state."

kind-up: ## Create kind cluster + local registry only
	@$(ROOT)/scripts/kind-up.sh

kind-down: ## Delete kind cluster + local registry only
	@$(ROOT)/scripts/kind-down.sh

install-platform: ## Install Tekton/Kyverno/(Argo/monitoring) onto existing cluster
	@$(ROOT)/scripts/install-platform.sh

run-pipeline: ## Submit the demo PipelineRun and wait for completion
	@$(ROOT)/scripts/run-pipeline.sh
