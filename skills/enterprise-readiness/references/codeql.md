# CodeQL Security Analysis

## MANDATORY: Custom Workflow over Default Setup

**CRITICAL: Always use a custom `codeql.yml` workflow. NEVER rely on GitHub's Default Setup.**

### Why Custom Workflow is Required

| Aspect | Default Setup (ClickOps) | Custom codeql.yml (IaC) |
|--------|--------------------------|-------------------------|
| **Auditability** | Hidden in Settings, no git history | Code in repo, PR reviewable |
| **Consistency** | Varies per repo based on who clicked | Same template across all repos |
| **Templatable** | Cannot template UI clicks | Skill can provide standard file |
| **Configuration** | Limited options | Full control over queries, schedules |
| **Drift detection** | Impossible | Git diff shows changes |

### Migration from Default Setup

If a repository has Default Setup enabled, **disable it before adding codeql.yml**:

```bash
# Check current status
gh api repos/OWNER/REPO/code-scanning/default-setup

# Disable Default Setup
gh api -X PATCH repos/OWNER/REPO/code-scanning/default-setup \
  -f state="not-configured"

# Then add custom codeql.yml
```

---

## Supported Languages

CodeQL supports these languages:

| Language | CodeQL Support | Notes |
|----------|----------------|-------|
| `actions` | **YES** | GitHub Actions workflows - **ALWAYS INCLUDE** |
| `javascript` | YES | Also covers TypeScript |
| `typescript` | YES | Alias for javascript |
| `python` | YES | |
| `java` | YES | Also covers Kotlin |
| `csharp` | YES | |
| `cpp` | YES | C and C++ |
| `go` | YES | |
| `ruby` | YES | |
| `swift` | YES | |
| **`php`** | **NO** | Not supported by CodeQL |

### Language Detection

For repositories, detect languages and configure accordingly:

```bash
# Check for JavaScript/TypeScript
if ls **/*.js **/*.ts **/*.jsx **/*.tsx 2>/dev/null | head -1 | grep -q .; then
  LANGUAGES="actions,javascript"
else
  LANGUAGES="actions"
fi
```

---

## Workflow Template

**Location:** `.github/workflows/codeql.yml`

### For PHP Projects (actions only)

PHP is NOT supported by CodeQL. For PHP projects, only scan `actions`:

```yaml
name: CodeQL

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]
  schedule:
    - cron: '0 6 * * 1'  # Weekly Monday 6 AM UTC

permissions: {}

jobs:
  analyze:
    name: Analyze
    runs-on: ubuntu-latest
    permissions:
      contents: read
      security-events: write
      actions: read

    steps:
      - name: Harden Runner
        uses: step-security/harden-runner@e3f713f2d8f53843e71c69a996d56f51aa9adfb9 # v2.14.1
        with:
          egress-policy: audit

      - name: Checkout repository
        uses: actions/checkout@de0fac2e4500dabe0009e67214ff5f5447ce83dd # v6.0.2

      - name: Initialize CodeQL
        uses: github/codeql-action/init@b20883b0cd1f46c72ae0ba6d1090936928f9fa30 # v4.32.0
        with:
          languages: actions
          queries: security-and-quality

      - name: Perform CodeQL Analysis
        uses: github/codeql-action/analyze@b20883b0cd1f46c72ae0ba6d1090936928f9fa30 # v4.32.0
        with:
          category: "/language:actions"
```

### For Projects with JavaScript/TypeScript

```yaml
name: CodeQL

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]
  schedule:
    - cron: '0 6 * * 1'

permissions: {}

jobs:
  analyze:
    name: Analyze (${{ matrix.language }})
    runs-on: ubuntu-latest
    permissions:
      contents: read
      security-events: write
      actions: read

    strategy:
      fail-fast: false
      matrix:
        language: [actions, javascript]

    steps:
      - name: Harden Runner
        uses: step-security/harden-runner@e3f713f2d8f53843e71c69a996d56f51aa9adfb9 # v2.14.1
        with:
          egress-policy: audit

      - name: Checkout repository
        uses: actions/checkout@de0fac2e4500dabe0009e67214ff5f5447ce83dd # v6.0.2

      - name: Initialize CodeQL
        uses: github/codeql-action/init@b20883b0cd1f46c72ae0ba6d1090936928f9fa30 # v4.32.0
        with:
          languages: ${{ matrix.language }}
          queries: security-and-quality

      - name: Autobuild
        uses: github/codeql-action/autobuild@b20883b0cd1f46c72ae0ba6d1090936928f9fa30 # v4.32.0

      - name: Perform CodeQL Analysis
        uses: github/codeql-action/analyze@b20883b0cd1f46c72ae0ba6d1090936928f9fa30 # v4.32.0
        with:
          category: "/language:${{ matrix.language }}"
```

---

## Checklist

When setting up CodeQL for a repository:

- [ ] Check if Default Setup is enabled: `gh api repos/OWNER/REPO/code-scanning/default-setup`
- [ ] If enabled, disable it: `gh api -X PATCH repos/OWNER/REPO/code-scanning/default-setup -f state="not-configured"`
- [ ] Detect languages in repository (JS/TS files present?)
- [ ] Create `.github/workflows/codeql.yml` with appropriate template
- [ ] **ALWAYS include `actions` language** (scans workflow files for security)
- [ ] Use SHA-pinned actions with version comments
- [ ] Include `step-security/harden-runner` for supply chain security
- [ ] Verify workflow runs successfully

---

## Common Issues

### "CodeQL analyses from advanced configurations cannot be processed when the default setup is enabled"

**Cause:** Repository has Default Setup enabled in Settings, conflicting with custom workflow.

**Fix:** Disable Default Setup via API before pushing codeql.yml:
```bash
gh api -X PATCH repos/OWNER/REPO/code-scanning/default-setup -f state="not-configured"
```

### "No source code was seen during the build"

**Cause:** For compiled languages, autobuild failed.

**Fix:** For interpreted languages (JS, Python), this is usually fine. For compiled languages, add custom build steps.

### PHP projects show no CodeQL results

**Cause:** PHP is not supported by CodeQL.

**Fix:** This is expected. For PHP projects, CodeQL only scans `actions` (workflow security). Use PHPStan, Psalm, or Semgrep for PHP static analysis.

---

## Integration with OpenSSF Scorecard

CodeQL contributes to the OpenSSF Scorecard `SAST` check. Having a properly configured CodeQL workflow improves your Scorecard score.

| Scorecard Check | CodeQL Contribution |
|-----------------|---------------------|
| SAST | +1 if CodeQL workflow exists and runs |
| Pinned-Dependencies | +1 if actions are SHA-pinned |
| Token-Permissions | +1 if permissions are minimized |
