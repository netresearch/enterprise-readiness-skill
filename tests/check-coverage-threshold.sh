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

for threshold in -1 101 nonsense 80percent; do
    check "invalid threshold $threshold fails" 1 "Threshold must be a number between 0 and 100" \
        -- bash "$SCRIPT" "$threshold" "$WORK/python.txt"
done
check "zero threshold is valid" 0 "meets threshold 0%" -- bash "$SCRIPT" 0 "$WORK/python.txt"
check "decimal threshold is valid" 0 "meets threshold 84.5%" -- bash "$SCRIPT" 84.5 "$WORK/python.txt"
printf 'TOTAL 40 0 101%%\n' > "$WORK/invalid.txt"
check "out-of-range reported coverage fails" 1 "Extracted coverage must be a number between 0 and 100" \
    -- bash "$SCRIPT" 80 "$WORK/invalid.txt"
printf 'Lines covered: -80%%\n' > "$WORK/negative.txt"
check "negative generic coverage fails" 1 "Extracted coverage must be a number between 0 and 100" \
    -- bash "$SCRIPT" 75 "$WORK/negative.txt"
printf 'Lines covered: -.80%%\n' > "$WORK/negative-decimal.txt"
check "negative decimal without leading zero fails" 1 "Extracted coverage must be a number between 0 and 100" \
    -- bash "$SCRIPT" 80 "$WORK/negative-decimal.txt"
printf '87.5%%\n' > "$WORK/bare.txt"
check "generic percentage at line start is extracted" 0 "Coverage 87.5% meets threshold 80%" \
    -- bash "$SCRIPT" 80 "$WORK/bare.txt"

summary "check-coverage-threshold.sh"
