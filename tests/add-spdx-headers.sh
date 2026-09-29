#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: Netresearch DTT GmbH
#
# Behaviour tests for skills/enterprise-readiness/scripts/add-spdx-headers.sh,
# which rewrites Go, Python and JavaScript/TypeScript files in the current
# directory. The licence and copyright holder are positional arguments.
# Usage: bash tests/add-spdx-headers.sh

# shellcheck source=tests/helpers.bash
source "$(dirname "${BASH_SOURCE[0]}")/helpers.bash"

SCRIPT="$SCRIPTS/add-spdx-headers.sh"
YEAR="$(date +%Y)"
DIR="$WORK/project"

mkdir -p "$DIR/pkg" "$DIR/vendor/dep" "$DIR/node_modules/m"
printf 'package pkg\n' > "$DIR/pkg/a.go"
printf '#!/usr/bin/env python3\nprint("x")\n' > "$DIR/tool.py"
printf 'import os\n' > "$DIR/lib.py"
printf 'export const x = 1;\n' > "$DIR/app.ts"
printf '// SPDX-License-Identifier: Apache-2.0\nconst y = 2;\n' > "$DIR/kept.js"
printf 'package dep\n' > "$DIR/vendor/dep/d.go"
printf 'module.exports = 1;\n' > "$DIR/node_modules/m/i.js"

run() { (cd "$DIR" && bash "$SCRIPT" "$@"); }

check "run reports the licence" 0 "License: Apache-2.0" -- run Apache-2.0 "Example Corp"

first_lines() { head -n "$2" "$DIR/$1"; }

check "Go file gets a // header" 0 "// SPDX-License-Identifier: Apache-2.0" -- first_lines pkg/a.go 1
check "Go file gets the copyright line" 0 "// Copyright (c) $YEAR Example Corp" -- first_lines pkg/a.go 2
check "Python shebang stays on line 1" 0 "#!/usr/bin/env python3" -- first_lines tool.py 1
check "Python header follows the shebang" 0 "# SPDX-License-Identifier: Apache-2.0" -- first_lines tool.py 2
check "Python file without shebang gets a header" 0 "# SPDX-License-Identifier: Apache-2.0" -- first_lines lib.py 1
check "TypeScript file gets a header" 0 "// SPDX-License-Identifier: Apache-2.0" -- first_lines app.ts 1
check "original content is kept" 0 "export const x = 1;" -- cat "$DIR/app.ts"

check "existing header is left alone" 0 "" -- cat "$DIR/kept.js"
absent "no second header in kept.js" "Example Corp"
check "vendor is skipped" 0 "" -- cat "$DIR/vendor/dep/d.go"
absent "vendor file unchanged" "SPDX"
check "node_modules is skipped" 0 "" -- cat "$DIR/node_modules/m/i.js"
absent "node_modules file unchanged" "SPDX"

before="$(cat "$DIR/pkg/a.go" "$DIR/tool.py")"
check "second run succeeds" 0 "" -- run Apache-2.0 "Example Corp"
check "second run adds nothing" 0 "" -- test "$before" = "$(cat "$DIR/pkg/a.go" "$DIR/tool.py")"

summary "add-spdx-headers.sh"
