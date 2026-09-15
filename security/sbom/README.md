# SPDX / CycloneDX SBOM outputs land in reports/ during make demo
# This file documents the expected SBOM contract for the platform.

# Contract:
# 1. syft <image> -o spdx-json    → reports/sbom.spdx.json
# 2. syft <image> -o cyclonedx-json → reports/sbom.cdx.json
# 3. cosign attest --predicate reports/sbom.spdx.json --type spdxjson <image@digest>
# 4. Deployment references image by digest only
