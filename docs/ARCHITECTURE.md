# Architecture Overview

## Purpose

The Enterprise Readiness Skill is an AI agent skill that assesses and hardens software projects against enterprise-grade standards. It aligns with OpenSSF frameworks (Scorecard, Best Practices Badge, SLSA, S2C2F, OSPS Baseline).

## Design

The skill follows the Agent Skills open standard. It is a knowledge-and-tooling package, not a runtime service. There is no build step, no server, and no database.

### Core Components

```
SKILL.md (entry point)
    |
    +-- references/       Knowledge base: criteria checklists, playbooks, guides
    |                     Loaded on demand based on project stack and task
    |
    +-- scripts/          Automation: shell and Python scripts for verification
    |                     Invoked by the AI agent during assessment
    |
    +-- assets/           Templates: GitHub Actions workflows, project templates
    |                     Copied into target projects as needed
    |
    +-- commands/         Slash commands: /audit, /slsa
    |
    +-- checkpoints.yaml  Structured assessment checkpoints
    +-- evals/            Evaluation test cases for skill quality
```

### Assessment Flow

1. **Trigger**: User asks about enterprise readiness, OpenSSF, SLSA, etc.
2. **Discovery**: Agent identifies platform, languages, existing CI/CD in the target project
3. **Reference loading**: Agent loads relevant reference docs (general.md always, plus stack-specific)
4. **Scoring**: Dynamic scoring using checklists (general: 60pts, GitHub: 40pts, Go: 20pts)
5. **Gap analysis**: Missing controls listed by severity
6. **Implementation**: Scripts and templates applied to close gaps
7. **Verification**: Re-score and compare before/after

### Distribution Channels

- **npm/skills.sh**: `npx skills add` (Agent Skills standard)
- **Composer**: `composer require netresearch/enterprise-readiness-skill` (PHP projects)
- **GitHub Releases**: Direct download
- **Git clone**: Manual installation

### Licensing

Split license model:
- Code (scripts, workflows, configs): MIT
- Content (skill definitions, documentation, references): CC-BY-SA-4.0
