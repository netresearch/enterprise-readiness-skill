<!-- SPDX-License-Identifier: CC-BY-SA-4.0 -->
<!-- SPDX-FileCopyrightText: Netresearch DTT GmbH -->

# Security Assurance Case

This document states what users of the Enterprise Readiness skill can and cannot expect in terms of security, and argues why the project meets those expectations. Each claim names the file that implements it. Vulnerabilities are reported privately as described in the organisation's [security policy](https://github.com/netresearch/.github/blob/main/SECURITY.md).

## What the project ships

| Component | Path | Runs code? |
|-----------|------|------------|
| Skill definition | `skills/enterprise-readiness/SKILL.md` | No. An AI agent reads it as instructions. |
| References | `skills/enterprise-readiness/references/*.md` | No. Documentation the agent consults. |
| Slash commands and output style | `commands/*.md`, `outputStyles/enterprise-report.md` | No. Prompts for the agent. |
| Templates | `assets/templates/*.md`, `assets/workflows/*.yml` | Not here. Users copy them into their own projects, where the workflows run in that project's CI. |
| Checkpoints | `skills/enterprise-readiness/checkpoints.yaml` | Only when an assessment tool runs them: 8 `command` and 4 `script` checkpoints are shell code executed in the assessed project. |
| Verification scripts | `skills/enterprise-readiness/scripts/*.sh` | Yes, on the user's machine, with the user's privileges, in the project being assessed. |
| Badge submission | `skills/enterprise-readiness/scripts/submit-badges.py` | Yes. It sends form data to bestpractices.dev with the user's session cookie. |
| Development scripts | `Build/`, `scripts/verify-harness.sh`, `tests/` | Yes, for maintainers. The npm package contains `scripts/` but not `Build/` or `tests/` (`files` in `package.json`); Composer and git installs contain the whole repository. |

## Actors and data flow

1. A user installs the skill (marketplace, skills directory, npm, Composer, a release archive or a git clone; see `README.md`).
2. The user's AI agent loads `SKILL.md` when a request matches its description and reads references as needed. `SKILL.md` pre-approves tools in `allowed-tools`: the skill's own scripts, `gh`, `cosign`, `Read`, `Write`, `Glob` and `Grep` run without a permission prompt while the skill is active. It does not remove other tools; the agent runtime's permission settings decide whether the user must approve those.
3. The agent runs verification scripts in the assessed project. They read files and git metadata there and print findings. Three of them run external programs on the project: `verify-reproducible-build.sh` runs the project's build twice, `check-branch-coverage.sh` runs `go test`, and `verify-review-requirements.sh` reads branch protection and rulesets through `gh api`.
4. `add-spdx-headers.sh` writes: it inserts licence headers into Go, Python and JavaScript/TypeScript files below the current directory. `verify-spdx-headers.sh --fix` calls it.
5. `submit-badges.py` reads a session cookie from `BADGE_COOKIE` or `~/.badge-cookie.txt`, fetches the project's edit page on `https://www.bestpractices.dev` and submits the criteria from a JSON file the user names.

## Trust boundaries

- **Skill content to agent.** The project controls the text the agent reads; it does not control what the agent does with it. Everything the agent produces from the skill is untrusted until a human reviews it.
- **Assessed project to scripts.** File contents, file names, tags and commit metadata of the assessed project are input data. The scripts read them with `grep`, `find`, `git` and `awk` and do not evaluate them as shell code. The exception is intended: `verify-reproducible-build.sh` and `check-branch-coverage.sh` execute the project's own build and tests, so they are only as safe as that project.
- **Script to GitHub.** `verify-review-requirements.sh` only reads (`gh api` GET requests) and uses the caller's `gh` login.
- **Script to bestpractices.dev.** `submit-badges.py` holds the user's session cookie, which grants write access to the user's badge entries.
- **Contributions to this repository.** Changes reach `main` through pull requests; the checks listed below run on each of them.

## Security requirements and how they are met

| Requirement | How it is met | Evidence |
|-------------|---------------|----------|
| The build verifier does not run arbitrary commands from its arguments (CWE-78). | The build command is chosen from a fixed list (`go`, `docker`, `make`, `composer`, `npm`); there is no `eval`. The output path is rejected unless it consists of letters, digits, `.`, `_`, `/` and `-`. | `verify-reproducible-build.sh` (`run_build`), `tests/verify-reproducible-build.sh` cases "unknown build type fails" and "output path with shell metacharacters is rejected" |
| The badge session cookie is sent only to bestpractices.dev over HTTPS and is not stored by the script. | The cookie is put into a cookie jar for the domain `www.bestpractices.dev` with `secure=True`; all URLs are built from `BASE_URL = "https://www.bestpractices.dev"`. The script prefers the environment variable and warns when `~/.badge-cookie.txt` is not mode 0600. It never writes the cookie. | `submit-badges.py` (`make_opener`, `main`), `tests/test_submit_badges.py` (`OpenerTests`, `MainTests`) |
| Fields the badge site detects itself are never overwritten. | `submit_data` skips the keys in `AUTO_DETECTED_FIELDS`. | `submit-badges.py`, `tests/test_submit_badges.py::test_auto_detected_fields_are_not_sent` |
| A failed check is visible to the caller. | Each `check` case in `tests/*.sh` asserts a script's exit code, so a change that turns a failure into exit 0 fails CI. `verify-badge-criteria.sh` is the exception to failing with an exit code: it prints a score and exits 0 for every valid level, so its output, not its exit code, carries the result. `verify-review-requirements.sh` exits 2 when it cannot read the classic branch protection or the branch rules, instead of reporting them as absent; bypass actors of a ruleset it cannot read are reported with a warning line, not a failure. | the `check` cases in `tests/*.sh` (the `absent`/`empty` cases inspect output only) |
| The scripts do not print the contents of scanned files. | Content tests use `grep -q`; only file names and counts are printed. | `check-tls-minimum.sh`, `tests/check-tls-minimum.sh` case "scanned source lines are not echoed" |
| Deprecated TLS versions are reported, not passed (CWE-326). | Deprecated protocol constants are tested before the modern ones, so `PROTOCOL_TLSv1` is not mistaken for `PROTOCOL_TLS`. | `check-tls-minimum.sh`, `tests/check-tls-minimum.sh` |
| The repository holds no secrets (CWE-798). | Betterleaks scans every push to `main` or `master` and every pull request against those branches. `.gitleaksignore` suppresses four findings, all `curl -u "$SONAR_TOKEN:"` example commands in `references/sonarcloud.md` that reference a variable, not a token. | `.github/workflows/security.yml`, `.gitleaksignore` |
| CI cannot be steered by pull request content (CWE-94). | Every workflow starts with `permissions: {}` and grants each job only the scopes its reusable workflow needs. No workflow in this repository has a `run:` step. The `pull_request_target` workflows (`auto-merge-deps.yml`, `labeler.yml`, `pr-quality.yml`) only call reusables and do not check out pull request code. zizmor analyses the workflows. | `.github/workflows/*.yml`, `security.yml` (zizmor job) |
| Dependencies and code are scanned (OWASP A06:2021). | Composer Audit, dependency review and Opengrep run on pull requests; Renovate proposes updates, including for pre-commit hooks. Besides the installers (`netresearch/composer-agent-skill-plugin` in `composer.json`, `@netresearch/agent-skill-coordinator` as an npm peer dependency) the project declares no dependencies. | `security.yml`, `renovate.json`, `composer.json` |
| Releases can be verified. | Releases run only from tags. The release reusable checks that the tag is annotated and signed, publishes `SHA256SUMS.txt` signed with Cosign (keyless) and attests build provenance for the archives. | `.github/workflows/release.yml`, [skill-repo-skill `release.yml`](https://github.com/netresearch/skill-repo-skill/blob/main/.github/workflows/release.yml) |

## Secure design principles applied

- **Least privilege.** Workflow tokens are scoped per job. `verify-review-requirements.sh` only reads. `SKILL.md` pre-approves only the skill's scripts, `gh`, `cosign` and the file tools; it is not a sandbox, and other tools stay subject to the runtime's permission prompts.
- **Fail safe.** Every shell script under `skills/enterprise-readiness/scripts/` runs with `set -euo pipefail`, and `submit-badges.py` exits non-zero on a missing cookie or wrong usage; an unreadable classic-protection or branch-rules response ends the review check with exit 2 rather than a pass (an unreadable ruleset only adds a warning line).
- **Economy of mechanism.** Each script is a single file using standard tools (`bash`, `git`, `grep`, `awk`, `jq`, Python's standard library). There are no third-party runtime packages.
- **Complete mediation in CI.** Every pull request to `main` runs the same checks; none can be skipped by a path filter.

## Checks on pull requests

On every pull request: `lint.yml` (skill validation including ShellCheck, ruff, markdownlint, yamllint, actionlint, JSON syntax and checkpoint schema), `tests.yml` (behaviour tests), `eval-validate.yml` and `pr-quality.yml`. On pull requests to `main` also: `security.yml` (Betterleaks, zizmor, dependency review, Composer Audit, Opengrep), `harness-verify.yml`, `check-template-drift.yml`, and CodeQL for Actions and Python through the repository's default setup.

## What users cannot expect

- The skill does not make an agent's output safe. Review generated workflows, policies and badge answers before committing or submitting them.
- The verification scripts are heuristics, not security scanners. `check-tls-minimum.sh` matches text patterns and inspects at most 50 configuration files; `check-branch-coverage.sh` estimates branch coverage as 80 % of statement coverage; `verify-badge-criteria.sh` looks for file names and keywords.
- `verify-reproducible-build.sh` and `check-branch-coverage.sh` run the assessed project's build and tests. Run them only in projects you trust.
- `add-spdx-headers.sh` rewrites files in place and defaults to the MIT licence and the git user name as copyright holder; `verify-spdx-headers.sh --fix` uses those defaults. Check the licence before running it, and review the diff.
- The checkpoints in `checkpoints.yaml` run shell commands in the assessed project when an assessment tool executes them; run them only in projects you trust.
- `submit-badges.py` needs a live browser session cookie. Anyone who reads the cookie can change your badge entries until the session ends.
- Security fixes follow the supported-versions rules of the organisation's security policy; older releases may not receive them.
