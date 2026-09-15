# ADR-001: Tekton for CI, GitOps for CD

## Status

Accepted

## Context

A single pipeline that both builds and `kubectl apply`s to production couples concerns and weakens auditability.

## Decision

- **Tekton** owns validation, build-related gates, and security scanning.
- **GitOps overlays** (`gitops/*`) own desired image digests per environment.
- **Argo CD** (full profile) reconciles; minimal profile uses `kubectl apply -k` for the same layouts.

## Consequences

+ Clear promotion/rollback via Git
+ Admission policy can assume digests are intentional
− Requires discipline not to bypass GitOps with imperative deploys
