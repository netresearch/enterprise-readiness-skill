# SLSA Level 3 Provenance Implementation Guide

Complete guide for implementing SLSA Level 3 provenance using `slsa-github-generator`.

## Overview

SLSA (Supply-chain Levels for Software Artifacts) Level 3 provides:
- Non-falsifiable provenance
- Isolated build environment
- Signed attestations via Sigstore
- Transparency log entries in Rekor

## Basic Workflow Setup

```yaml
name: SLSA Provenance

on:
  workflow_run:
    workflows: ["Release"]
    types: [completed]
  workflow_dispatch:
    inputs:
      version:
        description: 'Release version (e.g., v1.0.0)'
        required: true
        type: string

permissions: {}

jobs:
  provenance:
    name: Generate SLSA Provenance
    runs-on: ubuntu-latest
    if: github.event.workflow_run.conclusion == 'success'
    permissions:
      actions: read
      id-token: write
      contents: write
    outputs:
      subjects: ${{ steps.subjects.outputs.subjects }}
      has_subjects: ${{ steps.subjects.outputs.has_subjects }}
      version: ${{ steps.version.outputs.version }}
    steps:
      - name: Harden Runner
        uses: step-security/harden-runner@v2
        with:
          egress-policy: audit

      - name: Get version
        id: version
        run: |
          if [ "${{ github.event_name }}" = "workflow_dispatch" ]; then
            VERSION="${{ inputs.version }}"
          else
            VERSION="${{ github.event.workflow_run.head_branch }}"
          fi
          echo "version=$VERSION" >> "$GITHUB_OUTPUT"

      - name: Download release assets
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        run: |
          mkdir -p release-assets
          sleep 5  # Wait for release to be fully available
          gh release download "${{ steps.version.outputs.version }}" \
            --repo "${{ github.repository }}" \
            -D release-assets \
            --pattern "*.tar.gz" \
            --pattern "*.zip" || echo "Some assets may not be available"

      - name: Generate provenance subjects
        id: subjects
        run: |
          cd release-assets
          if ls *.tar.gz *.zip 1> /dev/null 2>&1; then
            # CRITICAL: base64-subjects expects sha256sum format, NOT JSON!
            sha256sum *.tar.gz *.zip > ../provenance-subjects.txt
            SUBJECTS_BASE64=$(cat ../provenance-subjects.txt | base64 -w0)
            echo "subjects=$SUBJECTS_BASE64" >> "$GITHUB_OUTPUT"
            echo "has_subjects=true" >> "$GITHUB_OUTPUT"
          else
            echo "has_subjects=false" >> "$GITHUB_OUTPUT"
          fi

  slsa-provenance:
    name: SLSA Level 3 Provenance
    needs: provenance
    if: needs.provenance.outputs.has_subjects == 'true'
    permissions:
      actions: read
      id-token: write
      contents: write
    uses: slsa-framework/slsa-github-generator/.github/workflows/generator_generic_slsa3.yml@v2.1.0
    with:
      base64-subjects: ${{ needs.provenance.outputs.subjects }}
      upload-assets: true
      upload-tag-name: ${{ needs.provenance.outputs.version }}
      # Compile from source to avoid binary fetch issues
      compile-generator: true
      # Workaround: generator may incorrectly detect public repo as private
      private-repository: true
```

## Critical Implementation Gotchas

### 1. base64-subjects Format (MOST COMMON ERROR)

The `base64-subjects` input expects **sha256sum raw output format**, NOT JSON.

**WRONG** (will fail with "unexpected sha256 hash format"):
```bash
# DO NOT DO THIS - creates JSON array
SUBJECTS=$(cat subjects.txt | awk '{print "{\"name\":\""$2"\",\"digest\":{\"sha256\":\""$1"\"}}"}' | jq -s -c '.')
SUBJECTS_BASE64=$(echo "$SUBJECTS" | base64 -w0)
```

**CORRECT**:
```bash
# sha256sum format: HASH  FILENAME (two spaces between hash and filename)
sha256sum *.tar.gz *.zip > subjects.txt
SUBJECTS_BASE64=$(cat subjects.txt | base64 -w0)
```

Expected format before base64 encoding:
```
61d6dcec3d8e7ce6f4c99b07d7a7f5de1237e598eadc15df12c0de968b474f98  myfile.tar.gz
1bc6c2d8414a725d502398cd5c2970f628c090d1b9644c2b5ae0436e8e3e1d14  myfile.zip
```

### 2. compile-generator Workaround

If you see errors like:
- `exit code 2` during "Fetching the builder"
- `exit code 127` (command not found)

Add `compile-generator: true` to build from source:

```yaml
uses: slsa-framework/slsa-github-generator/.github/workflows/generator_generic_slsa3.yml@v2.1.0
with:
  compile-generator: true  # Builds from source instead of downloading binary
```

**Trade-off**: Adds ~2 minutes to build time but avoids binary fetch issues.

### 3. private-repository for Public Repos

The generator may incorrectly detect public repositories as private, showing:
```
Repository is private. The workflow has halted in order to keep the repository
name from being exposed in the public transparency log.
```

**Solution**: Add `private-repository: true` even for public repos:

```yaml
uses: slsa-framework/slsa-github-generator/.github/workflows/generator_generic_slsa3.yml@v2.1.0
with:
  private-repository: true  # Safe for public repos - allows Rekor posting
```

This is safe because:
- For public repos: Just allows posting to Rekor transparency log (which is desired)
- For private repos: Explicitly acknowledges the repo name will be in public log

No license or payment required - this is just a safety flag.

### 4. workflow_run Trigger Best Practice

Use `workflow_run` instead of `release: published` to ensure assets are uploaded:

```yaml
on:
  workflow_run:
    workflows: ["Release"]  # Your release workflow name
    types: [completed]
```

This ensures:
- Release assets are fully uploaded before provenance generation
- Provenance runs only after successful release
- Assets are available for download and hashing

## Verification

Users can verify provenance with `slsa-verifier`:

```bash
# Install slsa-verifier
go install github.com/slsa-framework/slsa-verifier/v2/cli/slsa-verifier@latest

# Verify artifact against provenance
slsa-verifier verify-artifact \
  --provenance-path multiple.intoto.jsonl \
  --source-uri github.com/owner/repo \
  artifact.tar.gz
```

Add verification instructions to release notes:

```markdown
## Verification

This release includes SLSA Level 3 provenance. To verify:

1. Install slsa-verifier: `go install github.com/slsa-framework/slsa-verifier/v2/cli/slsa-verifier@latest`
2. Download the artifact and `multiple.intoto.jsonl`
3. Run: `slsa-verifier verify-artifact --provenance-path multiple.intoto.jsonl --source-uri github.com/OWNER/REPO artifact.tar.gz`
```

## Common Errors Reference

| Error | Cause | Solution |
|-------|-------|----------|
| `unexpected sha256 hash format` | Using JSON instead of sha256sum format | Use raw sha256sum output |
| `exit code 2` | Binary download failed | Add `compile-generator: true` |
| `exit code 127` | Command not found | Add `compile-generator: true` |
| `Repository is private` | False detection | Add `private-repository: true` |
| `Input required: path` | Previous step failed | Check provenance subjects step |
| No `.intoto.jsonl` uploaded | Generator step failed | Check all above issues |
| `exit code 27` | Final job aggregation failure | Fix upstream generator errors |

## Output Files

Successful provenance generation uploads to the release:
- `multiple.intoto.jsonl` - SLSA Level 3 provenance attestation

The `.intoto.jsonl` file contains:
- **Sigstore certificate** - Fulcio-signed ephemeral certificate
- **Rekor transparency log entry** - Immutable public record
- **DSSE envelope** - Dead Simple Signing Envelope with payload
- **Build provenance** - Builder identity, source URI, environment, parameters
- **Subject hashes** - SHA256 digests of all attested artifacts

## OpenSSF Scorecard Impact

Implementing SLSA provenance improves these Scorecard checks:
- **Signed-Releases** - Provenance provides cryptographic signatures
- **Token-Permissions** - Workflow uses minimal permissions
- **Pinned-Dependencies** - Generator should be pinned by SHA

## Security Considerations

1. **Pin generator by SHA**: Use full commit SHA, not just version tag
   ```yaml
   uses: slsa-framework/slsa-github-generator/.github/workflows/generator_generic_slsa3.yml@f7dd8c54c2067bafc12ca7a55595d5ee9b75204a # v2.1.0
   ```

2. **Minimal permissions**: Only grant `id-token: write` and `contents: write`

3. **Harden runner**: Add `step-security/harden-runner` for egress monitoring

4. **Verify in CI**: Consider adding verification step in downstream consumers

## References

- [SLSA Framework](https://slsa.dev/)
- [slsa-github-generator](https://github.com/slsa-framework/slsa-github-generator)
- [Sigstore](https://www.sigstore.dev/)
- [Rekor Transparency Log](https://rekor.sigstore.dev/)
- [slsa-verifier](https://github.com/slsa-framework/slsa-verifier)
