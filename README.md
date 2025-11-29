# Enterprise Readiness Skill

A [Claude Code](https://claude.ai/claude-code) skill for assessing and enhancing software projects to meet enterprise-grade standards for security, quality, and automation.

## Overview

This skill provides a comprehensive framework with:
- **Dynamic Scoring System** - Fair assessment across different tech stacks
- **40+ Security & Quality Checks** - Covering supply chain, testing, and automation
- **Implementation Patterns** - Ready-to-use code for SLSA, Cosign, GitHub hardening
- **Extensible Architecture** - General → Platform → Language modular design

## Installation

### Option 1: Direct Installation

```bash
# Clone to your Claude skills directory
git clone https://github.com/netresearch/enterprise-readiness-skill.git ~/.claude/skills/enterprise-readiness
```

### Option 2: Download ZIP

Download the [latest release](https://github.com/netresearch/enterprise-readiness-skill/releases) and extract to `~/.claude/skills/enterprise-readiness/`.

## Usage

The skill triggers automatically on keywords like:
- "enterprise ready"
- "production ready"
- "security hardening"
- "supply chain security"
- "SLSA"
- "OpenSSF Scorecard"

### Example Prompts

```
"Assess this project for enterprise readiness"
"How can I make this repository production ready?"
"Implement SLSA Level 3 provenance for this project"
"Harden the GitHub Actions workflows"
```

## Assessment Categories

| Category | Points | Description |
|----------|--------|-------------|
| Supply Chain Security | 20 | Provenance, signing, SBOMs, checksums, secret scanning |
| Quality Gates | 15 | Coverage thresholds, static analysis, security scanning |
| Testing Layers | 15 | Unit, integration, fuzz, E2E tests |
| **Total General** | **50** | Universal checks for any platform/language |
| GitHub Hardening | 30 | Harden runner, pinned actions, permissions, Dependabot |
| Go Best Practices | 20 | Static builds, golangci-lint, govulncheck, race detection |

## Scoring

Uses **Dynamic Denominator** scoring for fairness:

```
Score = (Points_Earned / Max_Points_Applicable) × 100
```

| Score | Grade | Status |
|-------|-------|--------|
| 90-100 | A | Enterprise Ready |
| 80-89 | B | Production Ready (minor gaps) |
| 70-79 | C | Development Ready (needs hardening) |
| 60-69 | D | Basic (significant gaps) |
| Below 60 | F | Not Ready (major improvements needed) |

## Structure

```
enterprise-readiness/
├── SKILL.md              # Main skill with workflow and patterns
└── references/
    ├── general.md        # Universal checks (50 points)
    ├── github.md         # GitHub-specific checks (30 points)
    └── go.md             # Go-specific checks (20 points)
```

## Extensibility

The skill is designed for extension. Additional modules can be added:

**Platform Modules (planned):**
- `references/gitlab.md`
- `references/bitbucket.md`
- `references/azure-devops.md`

**Language Modules (planned):**
- `references/python.md`
- `references/typescript.md`
- `references/rust.md`
- `references/java.md`

## Key Implementation Patterns

### SLSA Level 3 Provenance

```yaml
uses: slsa-framework/slsa-github-generator/.github/workflows/builder_go_slsa3.yml@v2.1.0
with:
  go-version-file: go.mod
  config-file: .slsa-goreleaser/${{ matrix.target }}.yml
  evaluated-envs: "VERSION:${{ github.ref_name }}, COMMIT:${{ github.sha }}"
```

### Keyless Signing with Cosign

```yaml
- uses: sigstore/cosign-installer@v3.8.2
- run: cosign sign-blob --yes --output-certificate file.pem --output-signature file.sig file.txt
```

### Workflow Hardening

```yaml
permissions: read-all

jobs:
  build:
    steps:
      - uses: step-security/harden-runner@SHA
        with:
          egress-policy: audit
      - uses: actions/checkout@SHA  # Pin to SHA, not tag
```

## Sources

This skill was developed based on:
- [SLSA Framework](https://slsa.dev/) - Supply chain security levels
- [OpenSSF Scorecard](https://securityscorecards.dev/) - Security health metrics
- [Sigstore/Cosign](https://docs.sigstore.dev/) - Keyless signing
- [step-security/harden-runner](https://github.com/step-security/harden-runner) - Workflow hardening
- Real-world implementation experience from the [ofelia](https://github.com/netresearch/ofelia) project

## Contributing

Contributions are welcome! Please feel free to submit PRs for:
- Additional platform modules (GitLab, Bitbucket, Azure DevOps)
- Additional language modules (Python, TypeScript, Rust, Java)
- New security checks and patterns
- Documentation improvements

## License

MIT License - See [LICENSE](LICENSE) for details.
