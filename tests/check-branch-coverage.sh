#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: Netresearch DTT GmbH
#
# Behaviour tests for skills/enterprise-readiness/scripts/check-branch-coverage.sh.
# A stub `go` on PATH stands in for `go test` and `go tool cover`; its
# statement coverage comes from STUB_COVERAGE, and STUB_TEST_FAIL=1 makes
# `go test` fail. A locally installed Go toolchain is never called.
# Usage: bash tests/check-branch-coverage.sh

# shellcheck source=tests/helpers.bash
source "$(dirname "${BASH_SOURCE[0]}")/helpers.bash"

SCRIPT="$SCRIPTS/check-branch-coverage.sh"

mkdir -p "$WORK/bin"
cat > "$WORK/bin/go" <<'EOF'
#!/usr/bin/env bash
case "$1" in
    test)
        [[ "${STUB_TEST_FAIL:-0}" == 1 ]] && exit 1
        printf 'mode: atomic\n' > coverage.out ;;
    tool)
        printf 'example/app.go:3:\tRun\t%s%%\n' "$STUB_COVERAGE"
        printf 'total:\t(statements)\t%s%%\n' "$STUB_COVERAGE" ;;
esac
EOF
chmod +x "$WORK/bin/go"

PROJECT="$WORK/project"
mkdir -p "$PROJECT/vendor/dep"
printf 'package app\n\nfunc Run(x int) int {\n\tif x > 0 {\n\t\treturn 1\n\t}\n\treturn 0\n}\n' > "$PROJECT/app.go"
printf 'package app\n\nfunc t() { if true {} }\n' > "$PROJECT/app_test.go"
printf 'package dep\n\nfunc d() { if true {} }\n' > "$PROJECT/vendor/dep/d.go"

run() { (cd "$PROJECT" && PATH="$WORK/bin:$PATH" bash "$SCRIPT" "$@"); }

export STUB_COVERAGE=90.0
check "estimate above threshold passes" 0 "Estimated branch coverage (72.0%) meets threshold (70%)" -- run --threshold 70
check "project without switch or select is assessed" 0 "Total decision points: 1" -- run --threshold 70
check "test and vendor files are not counted" 0 "if statements: 1" -- run --threshold 70
check "estimate below threshold fails" 1 "is below threshold (80%)" -- run
check "positional threshold is accepted" 1 "Threshold: 95%" -- run 95

STUB_TEST_FAIL=1 check "failing tests fail the check" 1 "Error: Tests failed" -- run

summary "check-branch-coverage.sh"
