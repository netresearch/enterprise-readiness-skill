---
name: enterprise-readiness
description: "Use when evaluating projects for production readiness, implementing supply chain security (SLSA, signing, SBOMs), hardening CI/CD pipelines, establishing quality gates, or pursuing OpenSSF Best Practices Badge."
---

# Enterprise Readiness Assessment

## When to Use

- Evaluating projects for production/enterprise readiness
- Implementing supply chain security (SLSA, signing, SBOMs)
- Hardening CI/CD pipelines
- Establishing quality gates
- Pursuing OpenSSF Best Practices Badge (Passing/Silver/Gold)
- Pursuing OpenSSF OSPS Baseline levels (1/2/3)
- Reviewing code or PRs for quality
- Writing ADRs, changelogs, or migration guides
- Configuring Git hooks or CI pipelines

## Quick Reference

### Mandatory Badges

| Badge | URL Pattern |
|-------|-------------|
| CI Status | `github.com/ORG/REPO/actions/workflows/ci.yml/badge.svg` |
| Codecov | `codecov.io/gh/ORG/REPO/graph/badge.svg` |
| OpenSSF Scorecard | `api.securityscorecards.dev/projects/github.com/ORG/REPO/badge` |
| OpenSSF Best Practices | `www.bestpractices.dev/projects/PROJECT_ID/badge` |
| OpenSSF Baseline | `www.bestpractices.dev/projects/PROJECT_ID/baseline` |

### Mandatory Workflows

| Workflow | File | Purpose |
|----------|------|---------|
| CI | `ci.yml` | Build, test, lint |
| CodeQL | `codeql.yml` | Security scanning |
| Scorecard | `scorecard.yml` | OpenSSF Scorecard |
| Dependency Review | `dependency-review.yml` | PR CVE check |

## Scorecard Quick Wins

| Check | Quick Fix | Impact |
|-------|-----------|--------|
| Token-Permissions | `permissions: {}` at workflow-level, `write` only per-job | 0->10 |
| Branch-Protection | `required_approving_review_count: 1` + auto-approve | 0->8 |
| Security-Policy | SECURITY.md + private vulnerability reporting | 4->10 |
| Pinned-Dependencies | SHA-pin all actions (except SLSA generator) | 8->10 |

## Assessment Workflow

1. **Discovery**: Identify platform, languages, existing CI/CD
2. **Scoring**: Apply checklists from references based on stack
3. **Badge Assessment**: Check OpenSSF criteria status
4. **Gap Analysis**: List missing controls by severity
5. **Implementation**: Apply fixes using scripts and templates
6. **Verification**: Re-score and compare

## References

| Reference | When to Load |
|-----------|--------------|
| `references/general.md` | Always (universal checks) |
| `references/github.md` | GitHub-hosted projects |
| `references/go.md` | Go projects |
| `references/mandatory-requirements.md` | Badge/workflow/Codecov setup checklist |
| `references/scorecard-playbook.md` | Raising Scorecard ~6.8 to ~9.0 |
| `references/cve-workflow.md` | CVE triage and response |
| `references/code-review.md` | PR quality checks |
| `references/documentation.md` | ADRs, changelogs, migration guides |
| `references/ci-patterns.md` | CI/CD pipelines, Git hooks |
| `references/openssf-badge-silver.md` | Silver badge criteria |
| `references/openssf-badge-gold.md` | Gold badge criteria |
| `references/openssf-badge-baseline.md` | OSPS Baseline levels 1/2/3 |
| `references/badge-submission-api.md` | Programmatic badge data submission gotchas |
| `references/slsa-provenance.md` | SLSA Level 3 implementation |
| `references/signed-releases.md` | Cosign/GPG signing |
| `references/solo-maintainer-guide.md` | N/A criteria justification |

## Scripts & Templates

| Directory | Contents |
|-----------|----------|
| `scripts/` | Badge verification, coverage checks, SPDX headers, signed tag verification |

## Critical Rules

- **NEVER** interpolate `${{ github.event.* }}` in `run:` blocks (script injection)
- **NEVER** guess action versions -- always fetch from GitHub API
- **ALWAYS** use SHA pins for actions with version comments
- **ALWAYS** verify commit hashes against official tags
- **ALWAYS** include `https://` URLs in badge justification text (platform rejects criteria without URLs)
- **NEVER** URL-decode session cookies when submitting badge data (breaks authentication silently)

## Related Skills

| Skill | Purpose |
|-------|---------|
| `go-development` | Go code patterns, testing |
| `github-project` | Repository setup, branch protection |
| `security-audit` | Deep security audits (OWASP, XXE, SQLi) |
| `git-workflow` | Git branching, commits, PR workflows |
