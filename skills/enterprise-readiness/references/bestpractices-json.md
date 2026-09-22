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
| `floss_license` | GitHub's detected SPDX id is OSI-approved, and a licence file exists |
| `discussion`, `report_process`, `report_archive` | Issues enabled on a public repository |
| `contribution` | `CONTRIBUTING.md` that mentions pull requests |
| `vulnerability_report_process` | A file named exactly `SECURITY.md` (root, `.github/`, `docs/`) that talks about reporting a vulnerability |
| `vulnerability_report_private` | Private vulnerability reporting enabled (`GET /repos/{r}/private-vulnerability-reporting`) *and* `SECURITY.md` links `security/advisories/new` |
| `test`, `test_continuous_integration` | Test files in the tree, and a `pull_request`-triggered workflow that runs them |
| `static_analysis` | PHPStan, golangci-lint, CodeQL or similar in a workflow |
| `dependency_monitoring` | `dependabot.yml` or a Renovate config |
| `version_unique`, `version_tags`, `version_semver` | SemVer tags |
| `release_notes` | A changelog file, including `Documentation/Changelog/Index.rst` for TYPO3 extensions, alongside SemVer tags |

## Traps measured on a 42-repository rollout

- **A case-insensitive file match invents a security policy.** `docs/security.md` in an application repository usually documents the application's security *model*. Matching `SECURITY.md` without regard to case credited one repository with a reporting process it does not have; the fix was an exact file name plus a check that the file actually describes reporting.
- **CI reusables hide the commands.** A repository that calls `typo3-ci-workflows`'s `ci.yml` or `.github`'s `go-check.yml` contains no `phpunit` or `go test` string. Open the reusable and read its defaults — `run-unit-tests`, `run-phpstan`, `enable-golangci-lint` are on by default there — and treat a caller that sets one to `false` as having no evidence.
- **Forks are two different things.** Compare each fork with its parent (`GET /repos/{parent}/compare/{base}...{org}:{branch}`). A fork far ahead of upstream is your project and gets a file; a fork 0 commits ahead is a mirror, and a commit there breaks the clean sync with upstream for no reader.
- **The registry's own auto-detection misses TYPO3 changelogs.** It recorded "No release notes file found" for an extension whose release notes live in `Documentation/Changelog/Index.rst`. A disagreement between your file and the registry is therefore not automatically your error; read the cited file before deciding.

## Check the generated files against the registry

For every repository that already has a badge project, compare each proposed `Met` with the registry's stored value (`/projects/{ID}.json`, no locale prefix, with a cache buster — see `badge-submission-api.md` § *API Response Caching*). This is an independent count: the registry was filled by people, the file by rules. On the Netresearch rollout 206 claims agreed, 11 met blank fields in an unfinished project, and the one disagreement was the changelog case above.

A registry check cannot see a repository without a badge project, which is where the `docs/security.md` false positive sat. Sample those by hand: pick a few claims per criterion and open the cited file.

## Finding the projects

`GET https://www.bestpractices.dev/projects.json?url=<repo-url>` returns the badge projects registered for a repository. Search the registry rather than the README: two of eleven Netresearch projects existed without a README badge.
