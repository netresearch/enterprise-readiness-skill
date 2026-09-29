#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: Netresearch DTT GmbH
#
# Behaviour tests for skills/enterprise-readiness/scripts/verify-spdx-headers.sh.
# Usage: bash tests/verify-spdx-headers.sh

# shellcheck source=tests/helpers.bash
source "$(dirname "${BASH_SOURCE[0]}")/helpers.bash"

SCRIPT="$SCRIPTS/verify-spdx-headers.sh"

run_in() { local dir="$1"; shift; (cd "$dir" && bash "$SCRIPT" "$@"); }

# All headers present.
mkdir -p "$WORK/ok/src"
printf '// SPDX-License-Identifier: MIT\npackage main\n' > "$WORK/ok/src/main.go"
printf '#!/bin/sh\n# SPDX-License-Identifier: MIT\necho hi\n' > "$WORK/ok/run.sh"
check "all files with headers pass" 0 "All source files have SPDX license headers" -- run_in "$WORK/ok" .
check "files are counted" 0 "Total files checked: 2" -- run_in "$WORK/ok" .

# One file without a header.
mkdir -p "$WORK/missing"
printf 'print("x")\n' > "$WORK/missing/tool.py"
printf '// SPDX-License-Identifier: MIT\n' > "$WORK/missing/ok.js"
check "missing header fails" 1 "Missing SPDX header: ./tool.py" -- run_in "$WORK/missing" .
check "missing header is counted" 1 "Files missing headers: 1" -- run_in "$WORK/missing" .

# A header after line 10 does not count.
mkdir -p "$WORK/late"
{ for _ in 1 2 3 4 5 6 7 8 9 10; do echo "# filler"; done; echo "# SPDX-License-Identifier: MIT"; } > "$WORK/late/late.sh"
check "header after line 10 is not found" 1 "Missing SPDX header: ./late.sh" -- run_in "$WORK/late" .

# Dependency and build directories are skipped.
mkdir -p "$WORK/deps/vendor/lib" "$WORK/deps/node_modules/m" "$WORK/deps/build" "$WORK/deps/src"
printf 'package lib\n' > "$WORK/deps/vendor/lib/lib.go"
printf 'module.exports = 1\n' > "$WORK/deps/node_modules/m/index.js"
printf 'echo built\n' > "$WORK/deps/build/out.sh"
printf '# SPDX-License-Identifier: MIT\n' > "$WORK/deps/src/app.py"
check "vendor, node_modules and build are skipped" 0 "Total files checked: 1" -- run_in "$WORK/deps" .

# A target directory named like an excluded one is still scanned.
check "target named build is scanned" 1 "Missing SPDX header: build/out.sh" -- run_in "$WORK/deps" build

# Nothing to check.
mkdir -p "$WORK/empty"
check "directory without source files passes" 0 "No source files found to check." -- run_in "$WORK/empty" .

summary "verify-spdx-headers.sh"
