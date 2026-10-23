#!/bin/bash
# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: Netresearch DTT GmbH
# check-coverage-threshold.sh - Validate test coverage meets requirements
# Usage: ./check-coverage-threshold.sh [THRESHOLD] [COVERAGE_FILE]
#   THRESHOLD      required coverage in percent (default: 80)
#   COVERAGE_FILE  Go profile, Python report or any text with a percentage
#                  (default: coverage.out)
set -euo pipefail

THRESHOLD="${1:-80}"
COVERAGE_FILE="${2:-coverage.out}"

# Reject malformed thresholds rather than letting awk coerce them during comparison.
if [[ ! "$THRESHOLD" =~ ^[0-9]+([.][0-9]+)?$ ]] ||
    ! awk -v value="$THRESHOLD" 'BEGIN {exit !(value >= 0 && value <= 100)}'; then
    echo "Error: Threshold must be a number between 0 and 100"
    exit 1
fi

echo "=== Coverage Threshold Check ==="
echo "Required: ${THRESHOLD}%"
echo "Coverage file: $COVERAGE_FILE"
echo ""

if [[ ! -f "$COVERAGE_FILE" ]]; then
    echo "Error: Coverage file not found: $COVERAGE_FILE"
    echo ""
    echo "Generate coverage with:"
    echo "  Go: go test -coverprofile=coverage.out ./..."
    echo "  Python: pytest --cov=. --cov-report=term"
    echo "  Node: npm test -- --coverage"
    exit 1
fi

# Detect coverage format and extract percentage
if head -1 "$COVERAGE_FILE" | grep -q "^mode:"; then
    # Go coverage format
    COVERAGE=$(go tool cover -func="$COVERAGE_FILE" 2>/dev/null | grep total | awk '{print $3}' | tr -d '%')
    echo "Format: Go coverage profile"
elif grep -q "TOTAL" "$COVERAGE_FILE"; then
    # Python coverage format
    COVERAGE=$(grep "TOTAL" "$COVERAGE_FILE" | awk '{print $NF}' | tr -d '%')
    echo "Format: Python coverage report"
else
    # Take the last percentage in the file, keeping a leading minus so the range check rejects it
    # (POSIX-compatible, works on macOS and Linux)
    COVERAGE=$(grep -oE -- '-?[0-9]+([.][0-9]+)?%' "$COVERAGE_FILE" 2>/dev/null | tail -1 | tr -d '%' || true)
    echo "Format: Generic"
fi

if [[ -z "$COVERAGE" ]]; then
    echo "Error: Could not extract coverage percentage"
    exit 1
fi

if [[ ! "$COVERAGE" =~ ^[0-9]+([.][0-9]+)?$ ]] ||
    ! awk -v value="$COVERAGE" 'BEGIN {exit !(value >= 0 && value <= 100)}'; then
    echo "Error: Extracted coverage must be a number between 0 and 100"
    exit 1
fi

echo "Coverage: ${COVERAGE}%"
echo ""

# Compare using awk for floating point (POSIX-compatible, no bc dependency)
if awk -v cov="$COVERAGE" -v thresh="$THRESHOLD" 'BEGIN {exit !(cov >= thresh)}' 2>/dev/null; then
    echo "✓ Coverage ${COVERAGE}% meets threshold ${THRESHOLD}%"
    exit 0
else
    echo "✗ Coverage ${COVERAGE}% is below threshold ${THRESHOLD}%"
    echo ""
    echo "To increase coverage:"
    echo "1. Run: go test -coverprofile=coverage.out ./..."
    echo "2. View: go tool cover -html=coverage.out"
    echo "3. Add tests for uncovered code paths"
    exit 1
fi
