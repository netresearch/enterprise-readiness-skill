#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: Netresearch DTT GmbH
#
# Behaviour tests for
# skills/enterprise-readiness/scripts/verify-review-requirements.sh. A stub
# `gh` on PATH answers the three API reads the script makes (classic branch
# protection, branch rules, one ruleset) from the STUB_* variables below; no
# request reaches GitHub. Requires jq.
# Usage: bash tests/verify-review-requirements.sh

# shellcheck source=tests/helpers.bash
source "$(dirname "${BASH_SOURCE[0]}")/helpers.bash"

SCRIPT="$SCRIPTS/verify-review-requirements.sh"

mkdir -p "$WORK/bin" "$WORK/cwd"
cat > "$WORK/bin/gh" <<'EOF'
#!/usr/bin/env bash
# STUB_PROTECTION: JSON body of the protection read; unset means "not protected".
# STUB_PROTECTION_ERROR: error text for the protection read instead.
# STUB_RULES: JSON array of branch rules (default []).
# STUB_BYPASS: bypass actor count of every ruleset (default 0).
if [[ "$1" == auth ]]; then exit 0; fi
args="$*"
case "$args" in
    *"/protection"*)
        if [[ -n "${STUB_PROTECTION_ERROR:-}" ]]; then
            echo "gh: $STUB_PROTECTION_ERROR (HTTP 404)" >&2; exit 1
        elif [[ -n "${STUB_PROTECTION:-}" ]]; then
            echo "$STUB_PROTECTION"
        else
            echo '{"message":"Branch not protected"}'
            echo "gh: Branch not protected (HTTP 404)" >&2; exit 1
        fi ;;
    *"/rules/branches/"*) echo "${STUB_RULES:-[]}" ;;
    *"/rulesets/"*) echo "${STUB_BYPASS:-0}" ;;
    *) echo "unexpected gh call: $args" >&2; exit 99 ;;
esac
EOF
chmod +x "$WORK/bin/gh"

run() { (cd "$WORK/cwd" && PATH="$WORK/bin:$PATH" bash "$SCRIPT" --owner o --repo r "$@"); }

check "invalid level fails" 1 "Error: Invalid level" -- run --level bronze
check "repository is required outside a clone" 1 "Could not determine repository" \
    -- bash -c "cd '$WORK/cwd' && PATH='$WORK/bin':\$PATH bash '$SCRIPT'"

check "no protection and no ruleset fails" 1 "No review requirement configured for main" -- run --level silver
check "passing level needs no review" 0 "Branch protection settings for passing level: sufficient." -- run --level passing

STUB_PROTECTION_ERROR="Not Found" check "unreadable protection stops the assessment" 2 \
    "Classic branch protection of main could not be read" -- run --level silver

export STUB_PROTECTION='{"required_pull_request_reviews":{"required_approving_review_count":1,"dismiss_stale_reviews":true},"required_status_checks":{"contexts":["ci"]},"enforce_admins":{"enabled":true}}'
check "classic protection with one review meets silver" 0 "Branch protection requires 1 approving review(s)" -- run --level silver
check "stale review dismissal is read" 0 "Dismiss stale reviews: true" -- run --level silver
check "status checks are counted" 0 "Required status checks: 1" -- run --level silver
check "gold notes that bot approvals count" 0 "bot approvals satisfy a required review count" -- run --level gold
unset STUB_PROTECTION

export STUB_RULES='[{"type":"pull_request","ruleset_id":7,"parameters":{"required_approving_review_count":2,"dismiss_stale_reviews_on_push":false,"require_code_owner_review":true}},{"type":"required_status_checks","ruleset_id":7,"parameters":{"required_status_checks":[{"context":"lint"},{"context":"test"}]}}]'
check "ruleset review count is read" 0 "Required approving reviews: 2" -- run --level gold
check "ruleset status checks are counted" 0 "Required status checks: 2" -- run --level gold
check "ruleset code owner review is read" 0 "Code owner reviews required" -- run --level gold
STUB_BYPASS=1 check "ruleset bypass actors are reported" 0 "Ruleset 7 lets 1 actor(s) bypass it" -- run --level gold

export STUB_RULES='[{"type":"pull_request","ruleset_id":7,"parameters":{"required_approving_review_count":0}}]'
check "ruleset without approvals is insufficient for silver" 1 "Insufficient reviewers: 0 < 1 required" -- run --level silver

summary "verify-review-requirements.sh"
