# SBOM contract

## What runs where

| Step | Host (`make demo`) | Tekton |
|------|--------------------|--------|
| Syft SPDX + CycloneDX | Yes → `reports/` | Task `sbom-syft` when Pipeline param `image` is set |
| Cosign sign + attest | Yes | Not default (needs registry push credentials in-cluster) |
| Cosign verify | Yes (+ `make promote`) | Task `cosign-verify` when `verify-signature=true` |

## Expected outputs (demo)

1. `reports/sbom.spdx.json`
2. `reports/sbom.cdx.json`
3. Cosign signature on `image@sha256:…`
4. GitOps pin via `gitops/<env>/kustomization.yaml` `images[].digest` only
