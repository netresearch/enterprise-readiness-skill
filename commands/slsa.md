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
   - **Level 3**: Hardened builds, non-falsifiable provenance (slsa-github-generator)

2. **Check provenance generation**
   ```bash
   # Look for slsa-github-generator or similar
   grep -r "slsa-github-generator" .github/workflows/
   grep -r "attest-build-provenance" .github/workflows/

   # Check for .intoto.jsonl in releases
   gh release view --json assets --jq '.assets[].name' | grep intoto
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
   - Reference: `slsa-provenance.md` for implementation details

## Critical Implementation Gotchas

When implementing SLSA Level 3 with `slsa-github-generator`:

### base64-subjects Format
- **MUST** be sha256sum raw output (`HASH  FILENAME\n`) base64-encoded
- **NOT** JSON array - causes "unexpected sha256 hash format" error
- Correct: `sha256sum *.tar.gz | base64 -w0`

### compile-generator Workaround
- If exit code 2/127 during builder fetch, add `compile-generator: true`
- Builds from source (~2 min longer) but avoids binary fetch issues

### private-repository for Public Repos
- Generator may incorrectly detect public repos as private
- Add `private-repository: true` even for public repos
- Safe: just allows posting to Rekor transparency log

### workflow_run Trigger
- Use `workflow_run` after Release workflow, not `release: published`
- Ensures assets are fully uploaded before provenance generation

See `references/slsa-provenance.md` for complete implementation guide.
