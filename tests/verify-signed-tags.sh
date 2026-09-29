#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: Netresearch DTT GmbH
#
# Behaviour tests for skills/enterprise-readiness/scripts/verify-signed-tags.sh.
# The signed case uses an SSH signing key generated for the test, so no GPG
# keyring is needed; it requires ssh-keygen.
# Usage: bash tests/verify-signed-tags.sh

# shellcheck source=tests/helpers.bash
source "$(dirname "${BASH_SOURCE[0]}")/helpers.bash"

SCRIPT="$SCRIPTS/verify-signed-tags.sh"

run_in() { local dir="$1"; shift; (cd "$dir" && bash "$SCRIPT" "$@"); }

REPO="$WORK/repo"
new_repo "$REPO"

check "repository without tags passes" 0 "No release tags (v*) found." -- run_in "$REPO"
check "unknown tag fails" 1 "Tag 'v9.9.9' does not exist" -- run_in "$REPO" v9.9.9

git -C "$REPO" tag v1.0.0
check "lightweight tag fails" 1 "v1.0.0: Lightweight tag" -- run_in "$REPO" v1.0.0

git -C "$REPO" tag -a v1.1.0 -m "Release v1.1.0"
check "annotated unsigned tag fails" 1 "v1.1.0: Annotated but NOT signed" -- run_in "$REPO" v1.1.0
check "recent release tags fail when one is unsigned" 1 "version_tags_signed = Unmet" -- run_in "$REPO"

# Signed tag with an SSH key the repository trusts.
ssh-keygen -q -t ed25519 -N "" -C test -f "$WORK/key"
printf 'author@example.org %s\n' "$(cat "$WORK/key.pub")" > "$WORK/allowed_signers"
git -C "$REPO" config gpg.format ssh
git -C "$REPO" config user.signingkey "$WORK/key"
git -C "$REPO" config gpg.ssh.allowedSignersFile "$WORK/allowed_signers"
git -C "$REPO" tag -s v2.0.0 -m "Release v2.0.0"
check "signed tag passes" 0 "v2.0.0: Signed and verified" -- run_in "$REPO" v2.0.0

check "check-all counts every tag" 1 "Total tags: 3" -- run_in "$REPO" --check-all
check "check-all counts the signed tag" 1 "Signed: 1" -- run_in "$REPO" --check-all

SIGNED="$WORK/signed"
new_repo "$SIGNED"
git -C "$SIGNED" config gpg.format ssh
git -C "$SIGNED" config user.signingkey "$WORK/key"
git -C "$SIGNED" config gpg.ssh.allowedSignersFile "$WORK/allowed_signers"
git -C "$SIGNED" tag -s v1.0.0 -m "Release v1.0.0"
check "only signed tags meet the criterion" 0 "version_tags_signed = Met" -- run_in "$SIGNED" --check-all

summary "verify-signed-tags.sh"
