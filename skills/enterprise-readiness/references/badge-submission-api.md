# Badge Data Submission Guide

> Practical guide for programmatically submitting OpenSSF Best Practices Badge data.

## Overview

The bestpractices.dev platform uses a Rails web application. There is no official REST API for
updating badge criteria. Submissions are done via authenticated HTML form PATCH requests.

## Submission Script

A Python script can automate badge data submission using session cookies:

```python
#!/usr/bin/env python3
"""Submit OpenSSF Best Practices Badge data.

Usage:
    BADGE_COOKIE='...' python3 submit-badge.py [--dry-run] [--level LEVEL]
"""
import json
import os
import re
import sys
import time
import urllib.parse
import urllib.request

COOKIE_NAME = '_BadgeApp_session'
PROJECT_ID = 12345  # Replace with your project ID
BASE_URL = 'https://www.bestpractices.dev/'

AUTH_TOKEN_PATTERN = re.compile(
    r'<input type="hidden" name="authenticity_token" value="([^"]+)"'
)
CSRF_TOKEN_PATTERN = re.compile(
    r'<meta name="csrf-token" content="([^"]+)"'
)

LEVELS = ['passing', 'silver', 'gold', 'baseline-1', 'baseline-2', 'baseline-3']
```

### Authentication

1. Log in to bestpractices.dev in your browser
2. Extract the `_BadgeApp_session` cookie value from browser DevTools
3. Pass it via environment variable: `BADGE_COOKIE='cookie_value_here'`

### Submission Flow

For each level:

1. **GET** the edit page to obtain CSRF tokens and update the session cookie
2. **PATCH** the level URL with form-encoded data

```
GET  /en/projects/{ID}/{level}/edit  → Extract authenticity_token + csrf-token
PATCH /en/projects/{ID}/{level}      → Submit form data with tokens
```

---

## Critical Gotchas

### 1. Cookie Handling - Do NOT URL-Decode

**CRITICAL**: The session cookie must be sent **exactly as received** from the browser. Do NOT URL-decode it.

```python
# CORRECT - send as-is
session_cookie = os.environ.get('BADGE_COOKIE', '')

# WRONG - URL decoding breaks session authentication
session_cookie = urllib.parse.unquote(os.environ.get('BADGE_COOKIE', ''))
```

**Symptom**: Writes appear to succeed (302 redirect) but data is silently not persisted.

### 2. URL-Required Justifications

Many criteria require `https://` URLs in the justification text. Without URLs, criteria show
"Warning: URL required, but no URL found" even when status is "Met".

**Affected criteria include** (not exhaustive):

| Level | Criteria Requiring URLs |
|-------|------------------------|
| Passing | `contribution_requirements`, `report_process`, `vulnerability_report_process`, `vulnerability_report_private` |
| Silver | `dco`, `governance`, `roles_responsibilities`, `access_continuity`, `bus_factor`, `documentation_architecture`, `documentation_achievements`, `vulnerability_report_credit`, `coding_standards`, `external_dependencies` |
| Gold | `bus_factor`, `contributors_unassociated`, `hardened_site`, `hardening` |

**Rule of thumb**: Always include at least one `https://` URL in every justification text.

```json
{
  "dco_justification": "DCO enforced via GitHub Actions: https://github.com/org/repo/blob/main/.github/workflows/dco.yml"
}
```

### 3. Auto-Detected Fields Cannot Be Set

These fields are auto-detected by the platform and **cannot** be set via form submission:

| Field | Why |
|-------|-----|
| `homepage_url_status` | Auto-detected from project URL |
| `report_url_status` | Auto-detected from issue tracker URL |
| `report_url` | Set at project creation, not a form field |

**Attempting to submit these fields causes HTTP 400 errors.**

Remove them from your badge data files before submission.

### 4. API Response Caching

The JSON API (`/projects/{ID}.json`) caches responses. After submitting new data:

```bash
# Add cache-buster parameter
curl -s "https://www.bestpractices.dev/projects/PROJECT_ID.json?_=$(date +%s)"
```

### 5. OSPS Baseline Field Names

OSPS Baseline criteria use a different naming convention in HTML forms:

| Display Format | Form Field Format |
|---------------|-------------------|
| `OSPS-AC-01.01` | `osps_ac_01_01_status` |
| `OSPS-BR-03.02` | `osps_br_03_02_status` |

Pattern: All lowercase, hyphens and dots become underscores.

### 6. Session Cookie Rotation

The server rotates session cookies via `Set-Cookie` headers. Your script must track
cookie updates across requests:

```python
def get_updated_cookie(headers, old_cookie):
    set_cookie = headers.get('Set-Cookie', '')
    if set_cookie.startswith(COOKIE_NAME + '='):
        return set_cookie.split('=', 1)[1].split(';', 1)[0]
    return old_cookie
```

### 7. Rate Limiting

Add delays between level submissions to avoid rate limiting:

```python
time.sleep(5)  # Wait 5 seconds between levels
```

---

## Badge Data File Format

Structure badge data as JSON files per level:

```
badge-data-passing.json
badge-data-silver.json
badge-data-gold.json
badge-data-baseline-1.json
badge-data-baseline-2.json
badge-data-baseline-3.json
```

Each file contains field name/value pairs:

```json
{
  "criterion_name_status": "Met",
  "criterion_name_justification": "Explanation with https://github.com/org/repo/evidence"
}
```

Valid status values: `Met`, `Unmet`, `N/A`, `?` (unknown)

---

## Verification

After submission, verify via API:

```bash
# Check badge level
curl -s "https://www.bestpractices.dev/projects/PROJECT_ID.json?_=$(date +%s)" | \
  jq '{badge_level, badge_percentage_0, badge_percentage_1, badge_percentage_2}'

# badge_percentage_0 = Passing
# badge_percentage_1 = Silver
# badge_percentage_2 = Gold
```

---

## Troubleshooting

| Problem | Cause | Fix |
|---------|-------|-----|
| 302 redirect but data not saved | URL-decoded cookie | Send cookie as-is, no `urllib.parse.unquote()` |
| HTTP 400 on PATCH | Submitting auto-detected fields | Remove `homepage_url_status`, `report_url_status` from data |
| Criteria shows `?` despite Met status | Missing URL in justification | Add `https://` URL to justification text |
| Stale API response after submit | Response caching | Add `?_=$(date +%s)` cache-buster |
| GET returns 302 redirect | Cookie expired | Get fresh cookie from browser |
