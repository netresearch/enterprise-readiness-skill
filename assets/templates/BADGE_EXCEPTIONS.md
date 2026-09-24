# OpenSSF Best Practices Badge - Exceptions and Justifications

> Documentation for badge criteria answered Unmet or N/A, with their justification.

## Project Information

| Field | Value |
|-------|-------|
| Project | [PROJECT_NAME] |
| Badge Level | Passing / Silver / Gold |
| Last Updated | [DATE] |

---

## Summary of Exceptions

`two_person_review`, `contributors_unassociated` and `bus_factor` do not accept N/A: answer them Met or Unmet, with a justification. Compensating controls are worth describing, but a bot review is not a second person and documentation is not a second maintainer, so they never make the answer Met.

| Criterion | Level | Status | Justification Summary |
|-----------|-------|--------|----------------------|
| `two_person_review` | Gold | Unmet | [N] of the last [M] merged pull requests approved by a human other than the author |
| `contributors_unassociated` | Gold | Unmet | Contributors come from [ORGANISATION] only |
| `bus_factor` | Silver (SHOULD) / Gold (MUST) | Unmet | One active author in the last twelve months |
| `accessibility_best_practices` | Silver | N/A | CLI tool, no UI |
| `internationalization` | Silver | N/A | Developer tooling |

---

## Detailed Justifications

### Solo Maintainer Criteria

#### `two_person_review` (Gold)

**Status:** Unmet

**Justification:**
[N] of the last [M] merged pull requests carry an approving review from a person other than the
author. Automated review runs on every pull request, but it is not a second person.

**Measurement:** `references/badge-submission-api.md` § *Solo Maintainer Justification Patterns*.

---

#### `contributors_unassociated` (Gold)

**Status:** Unmet

**Justification:**
The contributors of the last [PERIOD] come from [ORGANISATION]. The project accepts contributions
from anyone (CONTRIBUTING.md), but has none from unassociated organisations yet.

---

#### `bus_factor` (Silver/Gold)

**Status:** Unmet (a justified Unmet still passes Silver, where the criterion is a SHOULD)

**Justification:**
One person authored the changes of the last twelve months; nobody else currently knows the project
well enough to continue it.

**Measurement:** `references/badge-submission-api.md` § *Solo Maintainer Justification Patterns*.

---

### Technical N/A Criteria

#### `accessibility_best_practices` (Silver)

**Form Question:** "Does the project follow accessibility best practices?"

**Status:** N/A

**Justification:**
This is a command-line tool / library with no user interface. Accessibility best practices
for visual UI elements do not apply.

**Evidence:**
- No HTML, CSS, or frontend code
- CLI output follows standard conventions
- Documentation available in accessible text formats

---

#### `internationalization` (Silver)

**Form Question:** "Does the project support internationalization?"

**Status:** N/A

**Justification:**
This is developer tooling where the primary user base is English-speaking developers.
The project outputs technical information (logs, errors) that are typically not localized
in developer tools.

**Compensating Controls:**
- Error messages are clear and actionable
- Documentation is comprehensive
- Contributions for i18n would be accepted if needed

---

#### `crypto_used_network` (Silver)

**Form Question:** "Is cryptography used for network communications?"

**Status:** N/A

**Justification:**
This project does not perform network communications. It operates entirely on local files
and does not transmit data over networks.

**Evidence:**
- No network-related imports in codebase
- No HTTP client or server code
- Offline-only operation

---

#### `sites_password_security` (Silver)

**Form Question:** "Are passwords stored securely if applicable?"

**Status:** N/A

**Justification:**
This project does not store, process, or handle passwords. There is no user authentication
or credential management functionality.

**Evidence:**
- No password-related code
- No user authentication
- No credential storage

---

## Review History

| Date | Reviewer | Changes |
|------|----------|---------|
| YYYY-MM-DD | @maintainer | Initial exceptions documented |
| YYYY-MM-DD | @maintainer | Updated compensating controls |

---

## Certification

I certify that the above justifications are accurate and the compensating controls
described are implemented and active.

**Maintainer:** ________________________

**Date:** ________________________
