<!-- SPDX-License-Identifier: CC-BY-SA-4.0 -->
<!-- SPDX-FileCopyrightText: Netresearch DTT GmbH -->

# Enterprise Readiness Skill

Netresearch AI skill for assessing and enhancing software projects to meet enterprise-grade standards for security, quality, and automation.

## 🔌 Compatibility

This is an **Agent Skill** following the [open standard](https://agentskills.io) originally developed by Anthropic and released for cross-platform use.

**Supported Platforms:**
- ✅ Claude Code (Anthropic)
- ✅ Cursor
- ✅ GitHub Copilot
- ✅ Other skills-compatible AI agents

> Skills are portable packages of procedural knowledge that work across any AI agent supporting the Agent Skills specification.


## Features

- **OpenSSF Framework Alignment** - Complete coverage across Scorecard, Best Practices Badge (Passing/Silver/Gold), SLSA, and S2C2F
- **Dynamic Scoring** - Fair cross-stack assessment with platform/language-specific criteria
- **Supply Chain Security** - SLSA provenance, artifact signing, SBOM generation, dependency scanning
- **Quality Gates** - Testing layers, coverage thresholds, static analysis, secret scanning
- **Automation Scripts** - Ready-to-use scripts for security hardening and compliance checks
- **Badge Progression** - Guided path from Passing → Silver → Gold certification

## Installation

### Marketplace (Recommended)

Add the [Netresearch marketplace](https://github.com/netresearch/claude-code-marketplace) once, then browse and install skills:

```bash
# Claude Code
/plugin marketplace add netresearch/claude-code-marketplace
/plugin install enterprise-readiness@netresearch-claude-code-marketplace
```

### Without a marketplace

Since Claude Code 2.1.157 a plugin directory under your personal skills directory loads on its own, including the commands this repo ships:

```bash
mkdir -p ~/.claude/skills
git clone https://github.com/netresearch/enterprise-readiness-skill.git \
  ~/.claude/skills/enterprise-readiness
```

It loads as `enterprise-readiness@skills-dir` on the next session. Update with `git -C ~/.claude/skills/enterprise-readiness pull` and start a new session; remove it by deleting the directory. This route has no `claude plugin update`.

### npx ([skills.sh](https://skills.sh))

Install with any [Agent Skills](https://agentskills.io)-compatible agent:

```bash
npx skills add https://github.com/netresearch/enterprise-readiness-skill --skill enterprise-readiness
```

> **Limitation:** `npx skills` installs `SKILL.md`-based skills only. This repo also ships `commands`, which it does not install — use the marketplace or the skills directory for those.

### Download Release

Download the [latest release](https://github.com/netresearch/enterprise-readiness-skill/releases/latest) and extract to your agent's skills directory.

### Git Clone

```bash
git clone https://github.com/netresearch/enterprise-readiness-skill.git
```

### Composer (PHP Projects)

```bash
composer require netresearch/enterprise-readiness-skill
```

Requires [netresearch/composer-agent-skill-plugin](https://github.com/netresearch/composer-agent-skill-plugin).
### npm (Node Projects)

```bash
npm install --save-dev \
  @netresearch/agent-skill-coordinator \
  github:netresearch/enterprise-readiness-skill
```

Requires [@netresearch/agent-skill-coordinator](https://github.com/netresearch/node-agent-skill-coordinator), which discovers the skill in `node_modules` and registers it in `AGENTS.md` via a `postinstall` hook. For pnpm, also allowlist the coordinator's postinstall:

```json
{
  "pnpm": {
    "onlyBuiltDependencies": ["@netresearch/agent-skill-coordinator"]
  }
}
```

## Usage

The skill triggers on keywords like:
- "enterprise readiness", "production ready"
- "OpenSSF", "security scorecard", "best practices badge"
- "SLSA", "supply chain security", "SBOM"
- "quality gates", "CI/CD hardening"

### Example Prompts

```
"Assess this project for enterprise readiness"
"What's needed for OpenSSF Best Practices Silver badge?"
"Help me reach SLSA Level 2"
"Set up supply chain security for this Go project"
```

## Structure

```
enterprise-readiness/
├── SKILL.md              # AI instructions
├── README.md             # This file
├── LICENSE-MIT           # Code license (MIT)
├── LICENSE-CC-BY-SA-4.0  # Content license (CC-BY-SA-4.0)
├── composer.json         # PHP distribution
├── references/           # OpenSSF criteria documentation
│   ├── general.md        # Universal checks (60 points)
│   ├── github.md         # GitHub-specific (40 points)
│   ├── go.md             # Go-specific (20 points)
│   ├── openssf-badge-silver.md
│   └── openssf-badge-gold.md
├── scripts/              # Automation scripts
│   ├── check-*.sh        # Validation scripts
│   └── setup-*.sh        # Configuration scripts
└── assets/               # Templates and configs
    └── templates/        # CI/CD, SBOM, policy templates
```

## Contributing

Contributions welcome! Please submit PRs for:
- Additional platform support (GitLab, Bitbucket)
- New language-specific checks
- Script improvements
- Documentation updates

## Development and tests

Every script under `skills/enterprise-readiness/scripts/` and the version check the pre-push hook runs (`Build/Scripts/check-plugin-version.sh`) has a behaviour test in `tests/`, named after the script (`tests/<script>.sh`, and `tests/test_submit_badges.py` for `submit-badges.py`). The tests build fixture directories and throw-away git repositories in a temporary directory and run the real script against them, checking exit codes and output: pass and fail verdicts, thresholds, excluded directories, signed and unsigned tags, and error paths. `go` and `gh` are replaced by stubs, and `submit-badges.py` talks to a fake HTTP opener, so no test calls a Go toolchain, GitHub or bestpractices.dev. Shared helpers are in `tests/helpers.bash`.

The tests need bash, git, jq, make, ssh-keygen and python3. Run them from the repository root:

```bash
for t in tests/*.sh; do bash "$t" || exit 1; done
python3 tests/test_submit_badges.py
```

Each shell test prints `ok` or `FAIL` per case, with the captured output of a failing case indented below it, and ends with a `passed, failed` tally; it exits non-zero if any case failed. The Python test uses `unittest` and reports failures the same way. CI runs the same files on every pull request and on pushes to `main` (`.github/workflows/tests.yml`), and fails if no test file is found. The pre-commit hooks in `.pre-commit-config.yaml` run the linters that `lint.yml` runs in CI.

New or changed behaviour in a script needs a test case in `tests/` in the same pull request.

## Governance and policies

This repository follows the Netresearch organisation policies:

- [Governance](https://github.com/netresearch/.github/blob/main/GOVERNANCE.md): who decides, how changes are accepted, and how disputes are resolved.
- [Roadmap](https://github.com/netresearch/.github/blob/main/ROADMAP.md): planned and excluded work for the coming year.
- [Handling of dependency and code analysis findings](https://github.com/netresearch/.github/blob/main/SECURITY.md#handling-of-dependency-and-code-analysis-findings): thresholds, deadlines and exceptions for dependency and static-analysis findings.
- [Secret management](https://github.com/netresearch/.github/blob/main/SECURITY.md#secret-management): how CI and release credentials are stored, accessed and rotated.
- [Access roster](https://github.com/netresearch/.github/blob/main/docs/access-roster.md): the accounts that can change code, settings or releases of this repository, with their access level.
- [Security assurance case](docs/SECURITY-ASSURANCE.md): threat model, trust boundaries and countermeasures for this skill.

Every pull request to `main` runs these security checks (`.github/workflows/security.yml`): dependency review, Composer Audit, Opengrep (static analysis), Betterleaks (secret scanning) and zizmor (workflow analysis). CodeQL analyses the GitHub Actions workflows and the Python code through the repository's default setup. The only secrets this repository's workflows use are the organisation GitHub App credentials passed to the dependency auto-merge job (`auto-merge-deps.yml`); releases are signed with short-lived OIDC credentials (`release.yml`).

## License

This project uses split licensing:

- **Code** (scripts, workflows, configs): [MIT](LICENSE-MIT)
- **Content** (skill definitions, documentation, references): [CC-BY-SA-4.0](LICENSE-CC-BY-SA-4.0)

See the individual license files for full terms.
## Credits

Developed and maintained by [Netresearch DTT GmbH](https://www.netresearch.de/).

---

**Made with ❤️ for Open Source by [Netresearch](https://www.netresearch.de/)**
