#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: Netresearch DTT GmbH
#
# Behaviour tests for
# skills/enterprise-readiness/scripts/check-coverage-threshold.sh with Python
# and generic coverage reports. The Go profile branch needs `go tool cover`
# and is not covered here. Arguments are positional: THRESHOLD FILE.
# Usage: bash tests/check-coverage-threshold.sh

# shellcheck source=tests/helpers.bash
source "$(dirname "${BASH_SOURCE[0]}")/helpers.bash"

SCRIPT="$SCRIPTS/check-coverage-threshold.sh"

cat > "$WORK/python.txt" <<'EOF'
Name          Stmts   Miss  Cover
---------------------------------
app.py           40      6    85%
---------------------------------
TOTAL            40      6    85%
EOF
printf 'Lines covered: 91.5%%\n' > "$WORK/generic.txt"
printf 'nothing to see here\n' > "$WORK/none.txt"

check "missing file fails" 1 "Coverage file not found: $WORK/nope.out" -- bash "$SCRIPT" 80 "$WORK/nope.out"
check "Python report is detected" 0 "Format: Python coverage report" -- bash "$SCRIPT" 80 "$WORK/python.txt"
check "Python coverage above threshold passes" 0 "Coverage 85% meets threshold 80%" -- bash "$SCRIPT" 80 "$WORK/python.txt"
check "Python coverage below threshold fails" 1 "Coverage 85% is below threshold 90%" -- bash "$SCRIPT" 90 "$WORK/python.txt"
check "coverage equal to threshold passes" 0 "meets threshold 85%" -- bash "$SCRIPT" 85 "$WORK/python.txt"
check "generic percentage is extracted" 0 "Coverage 91.5% meets threshold 90%" -- bash "$SCRIPT" 90 "$WORK/generic.txt"
check "file without a percentage fails" 1 "Could not extract coverage percentage" -- bash "$SCRIPT" 80 "$WORK/none.txt"

summary "check-coverage-threshold.sh"
