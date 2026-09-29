#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: Netresearch DTT GmbH
#
# Behaviour tests for skills/enterprise-readiness/scripts/analyze-bus-factor.sh.
# The bus factor is the number of authors needed to cover half of the commits
# in the period. Arguments are positional: DAYS THRESHOLD.
# Usage: bash tests/analyze-bus-factor.sh

# shellcheck source=tests/helpers.bash
source "$(dirname "${BASH_SOURCE[0]}")/helpers.bash"

SCRIPT="$SCRIPTS/analyze-bus-factor.sh"

run_in() { local dir="$1"; shift; (cd "$dir" && bash "$SCRIPT" "$@"); }

# commit_as DIR NAME: one empty commit by NAME.
commit_as() {
    GIT_AUTHOR_NAME="$2" GIT_AUTHOR_EMAIL="$2@example.org" \
        git -C "$1" commit -q --allow-empty -m "change by $2"
}

mkdir -p "$WORK/plain"
check "outside a git repository fails" 1 "Error: Not a git repository" -- run_in "$WORK/plain"

SOLO="$WORK/solo"
mkdir -p "$SOLO"
git -C "$SOLO" init -q -b main
commit_as "$SOLO" alice
commit_as "$SOLO" alice
check "single author is below threshold 2" 1 "Bus factor (1) below threshold (2)" -- run_in "$SOLO"
check "single author meets threshold 1" 0 "Bus factor (1) meets threshold (1)" -- run_in "$SOLO" 365 1

TEAM="$WORK/team"
mkdir -p "$TEAM"
git -C "$TEAM" init -q -b main
for author in alice bob carol dave; do commit_as "$TEAM" "$author"; done
check "four equal authors give bus factor 2" 0 "Authors needed for 50% of commits: 2" -- run_in "$TEAM"
check "bus factor 2 meets threshold 2" 0 "Bus factor (2) meets threshold (2)" -- run_in "$TEAM"
check "distribution lists each author" 0 "Total commits: 4" -- run_in "$TEAM"

OLD="$WORK/old"
mkdir -p "$OLD"
git -C "$OLD" init -q -b main
GIT_AUTHOR_DATE="2001-01-01T00:00:00Z" GIT_COMMITTER_DATE="2001-01-01T00:00:00Z" commit_as "$OLD" alice
check "no commits in the period fails" 1 "Bus Factor: 0 (no activity)" -- run_in "$OLD" 30

summary "analyze-bus-factor.sh"
