# ADR-002: Cosign key-based signing for local demo

## Status

Accepted

## Context

Keyless Sigstore signing needs network access to Fulcio/Rekor and is awkward for offline laptop demos.

## Decision

- `make bootstrap` generates a local Cosign keypair under `.cosign/` (gitignored).
- Sign/attest with `--tlog-upload=false`; verify with `--insecure-ignore-tlog`.
- Kyverno `verifyImages` uses the same public key with `insecureIgnoreTlog: true`.

## Consequences

+ Demo works air-gapped / behind corporate proxies
− Not the production trust model — migrate to keyless + KMS for real environments
