# Enterprise Readiness Skill

<!-- Index file -- detail in docs/ and skills/. Keep under 100 lines. -->

## Repo Structure

```
enterprise-readiness-skill/
├── AGENTS.md                          # This file
├── README.md                          # User-facing overview, installation, usage
├── composer.json                      # PHP distribution (ai-agent-skill type)
├── renovate.json                      # Dependency update config
├── commands/                          # Slash-command definitions
│   ├── audit.md                       # /audit command
│   └── slsa.md                        # /slsa command
├── outputStyles/
│   └── enterprise-report.md           # Report output format
├── skills/enterprise-readiness/
│   ├── SKILL.md                       # AI instructions and metadata (v4.6.0)
│   ├── checkpoints.yaml              # Assessment checkpoints
│   ├── evals/evals.json              # Evaluation test cases
│   ├── references/                    # OpenSSF criteria, guides, playbooks
│   └── scripts/                       # Automation (badge checks, SPDX, signing)
├── assets/
│   ├── workflows/                     # GitHub Actions templates (CodeQL, Scorecard, SLSA)
│   └── templates/                     # Project templates (CoC, Security Audit, Governance)
├── Build/
│   ├── Scripts/check-plugin-version.sh
│   └── hooks/pre-push
├── docs/                              # Architecture and planning docs
│   ├── ARCHITECTURE.md
│   └── exec-plans/                    # Execution plans
└── .github/workflows/                 # CI: lint, release, auto-merge-deps
```

## Commands

Build/test/lint:
- **Lint**: CI runs `netresearch/skill-repo-skill/.github/workflows/validate.yml`
- **Version check**: `bash Build/Scripts/check-plugin-version.sh`
- **Badge verification**: `bash skills/enterprise-readiness/scripts/verify-badge-criteria.sh`
- **SPDX headers**: `bash skills/enterprise-readiness/scripts/verify-spdx-headers.sh`
- **Signed tags**: `bash skills/enterprise-readiness/scripts/verify-signed-tags.sh`
- **Badge submission**: `python3 skills/enterprise-readiness/scripts/submit-badges.py`

No Makefile or package.json; no local test runner.

## Rules

1. **NEVER** interpolate `${{ github.event.* }}` in `run:` blocks (script injection)
2. **NEVER** guess action versions -- always fetch from GitHub API
3. **ALWAYS** use SHA pins for actions with version comments
4. **ALWAYS** verify commit hashes against official tags
5. **ALWAYS** include `https://` URLs in badge justification text
6. **NEVER** URL-decode session cookies when submitting badge data
7. Dual license: code = MIT, content = CC-BY-SA-4.0
8. Entity name: "Netresearch DTT GmbH" (not old company name)

## References

- `skills/enterprise-readiness/SKILL.md` -- primary AI instructions
- `skills/enterprise-readiness/references/` -- OpenSSF criteria docs
- `skills/enterprise-readiness/references/general.md` -- universal checks (always load)
- `skills/enterprise-readiness/references/scorecard-playbook.md` -- raise Scorecard to ~9.0
- `skills/enterprise-readiness/references/mandatory-requirements.md` -- badge/workflow checklist
- `docs/ARCHITECTURE.md` -- architecture overview
