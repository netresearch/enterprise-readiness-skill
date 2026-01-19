---
description: "Check and improve SLSA compliance level"
---

# SLSA Compliance Check

Assess and improve Supply-chain Levels for Software Artifacts (SLSA) compliance.

## Steps

1. **Determine current SLSA level**

   Check for:
   - **Level 1**: Build process documented, provenance available
   - **Level 2**: Hosted build service, signed provenance
   - **Level 3**: Hardened builds, non-falsifiable provenance

2. **Check provenance generation**
   ```bash
   # Look for slsa-github-generator or similar
   grep -r "slsa-github-generator" .github/workflows/
   grep -r "attest-build-provenance" .github/workflows/
   ```

3. **Verify artifact signing**
   ```bash
   # Check for sigstore/cosign usage
   grep -r "cosign" .github/workflows/
   grep -r "sigstore" .github/workflows/
   ```

4. **Generate SLSA report**

   ```
   ## SLSA Compliance Report

   Current Level: X
   Target Level: X

   ### Requirements Met
   - [x] Scripted build
   - [x] Build service
   - [ ] Signed provenance
   - [ ] Isolated builds

   ### Actions Required for Level X
   1. Add provenance generation
   2. Enable artifact signing
   3. Implement hermetic builds
   ```

5. **Provide upgrade path**
   - Specific workflow changes needed
   - Link to SLSA documentation
