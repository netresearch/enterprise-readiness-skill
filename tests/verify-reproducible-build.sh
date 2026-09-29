#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: Netresearch DTT GmbH
#
# Behaviour tests for
# skills/enterprise-readiness/scripts/verify-reproducible-build.sh through its
# `make` build type (`make build` twice, then the output hashes are compared).
# Requires make.
# Usage: bash tests/verify-reproducible-build.sh

# shellcheck source=tests/helpers.bash
source "$(dirname "${BASH_SOURCE[0]}")/helpers.bash"

SCRIPT="$SCRIPTS/verify-reproducible-build.sh"

run_in() { local dir="$1"; shift; (cd "$dir" && bash "$SCRIPT" "$@"); }

mkdir -p "$WORK/same" "$WORK/differs" "$WORK/nothing"
printf 'build:\n\tprintf "fixed content\\n" > out.bin\n' > "$WORK/same/Makefile"
printf 'build:\n\tdate +%%s%%N > out.bin\n' > "$WORK/differs/Makefile"
printf 'build:\n\t@true\n' > "$WORK/nothing/Makefile"

check "unknown build type fails" 1 "Error: Unknown build type 'cmake'" -- run_in "$WORK/same" cmake out.bin
check "output path with shell metacharacters is rejected" 1 "Error: Output path contains invalid characters" \
    -- run_in "$WORK/same" make 'out.bin;id'
check "identical builds pass" 0 "build_reproducible = Met" -- run_in "$WORK/same" make out.bin
check "differing builds fail" 1 "Builds are DIFFERENT" -- run_in "$WORK/differs" make out.bin
check "missing build output fails" 1 "Error: Build output not found: out.bin" -- run_in "$WORK/nothing" make out.bin

summary "verify-reproducible-build.sh"
