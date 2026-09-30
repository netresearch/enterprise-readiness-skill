#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: Netresearch DTT GmbH
#
# Behaviour tests for skills/enterprise-readiness/scripts/check-tls-minimum.sh.
# Each case scans a directory holding one fixture file.
# Usage: bash tests/check-tls-minimum.sh

# shellcheck source=tests/helpers.bash
source "$(dirname "${BASH_SOURCE[0]}")/helpers.bash"

SCRIPT="$SCRIPTS/check-tls-minimum.sh"

# fixture NAME FILE CONTENT: writes CONTENT to $WORK/NAME/FILE, prints the dir.
fixture() {
    local name="$1" file="$2" content="$3"
    mkdir -p "$WORK/$name"
    printf '%b' "$content" > "$WORK/$name/$file"
    echo "$WORK/$name"
    return 0
}

check "Go MinVersion TLS 1.2 is met" 0 "crypto_tls12 = Met" \
    -- bash "$SCRIPT" "$(fixture go12 main.go 'cfg := &tls.Config{\n\tMinVersion: tls.VersionTLS12,\n}\n')"
check "Go MinVersion TLS 1.0 is an issue" 1 "Insecure TLS version (TLS 1.0 or 1.1)" \
    -- bash "$SCRIPT" "$(fixture go10 main.go 'cfg := &tls.Config{MinVersion: tls.VersionTLS10}\n')"
check "Go InsecureSkipVerify is a warning" 0 "InsecureSkipVerify enabled" \
    -- bash "$SCRIPT" "$(fixture goskip main.go 'cfg := &tls.Config{InsecureSkipVerify: true}\n')"
check "Go tls.Config without MinVersion is a warning" 0 "MinVersion not explicitly set" \
    -- bash "$SCRIPT" "$(fixture gonone main.go 'cfg := &tls.Config{}\n')"
check "Go test files are ignored" 0 "crypto_tls12 = N/A" \
    -- bash "$SCRIPT" "$(fixture gotest main_test.go 'cfg := &tls.Config{MinVersion: tls.VersionTLS10}\n')"

check "Python PROTOCOL_TLS_CLIENT is met" 0 "Modern TLS protocol configured" \
    -- bash "$SCRIPT" "$(fixture pyclient app.py 'import ssl\nctx = ssl.SSLContext(ssl.PROTOCOL_TLS_CLIENT)\n')"
check "Python PROTOCOL_TLSv1 is deprecated" 1 "Deprecated protocol version" \
    -- bash "$SCRIPT" "$(fixture pytls1 app.py 'import ssl\nctx = ssl.SSLContext(ssl.PROTOCOL_TLSv1)\n')"
check "Python PROTOCOL_TLSv1_1 is deprecated" 1 "Deprecated protocol version" \
    -- bash "$SCRIPT" "$(fixture pytls11 app.py 'import ssl\nctx = ssl.SSLContext(ssl.PROTOCOL_TLSv1_1)\n')"
check "Python CERT_NONE is a warning" 0 "Certificate verification disabled" \
    -- bash "$SCRIPT" "$(fixture pycert app.py 'import ssl\nctx.verify_mode = ssl.CERT_NONE\n')"

check "Node minVersion TLSv1.2 is met" 0 "TLS 1.2+ minimum configured" \
    -- bash "$SCRIPT" "$(fixture js12 server.js 'const tls = require("tls");\ntls.createServer({ minVersion: "TLSv1.2" });\n')"
check "Node rejectUnauthorized false is a warning" 0 "Certificate verification disabled" \
    -- bash "$SCRIPT" "$(fixture jsreject client.js 'https.request({ rejectUnauthorized: false });\n')"
check "Node file without TLS settings passes" 0 "crypto_tls12 = N/A" \
    -- bash "$SCRIPT" "$(fixture jsplain client.js 'https.get("https://example.org/secret-path");\n')"
absent "scanned source lines are not echoed" "secret-path"

check "config with TLS 1.0 is an issue" 1 "Deprecated TLS/SSL version in config" \
    -- bash "$SCRIPT" "$(fixture cfg config.yml 'tls_version: 1.0\n')"
check "directory without TLS usage is N/A" 0 "No TLS configurations found to check." \
    -- bash "$SCRIPT" "$(fixture none README.txt 'nothing\n')"

summary "check-tls-minimum.sh"
