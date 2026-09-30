#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: Netresearch DTT GmbH
#
# Behaviour tests for skills/enterprise-readiness/scripts/verify-badge-criteria.sh.
# The script reports a score and exits 0 for every valid level; only an
# invalid level exits non-zero. The level is the first positional argument.
# Usage: bash tests/verify-badge-criteria.sh

# shellcheck source=tests/helpers.bash
source "$(dirname "${BASH_SOURCE[0]}")/helpers.bash"

SCRIPT="$SCRIPTS/verify-badge-criteria.sh"

run_in() { local dir="$1"; shift; (cd "$dir" && bash "$SCRIPT" "$@"); return $?; }

mkdir -p "$WORK/bare" "$WORK/full/.github/workflows"
check "invalid level fails" 1 "Error: Level must be passing, silver, or gold" -- run_in "$WORK/bare" platinum
check "help exits 0" 0 "verify-badge-criteria.sh [passing|silver|gold]" -- run_in "$WORK/bare" --help
absent "help shows no --level flag" "--level"

check "empty project scores 0" 0 "Score: 0/10 (0%)" -- run_in "$WORK/bare"
check "missing README is reported" 0 "README.md missing" -- run_in "$WORK/bare" passing
absent "passing level skips silver checks" "Silver Level Checks"

FULL="$WORK/full"
for f in README.md LICENSE SECURITY.md GOVERNANCE.md CODE_OF_CONDUCT.md ARCHITECTURE.md; do
    touch "$FULL/$f"
done
echo "All commits need a DCO sign-off." > "$FULL/CONTRIBUTING.md"
cat > "$FULL/.github/workflows/ci.yml" <<'EOF'
jobs:
  build:
    steps:
      - uses: slsa-framework/slsa-github-generator@v2
      - run: cosign sign-blob artefact
      - run: syft . -o spdx-json
      - run: golangci-lint run
      - uses: github/codeql-action/init@v3
      - uses: gitleaks/gitleaks-action@v2
      - run: go test -coverprofile=c.out && check coverage 80
EOF

check "complete passing project scores 10/10" 0 "Score: 10/10 (100%)" -- run_in "$WORK/full" passing
check "complete project is excellent" 0 "Status: Excellent - Ready for passing certification" -- run_in "$WORK/full" passing
check "silver adds governance checks" 0 "GOVERNANCE.md exists" -- run_in "$WORK/full" silver
check "silver finds the DCO" 0 "DCO mentioned in CONTRIBUTING.md" -- run_in "$WORK/full" silver
check "silver scores 15/15" 0 "Score: 15/15 (100%)" -- run_in "$WORK/full" silver
check "gold counts files without SPDX headers" 0 "SPDX headers missing in some files (0/0)" -- run_in "$WORK/full" gold
check "gold without tags skips the tag check" 0 "No tags found (N/A)" -- run_in "$WORK/full" gold
check "gold reports missing 90% threshold" 0 "90% coverage threshold not found in CI" -- run_in "$WORK/full" gold

summary "verify-badge-criteria.sh"
