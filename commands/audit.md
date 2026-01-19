---
description: "Run enterprise readiness assessment on current project"
---

# Enterprise Readiness Audit

Run a comprehensive enterprise readiness assessment on the current project.

## Steps

1. **Identify project type and stack**
   - Detect language (Go, PHP, Python, Node.js, etc.)
   - Identify frameworks and key dependencies
   - Check for existing CI/CD configuration

2. **Security Assessment**
   - Check for dependency scanning (Dependabot, Renovate, Snyk)
   - Verify SAST tools (CodeQL, Semgrep, PHPStan)
   - Check for secrets detection (gitleaks, truffleHog)
   - Assess SLSA compliance level
   - Look for SBOM generation

3. **Quality Assessment**
   - Check test coverage configuration
   - Verify linting setup
   - Check for pre-commit hooks
   - Assess documentation completeness

4. **CI/CD Assessment**
   - Check workflow security (pinned actions, minimal permissions)
   - Verify release automation
   - Check for signed commits/releases

5. **Generate Report**
   Use the enterprise-readiness outputStyle for the report:

   ```
   ## Enterprise Readiness Score: X/100

   ### Security (X/40)
   - [ ] Dependency scanning
   - [ ] SAST analysis
   - [ ] Secrets detection
   - [ ] SLSA Level X

   ### Quality (X/30)
   - [ ] Test coverage >80%
   - [ ] Linting enforced
   - [ ] Pre-commit hooks

   ### CI/CD (X/30)
   - [ ] Pinned action versions
   - [ ] Signed releases
   - [ ] Automated deployments

   ### Priority Actions
   1. [Critical] ...
   2. [High] ...
   3. [Medium] ...
   ```

6. **Provide actionable recommendations**
   - Order by impact and effort
   - Include specific file changes needed
