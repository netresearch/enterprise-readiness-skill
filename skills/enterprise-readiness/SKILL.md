---
name: enterprise-readiness
description: "Use when evaluating projects for production or enterprise readiness, implementing supply chain security (SLSA provenance, cosign signing, SBOMs), hardening CI/CD pipelines, establishing quality gates, pursuing OpenSSF Best Practices Badge (Passing/Silver/Gold) or OSPS Baseline levels, reviewing code quality, writing ADRs, or configuring Git hooks and CI pipelines."
license: "(MIT AND CC-BY-SA-4.0). See LICENSE-MIT and LICENSE-CC-BY-SA-4.0"
compatibility: "Requires gh CLI, python3, cosign, docker."
metadata:
  author: Netresearch DTT GmbH
  version: "4.8.0"
  repository: https://github.com/netresearch/enterprise-readiness-skill
allowed-tools: Bash(gh:*) Bash(python3:*) Bash(cosign:*) Read Write Glob Grep
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

Required badges: CI Status, Codecov, OpenSSF Scorecard, Best Practices, Baseline.
Required workflows: `ci.yml`, `codeql.yml`, `scorecard.yml`, `dependency-review.yml`.
See `references/badges-and-workflows.md` for URL patterns and Scorecard quick wins.

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
| `references/badges-and-workflows.md` | Badge URLs, workflow list, Scorecard quick wins |
| `references/general.md` | Always (universal checks) |
| `references/github.md` | GitHub-hosted projects |
| `references/go.md` | Go projects |
| `references/mandatory-requirements.md` | Badge/workflow/Codecov setup checklist |
| `references/scorecard-playbook.md` | Raising Scorecard ~6.8 to ~9.0 |
| `references/cve-workflow.md` | CVE triage and response |
| `references/code-review.md` | PR quality checks |
| `references/documentation.md` | ADRs, changelogs, migration guides |
| `references/ci-patterns.md` | CI/CD pipelines, Git hooks |
| `references/ci-docker-worktree.md` | Docker/worktree CI robustness |
| `references/openssf-badge-silver.md` | Silver badge criteria |
| `references/openssf-badge-gold.md` | Gold badge criteria |
| `references/openssf-badge-baseline.md` | OSPS Baseline levels |
| `references/badge-submission-api.md` | Badge API submission gotchas |
| `references/slsa-provenance.md` | SLSA Level 3 implementation |
| `references/signed-releases.md` | Cosign/GPG signing |
| `references/solo-maintainer-guide.md` | N/A criteria justification |

## Scripts & Templates

| Directory | Contents |
|-----------|----------|
| `scripts/` | Badge verification, coverage checks, SPDX headers, signed tag verification |

## Critical Rules

- **NEVER** interpolate `${{ github.event.* }}` in `run:` (script injection)
- **NEVER** guess action versions -- always fetch from GitHub API
- **ALWAYS** use SHA pins for actions with version comments
- **ALWAYS** verify commit hashes against official tags
- **ALWAYS** include `https://` URLs in badge justifications (platform rejects criteria without URLs)
- **NEVER** URL-decode session cookies for badge submission (breaks auth silently)

## Related Skills

| Skill | Purpose |
|-------|---------|
| `go-development` | Go code patterns, testing |
| `github-project` | Repository setup, branch protection |
| `security-audit` | Deep security audits (OWASP, XXE, SQLi) |
| `git-workflow` | Git branching, commits, PR workflows |
