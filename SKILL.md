---
name: enterprise-readiness
description: "Assess and enhance software projects for enterprise-grade security, quality, and automation. This skill should be used when evaluating projects for production readiness, implementing supply chain security (SLSA, signing, SBOMs), hardening CI/CD pipelines, or establishing quality gates. Aligned with OpenSSF Scorecard, Best Practices Badge, SLSA Framework, and S2C2F. Triggers on keywords: enterprise, production ready, security hardening, supply chain security, SLSA, OpenSSF Scorecard, release automation, security assessment."
---

# Enterprise Readiness Assessment v2.0

A comprehensive framework for assessing and improving software projects to meet enterprise-grade
standards for security, quality, and automation. Aligned with major OpenSSF programs.

## OpenSSF Framework Alignment

This skill provides coverage across four major OpenSSF frameworks:

| Framework | Focus | Coverage |
|-----------|-------|----------|
| [OpenSSF Scorecard](https://securityscorecards.dev/) | Automated security health metrics | 18/20 checks (~90%) |
| [Best Practices Badge](https://www.bestpractices.dev/) | Project maturity assessment | ~70% of Passing criteria |
| [SLSA Framework](https://slsa.dev/) | Supply chain integrity levels | Full L1-L3 tracking |
| [S2C2F](https://github.com/ossf/s2c2f) | Secure dependency consumption | 6/8 practices (~75%) |

## Purpose

Systematically evaluate and enhance projects across five dimensions:

1. **Governance & Policy** - Security policies, SLAs, maintenance, licensing
2. **Supply Chain Security** - Provenance, signing, SBOMs, binary hygiene
3. **Dependency Consumption** - Ingestion controls, vulnerability scanning, license compliance
4. **Quality Gates** - Testing, coverage, static analysis, secret scanning
5. **Platform Hardening** - CI/CD security, workflow injection prevention, code review

## Assessment Workflow

### Phase 1: Discovery

1. Identify the hosting platform (GitHub, GitLab, Bitbucket, Azure DevOps)
2. Identify primary language(s) (Go, Python, TypeScript, Rust, Java)
3. Scan existing CI/CD configuration files
4. Check for security tooling presence (SBOM, signing, scanning)
5. Review repository security settings

### Phase 2: Scoring

Apply checklists using **Dynamic Denominator** scoring:
- Calculate `Score = (Points_Earned / Max_Points_Applicable) * 100`
- Skip platform/language sections that don't apply
- This ensures fair scoring across different tech stacks

Load appropriate reference files based on discovered stack:
- `references/general.md` - Always apply (60 points, universal checks)
- `references/github.md` - For GitHub-hosted projects (40 points)
- `references/go.md` - For Go projects (20 points)

**Scoring Example**:
- GitHub + Go project: Max = 60 + 40 + 20 = 120 points
- GitHub + Python project: Max = 60 + 40 = 100 points (no Go checks)
- GitLab + Go project: Max = 60 + 20 = 80 points (no GitHub checks)

### Phase 3: Gap Analysis

1. List missing security controls with severity:
   - **Critical Blockers** - Must fix immediately (script injection, no branch protection)
   - **High Priority** - Should fix before production (missing SLSA, no code review)
   - **Medium Priority** - Plan for improvement (coverage gaps, missing SBOM)
   - **Low Priority** - Nice to have (documentation gaps)

2. Map findings to OpenSSF Scorecard checks for context

3. Prioritize by impact and implementation effort

### Phase 4: Implementation

For each identified gap:
1. Provide specific code/configuration from this skill's patterns
2. Reference implementation patterns from the assessed project
3. Verify implementation works
4. Re-score after changes

## Scoring Interpretation

| Score | Grade | Status |
|-------|-------|--------|
| 90-100 | A | Enterprise Ready |
| 80-89 | B | Production Ready (minor gaps) |
| 70-79 | C | Development Ready (needs hardening) |
| 60-69 | D | Basic (significant gaps) |
| Below 60 | F | Not Ready (major improvements needed) |

## Output Format

Generate a structured report:

```markdown
# Enterprise Readiness Assessment

## Executive Summary
- **Score**: X/100 (Grade: Y)
- **Platform**: GitHub/GitLab/etc.
- **Language(s)**: Go/Python/etc.
- **OpenSSF Scorecard Alignment**: X/20 checks passing

## Critical Blockers (Stop-Ship)
[Items requiring immediate attention - script injection, exposed secrets, etc.]

## High Priority Findings
[Security gaps that should be addressed before production]

## Detailed Findings

### Governance & Policy (X/10 points)
[Security policy, licensing, maintenance status]

### Supply Chain Security (X/15 points)
[Provenance, signing, SBOM, binary artifacts]

### Dependency Consumption (X/10 points)
[S2C2F alignment, vulnerability scanning, license compliance]

### Quality Gates (X/10 points)
[Coverage, static analysis, secret scanning]

### Testing Layers (X/10 points)
[Unit, integration, security testing]

### Platform-Specific (X/Y points)
[GitHub/GitLab specific findings]

### Language-Specific (X/Y points)
[Go/Python/TypeScript specific findings]

## OpenSSF Scorecard Mapping
| Check | Status | Notes |
|-------|--------|-------|
| Dangerous-Workflow | ✅/❌ | ... |
| Code-Review | ✅/❌ | ... |
| ... | ... | ... |

## Improvement Roadmap
[Prioritized action items with implementation guidance]
```

## Critical Security Patterns

### Dangerous Workflow Prevention (CRITICAL)

**NEVER interpolate user input directly in workflow scripts:**

```yaml
# DANGEROUS - Script injection vulnerability
- run: echo "Title: ${{ github.event.issue.title }}"

# SAFE - Use environment variables
- name: Process issue
  env:
    TITLE: ${{ github.event.issue.title }}
  run: echo "Title: $TITLE"
```

### SLSA Level 3 Provenance (GitHub)

```yaml
uses: slsa-framework/slsa-github-generator/.github/workflows/builder_go_slsa3.yml@v2.1.0
with:
  go-version-file: go.mod
  config-file: .slsa-goreleaser/${{ matrix.target }}.yml
  evaluated-envs: "VERSION:${{ github.ref_name }}, COMMIT:${{ github.sha }}"
  upload-assets: true
```

**Critical**: Use `{{ .Env.VERSION }}` in config files, not `{{ .Tag }}`.

### Keyless Signing with Cosign

```yaml
- uses: sigstore/cosign-installer@v3.8.2
- run: |
    cosign sign-blob --yes \
      --output-certificate file.pem \
      --output-signature file.sig \
      file.txt
```

### Workflow Hardening

```yaml
permissions: read-all  # At workflow level

jobs:
  build:
    permissions:
      contents: write  # Escalate only as needed
    steps:
      - uses: step-security/harden-runner@0634a2670c59f64b4a01f0f96f84700a4088b9f0 # v2.12.0
        with:
          egress-policy: audit
      - uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683 # v4.2.2
```

### Quality Gate Enforcement

```yaml
- name: Check coverage threshold
  run: |
    COVERAGE=$(go tool cover -func=coverage.out | grep total | awk '{print $3}' | tr -d '%')
    if (( $(echo "$COVERAGE < 60" | bc -l) )); then
      echo "Coverage $COVERAGE% is below 60% threshold"
      exit 1
    fi
```

## Common Pitfalls (Lessons Learned)

1. **Script Injection**: Never use `${{ github.event.* }}` directly in `run:` blocks
2. **SLSA Template Syntax**: Use `{{ .Env.VERSION }}` with `evaluated-envs`, not `{{ .Tag }}`
3. **GitHub CLI Context**: Jobs using `gh` commands need `actions/checkout` first
4. **YAML Heredocs**: Careful indentation required for multi-line scripts
5. **Merge Queue Events**: Must handle `merge_group` event type explicitly
6. **Action Pinning**: SHA pins prevent supply chain attacks but need Dependabot for updates
7. **pull_request_target**: Dangerous trigger - never checkout PR code with it
8. **Binary Artifacts**: Generated binaries in source repos are unverifiable

## Extensibility

This skill uses a modular architecture. Additional platform and language modules
can be added to `references/` following the same checklist structure:

**Available Modules:**
- `references/general.md` - Universal checks (60 points)
- `references/github.md` - GitHub-specific (40 points)
- `references/go.md` - Go-specific (20 points)

**Future Platform Modules:**
- `references/gitlab.md`
- `references/bitbucket.md`
- `references/azure-devops.md`

**Future Language Modules:**
- `references/python.md`
- `references/typescript.md`
- `references/rust.md`
- `references/java.md`

## Resources

- [SLSA Framework](https://slsa.dev/) - Supply chain security levels
- [OpenSSF Scorecard](https://securityscorecards.dev/) - Security health metrics
- [OpenSSF Best Practices Badge](https://www.bestpractices.dev/) - Project maturity
- [S2C2F Framework](https://github.com/ossf/s2c2f) - Secure consumption
- [Sigstore/Cosign](https://docs.sigstore.dev/) - Keyless signing
- [step-security/harden-runner](https://github.com/step-security/harden-runner) - Workflow hardening
- [slsa-github-generator](https://github.com/slsa-framework/slsa-github-generator) - SLSA builders
