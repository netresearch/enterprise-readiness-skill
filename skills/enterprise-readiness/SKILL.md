---
name: enterprise-readiness
description: "Use when evaluating projects for production or enterprise readiness, implementing supply chain security (SLSA provenance, cosign signing, SBOMs), hardening CI/CD pipelines, establishing quality gates (TYPO3: CI matrix PHP 8.2-8.5 x TYPO3 12.4/13.4/14.3 LTS), pursuing OpenSSF Best Practices Badge (Passing/Silver/Gold) or OSPS Baseline levels, reviewing code quality, writing ADRs, or configuring Git hooks and CI pipelines."
license: "(MIT AND CC-BY-SA-4.0). See LICENSE-MIT and LICENSE-CC-BY-SA-4.0"
compatibility: "Requires gh CLI, python3, cosign, docker."
metadata:
  author: Netresearch DTT GmbH
  version: "4.12.0"
  repository: https://github.com/netresearch/enterprise-readiness-skill
allowed-tools: Bash(gh:*) Bash(python3:*) Bash(cosign:*) Read Write Glob Grep
---

# Enterprise Readiness Assessment

## When to Use

- Evaluating projects for production/enterprise readiness
- Supply chain security: SLSA provenance, cosign signing, SBOMs
- Hardening CI/CD pipelines and workflow permissions
- OpenSSF Best Practices Badge (Passing/Silver/Gold), OSPS Baseline (Level 1/2/3)
- Scorecard optimization (Token-Permissions, Branch-Protection, Pinned-Dependencies)
- Code review, ADRs, changelogs, security policy (SECURITY.md)

## Assessment Workflow

1. **Discovery**: Identify platform, languages, existing CI/CD, dependabot.yml
2. **Scoring**: Apply checklists; check Scorecard, badge criteria, coverage
3. **Gap Analysis**: List missing controls by severity
4. **Implementation**: Apply fixes (SHA-pin actions, harden permissions, add workflows)
5. **Verification**: Re-score and compare

## Mandatory Workflows & Badges

Required coverage: CI, CodeQL, OpenSSF Scorecard, dependency review, security (composer audit + SBOM). Each can be EITHER a dedicated `.github/workflows/<name>.yml` file OR a job in another workflow that delegates to the netresearch reusable workflow (`uses: netresearch/.github/.github/workflows/<name>.yml@…` or `uses: netresearch/typo3-ci-workflows/.github/workflows/security.yml@…`).
Badges: CI Status, Codecov (`codecov.io`), OpenSSF Scorecard, Best Practices, Baseline.
See `references/badges-and-workflows.md` for URL patterns.

## Key Hardening Patterns

- **Permissions**: Declare `permissions: contents: read` at workflow-level; grant write only per-job
- **SHA pinning**: Third-party actions pinned to SHA with version comment (`# v4.2.0`). Org-internal reusable workflows use `@main`
- **Harden-Runner**: `step-security/harden-runner` as first step in every job; prefer `egress-policy: block` with allowed-endpoints
- **Dependabot**: Configure `dependabot.yml` with all ecosystems (`composer`, `npm`, `github-actions`, `docker`); set up auto-merge workflow for dependency PRs using `pull_request_target`
- **Coverage**: Upload via `codecov-action`; configure `codecov.yml` with patch coverage threshold
- **Duplicate CI prevention**: Scope `push:` trigger to `branches: [main]` when `pull_request:` is also present
- **SLSA provenance**: Use `actions/attest-build-provenance` with `id-token: write` and `attestations: write` permissions; verify with `gh attestation verify`
- **Security policy**: Create `SECURITY.md` with vulnerability disclosure process and response SLA (Critical: 7 days, High: 30 days)

## Critical Rules

- **NEVER** interpolate `${{ github.event.* }}` or `${{ inputs.* }}` in `run:` blocks (script injection)
- **NEVER** guess action versions -- fetch from GitHub API and verify SHA against tags
- **ALWAYS** include `https://` URLs in badge justifications
- **ALWAYS** configure auto-merge for repos with Dependabot/Renovate

## References

| Reference | Use |
|-----------|-----|
| `references/general.md` | Always |
| `references/scorecard-playbook.md` | Scorecard optimization |
| `references/badges-and-workflows.md` | Badge URLs, workflows |
| `references/mandatory-requirements.md` | Checklist |
| `references/ci-patterns.md` | CI/CD, hooks |
| `references/code-review.md` | PR quality |
| `references/documentation.md` | ADRs, changelogs |
| `references/slsa-provenance.md` | SLSA Level 3 |
| `references/signed-releases.md` | Cosign/GPG |
| `references/openssf-badge-silver.md` | Silver |
| `references/openssf-badge-gold.md` | Gold |
| `references/openssf-badge-baseline.md` | OSPS Baseline |
| `references/harden-runner-guide.md` | Harden-Runner |
| `references/solo-maintainer-guide.md` | N/A criteria |

Related skills: `go-development`, `github-project`, `security-audit`, `git-workflow`.
