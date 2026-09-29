#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: Netresearch DTT GmbH
#
# Behaviour tests for Build/Scripts/check-plugin-version.sh, which the pre-push
# hook runs: a semver tag at HEAD must match .claude-plugin/plugin.json.
# Usage: bash tests/check-plugin-version.sh

# shellcheck source=tests/helpers.bash
source "$(dirname "${BASH_SOURCE[0]}")/helpers.bash"

SCRIPT="$ROOT/Build/Scripts/check-plugin-version.sh"

# repo NAME VERSION [TAG]: repository with plugin.json at VERSION, HEAD tagged TAG.
repo() {
    local dir="$WORK/$1"
    new_repo "$dir"
    mkdir -p "$dir/.claude-plugin"
    printf '{"name": "x", "version": "%s"}\n' "$2" > "$dir/.claude-plugin/plugin.json"
    if [[ -n "${3:-}" ]]; then
        git -C "$dir" tag "$3"
    fi
    echo "$dir"
}

run_in() { (cd "$1" && bash "$SCRIPT"); }

check "no tag at HEAD passes silently" 0 "" -- run_in "$(repo untagged 1.2.3)"
empty "no output without a tag"
check "v-prefixed tag matching plugin.json passes" 0 "" -- run_in "$(repo vtag 1.2.3 v1.2.3)"
check "bare tag matching plugin.json passes" 0 "" -- run_in "$(repo baretag 1.2.3 1.2.3)"
check "tag not matching plugin.json fails" 1 \
    "plugin.json version (1.2.4) does not match any semver tag at HEAD" \
    -- run_in "$(repo mismatch 1.2.4 v1.2.3)"
check "non-semver tag is ignored" 0 "" -- run_in "$(repo nonsemver 1.2.4 release-1)"

summary "check-plugin-version.sh"
