# `.bestpractices.json`: proposing badge answers from the repository

A file the OpenSSF BadgeApp reads to pre-fill the Best Practices questionnaire. It is the only way to feed answers in without a logged-in session; [`badge-submission-api.md`](badge-submission-api.md) covers writing them directly, which needs a browser session cookie.

## What the BadgeApp does with it

Read from `.bestpractices.json` at the repository root, or from `.project.d/bestpractices.json`. The format is the project JSON itself: `<criterion>_status` and `<criterion>_justification` keys, flat in one object. Source: [`docs/bestpractices-json.md`](https://github.com/ossf/best-practices-badge/blob/main/docs/bestpractices-json.md) and the reader [`app/lib/repo_json_detective.rb`](https://github.com/ossf/best-practices-badge/blob/main/app/lib/repo_json_detective.rb).

- Status values are `Met`, `Unmet`, `N/A`, case-insensitive. `?`, an empty string and any other value are ignored, so a leftover placeholder is harmless.
- Field names are checked against the list of real criteria; an unknown key such as `_comment` is dropped silently, which makes it a safe place for a note to the reader.
- A justification is capped at 8192 characters (`Project::MAX_TEXT_LENGTH`).
- Values are *proposals* at confidence 3.5. They appear in the form when a section is first edited, and again when a maintainer clicks **Save (and continue) 🤖** — the robot button is what re-runs the automation after the file has changed. Nothing is saved without a logged-in maintainer.

**Unverified:** which branch the BadgeApp reads. The reader calls `repo_files.get_content(path)` without naming one; the working assumption is the default branch, so merge the file before asking anyone to save.

## Write only what the repository shows

The file asserts things in the project's name. A template copied across repositories is false in most of them, so derive each file from the repository it lands in:

- Emit only `Met`, and only where a file or setting shows it. Never write `Unmet`: an absent key already means "unknown", and an `Unmet` proposal adds nothing the maintainer did not know.
- Put the evidence URL in every justification (`https://github.com/<org>/<repo>/blob/<default-branch>/<path>`). Many criteria count only with a URL; see `badge-submission-api.md` § *URL-Required Justifications*.
- Check the text of the criterion, not its name. `test` requires a suite *and* a documented way to run it; `vulnerability_report_process` requires a published *reporting* process. The wording is in [`config/locales/en.yml`](https://github.com/ossf/best-practices-badge/blob/main/config/locales/en.yml) under `criteria`.

Criteria that can be derived mechanically, with the rule that proved reliable:

| Criterion | Evidence |
|---|---|
| `repo_public`, `repo_track`, `repo_distributed` | Public repository on GitHub |
| `sites_https` | Public repository, and the homepage field empty or `https://` |
| `license_location` | Licence file in the root |
| `floss_license` | GitHub's detected SPDX id is OSI-approved, a licence file exists, and `composer.json` and `CONTRIBUTING.md` name no other licence. Cite the most precise id: GitHub detects the GPL text as `GPL-2.0`, while `composer.json` states the grant as `GPL-2.0-or-later` |
| `discussion`, `report_process`, `report_archive` | Issues enabled on a public repository. Word the archive as *public bug reports*: vulnerabilities go through a private channel |
| `contribution` | `CONTRIBUTING.md` that mentions pull requests |
| `vulnerability_report_process` | A file named exactly `SECURITY.md` (root, `.github/`, `docs/`) that names a concrete channel: a `security/advisories` link or an e-mail address |
| `vulnerability_report_private` | Private vulnerability reporting enabled (`GET /repos/{r}/private-vulnerability-reporting`) *and* `SECURITY.md` links `security/advisories` (with or without `/new`); or `SECURITY.md` names a private e-mail address |
| `test` | Test files in the tree, and a pull-request workflow that invokes them (`go test`, `bin/phpunit`, `composer test:php:unit`, or a shared CI reusable with tests on by default) — the criterion accepts a CI script as the documented way to run the suite, and the licence makes the suite FLOSS. Cite the test directory for the count |
| `test_continuous_integration` | A workflow that runs the tests on every pull request |
| `static_analysis` | An invocation in a pull-request workflow of a tool for the project's own language: PHPStan or Psalm for PHP; golangci-lint, staticcheck or CodeQL for Go. CodeQL has no PHP support. Cite the shared workflow and the analyser's configuration |
| `dependency_monitoring` | A CI audit that fails on a known vulnerability (Composer Audit, govulncheck). The criterion also asks for fixing, which a failing audit enforces. Renovate's `vulnerabilityAlerts` shows detection only: it opens a labelled fix pull request, and nothing enforces that it is merged (the shared config sets no automerge). A Dependabot file that only schedules updates shows neither. Describe what the CI enforces, including its exceptions: the shared Composer Audit passes with a warning when the advisory source stays unreachable, and govulncheck fails only on reachable vulnerabilities, in strict mode (the default) |
| `version_unique`, `version_tags`, `version_semver` | SemVer tags |
| `release_notes` | A changelog file (including `Documentation/Changelog/Index.rst` for TYPO3 extensions) that names the latest SemVer release |

## Traps measured on the Netresearch rollout

The generator analysed 42 repositories — every Go module and TYPO3 extension in the organisation — and 33 of them received the file; the other nine are mirror or patch forks (see *Forks are two different things* below). Most produced a wrong or overbroad file before hand sampling or a CodeRabbit review caught it; two misled a review or the rollout itself instead of a file; the last three were checked before the first file was written.

- **A case-insensitive file match invents a security policy.** `docs/security.md` in an application repository usually documents the application's security *model*. Matching `SECURITY.md` without regard to case credited one repository with a reporting process it does not have; the fix was an exact file name plus a check that the file actually describes reporting.
- **A security guide is not a reporting policy.** A 700-line `SECURITY.md` can mention "report" and "vulnerability" many times and end on "contact the maintainers through the project's security channels" without naming one. Require a concrete channel — an advisories link or an e-mail address — before claiming the process is published.
- **Match the channel, not one spelling of its URL.** Requiring the literal `security/advisories/new` missed a policy that links `security/advisories` and says "Click 'Report a vulnerability'", and one that offers `security@…` instead. Both are private channels in the criterion's sense.
- **The first matching workflow is not the right one.** Taking the first workflow file that mentions any analysis tool credited a PHP extension with CodeQL, because `checks.yml` sorts before `ci.yml` — and CodeQL does not analyse PHP. Rank the tools, and accept only those for the project's language.
- **A changelog file is not release notes for every release.** Two extensions keep a `CHANGELOG.md` that starts at an untagged 2.0.0 and never names the latest tag. Require the latest SemVer release to appear in the file.
- **A tool's name is not its invocation.** A workflow that says `run-phpstan: false`, or carries the comment *no PHPStan setup*, contains the word `phpstan` — a fallback that searched for the name credited two extensions with static analysis they switch off. Drop comment lines and require an invocation (`bin/phpstan`, `phpstan analyse`, `golangci-lint run`). The same holds for script names: `composer ci:test:php:lint` starts with `test` and runs no tests.
- **An update bot is not vulnerability monitoring.** A `dependabot.yml` that schedules only `github-actions` updates says nothing about the project's own dependencies, and none says anything about fixing. Renovate's `vulnerabilityAlerts` detects and opens a fix pull request, but without automerge or a blocking check nothing ensures the fix lands. A CI audit that fails the build on a finding covers detection and remediation in one.
- **Licence statements can disagree inside one repository.** Two repositories carry one licence in `LICENSE` and another in `composer.json` and `CONTRIBUTING.md` (MIT against GPL-2.0-or-later; GPL-3.0 against GPL-2.0-or-later). Leave `floss_license` out and name the conflict in the pull request: which licence applies is the maintainers' decision.
- **Private reporting narrows the archive.** Where vulnerabilities go to a private channel, "all reports stay public" is false; claim the archive for public bug reports.
- **A sentence on GitHub's page is not a repository setting.** "Issue creation is restricted in this repository" appears in the HTML of every issues page, including `cli/cli` and `microsoft/vscode`, which accept issues from anyone. A review took it for a restriction and a scan found it in all 33 repositories; the control against repositories known to be open showed it is page furniture. The API (`/interaction-limits`, issue templates) is the evidence.
- **Right after a push, the check rollup can still show the previous head.** A watcher started at once reported a stale failed check three times; on the new head the same check was only queued. Wait a couple of minutes, or read the check run for the new SHA before acting on a failure.
- **Describe the CI, not the criterion.** The criterion lets a vulnerability be verified as unexploitable instead of fixed; a CI that fails on every reachable finding does not. One review asked for "fixed or assessed", the next rightly pointed out that `govulncheck-strict` defaults to `true` and nothing overrides it. The justification states what the pipeline enforces, which satisfies the criterion either way.
- **CI reusables hide the commands.** A repository that calls `typo3-ci-workflows`'s `ci.yml` or `.github`'s `go-check.yml` contains no `phpunit` or `go test` string. Open the reusable and read its defaults — `run-unit-tests`, `run-phpstan`, `enable-golangci-lint` are on by default there — and treat a caller that sets one to `false` as having no evidence.
- **Forks are two different things.** Compare each fork with its parent (`GET /repos/{parent}/compare/{base}...{org}:{branch}`). A fork far ahead of upstream is your project and gets a file; a fork 0 commits ahead is a mirror, and a commit there breaks the clean sync with upstream for no reader.
- **The registry's own auto-detection misses TYPO3 changelogs.** It recorded "No release notes file found" for an extension whose release notes live in `Documentation/Changelog/Index.rst`. A disagreement between your file and the registry is therefore not automatically your error; read the cited file before deciding.

## Check the generated files against the registry

For every repository that already has a badge project, compare each proposed `Met` with the registry's stored value (`/projects/{ID}.json`, no locale prefix, with a cache buster — see `badge-submission-api.md` § *API Response Caching*). This is an independent count: the registry was filled by people, the file by rules. On the Netresearch rollout 204 claims agreed, 11 met blank fields in an unfinished project, and the one disagreement was the changelog case above.

A registry check cannot see a repository without a badge project, which is where both false positives — `docs/security.md` and the security guide without a channel — sat. Sample those by hand: pick a few claims per criterion and open the cited file.

## Watching a fleet of pull requests

A `pr-status.sh --watch` per pull request polls GraphQL every 20 seconds by default. Twenty-five of them, beside other sessions on the same account, ran into the API limit twice in one evening: calls were refused with *API rate limit exceeded for user ID …* while `gh api rate_limit` for the same token reported 5000 remaining. Why the two disagree was not established, so do not read the counter as permission while refusals continue. Pass `--interval 300` for a fleet, and generate files in one batch rather than per review round.

## Finding the projects

`GET https://www.bestpractices.dev/projects.json?url=<repo-url>` returns the badge projects registered for a repository. Search the registry rather than the README: two of eleven Netresearch projects existed without a README badge.
