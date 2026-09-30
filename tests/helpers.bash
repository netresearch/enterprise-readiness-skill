# shellcheck shell=bash
# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: Netresearch DTT GmbH
#
# Shared helpers for the behaviour tests in tests/*.sh. Sourced, not run:
# the .bash extension keeps it out of the tests/**/*.sh glob that CI executes.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck disable=SC2034  # read by the test files that source this one
SCRIPTS="$ROOT/skills/enterprise-readiness/scripts"

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

PASS=0
FAIL=0

# Git runs without the caller's global or system configuration, so signing
# defaults, hooks and templates of the developer's machine cannot change a
# result.
export GIT_CONFIG_GLOBAL=/dev/null
export GIT_CONFIG_NOSYSTEM=1
export GIT_AUTHOR_NAME="Test Author" GIT_AUTHOR_EMAIL="author@example.org"
export GIT_COMMITTER_NAME="Test Author" GIT_COMMITTER_EMAIL="author@example.org"

# check NAME EXPECTED_RC EXPECTED_OUTPUT -- COMMAND...
# Runs COMMAND, then compares its exit code and requires EXPECTED_OUTPUT as a
# fixed substring of the combined stdout and stderr. An empty EXPECTED_OUTPUT
# only checks the exit code.
check() {
    local name="$1" expected_rc="$2" expected_out="$3"
    shift 4
    local rc
    set +e
    OUT="$("$@" 2>&1)"
    rc=$?
    set -e
    if [[ "$rc" -eq "$expected_rc" ]] && { [[ -z "$expected_out" ]] || grep -qF -- "$expected_out" <<< "$OUT"; }; then
        echo "ok   $name"
        PASS=$((PASS + 1))
    else
        echo "FAIL $name (exit $rc, expected $expected_rc; expected output: $expected_out)"
        while IFS= read -r line; do printf '    | %s\n' "$line"; done <<< "$OUT"
        FAIL=$((FAIL + 1))
    fi
}

# absent NAME TEXT: TEXT must not appear in the output of the last check.
absent() {
    local name="$1" text="$2"
    if grep -qF -- "$text" <<< "$OUT"; then
        echo "FAIL $name (unexpected output: $text)"
        FAIL=$((FAIL + 1))
    else
        echo "ok   $name"
        PASS=$((PASS + 1))
    fi
}

# empty NAME: the last check must have printed nothing.
empty() {
    if [[ -z "$OUT" ]]; then
        echo "ok   $1"
        PASS=$((PASS + 1))
    else
        echo "FAIL $1 (expected no output)"
        while IFS= read -r line; do printf '    | %s\n' "$line"; done <<< "$OUT"
        FAIL=$((FAIL + 1))
    fi
}

# summary LABEL: prints the tally and returns non-zero if any case failed.
summary() {
    echo ""
    echo "$1: $PASS passed, $FAIL failed"
    [[ "$FAIL" -eq 0 ]]
}

# new_repo DIR: creates a git repository with one commit.
new_repo() {
    local dir="$1"
    mkdir -p "$dir"
    git -C "$dir" init -q -b main
    git -C "$dir" commit -q --allow-empty -m "initial"
    return $?
}
