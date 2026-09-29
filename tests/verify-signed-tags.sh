#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: Netresearch DTT GmbH
#
# Behaviour tests for skills/enterprise-readiness/scripts/verify-signed-tags.sh.
# Signed tags are made with an SSH key and a GnuPG key generated for the test
# in temporary directories; the developer's keyrings are never used. Requires
# ssh-keygen and gpg (2.1 or later).
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

# tamper REPO TAG NEW: copies the signed tag object TAG with its tag name
# changed to NEW, so the signature no longer matches the content.
tamper() {
    local obj
    obj=$(git -C "$1" cat-file tag "$2" | sed "s/^tag $2\$/tag $3/" | git -C "$1" mktag)
    git -C "$1" update-ref "refs/tags/$3" "$obj"
}

# SSH: signed, but the key is not in the allowed signers file.
UNTRUSTED="$WORK/untrusted"
new_repo "$UNTRUSTED"
git -C "$UNTRUSTED" config gpg.format ssh
git -C "$UNTRUSTED" config user.signingkey "$WORK/key"
git -C "$UNTRUSTED" tag -s v1.0.0 -m "Release v1.0.0"
check "ssh tag without allowed signers is signed, not trusted" 1 \
    "v1.0.0: Signed, but the signing key is not trusted here" -- run_in "$UNTRUSTED" v1.0.0
absent "untrusted ssh tag is not called unsigned" "NOT signed"
ssh-keygen -q -t ed25519 -N "" -C other -f "$WORK/other"
printf 'author@example.org %s\n' "$(cat "$WORK/other.pub")" > "$WORK/other_signers"
git -C "$UNTRUSTED" config gpg.ssh.allowedSignersFile "$WORK/other_signers"
check "ssh tag by a key missing from allowed signers is not trusted" 1 "No principal matched" \
    -- run_in "$UNTRUSTED" v1.0.0
check "check-all counts untrusted tags separately" 1 "Signed, key not trusted: 1" \
    -- run_in "$UNTRUSTED" --check-all
check "untrusted tags do not meet the criterion" 1 "version_tags_signed = Unmet" \
    -- run_in "$UNTRUSTED" --check-all

# SSH: signature that does not match the tag.
tamper "$REPO" v2.0.0 v2.0.1
check "tampered ssh tag is invalid" 1 "v2.0.1: Signature INVALID" -- run_in "$REPO" v2.0.1

# GnuPG: verified, unknown key, tampered. GNUPGHOME is kept short because
# gpg-agent's socket path has a length limit.
GPG_REPO="$WORK/gpg"
new_repo "$GPG_REPO"
GNUPGHOME="$(mktemp -d)"
EMPTY_GNUPGHOME="$(mktemp -d)"
export GNUPGHOME
chmod 700 "$GNUPGHOME" "$EMPTY_GNUPGHOME"
trap 'gpgconf --kill all 2>/dev/null; GNUPGHOME="$EMPTY_GNUPGHOME" gpgconf --kill all 2>/dev/null; rm -rf "$WORK" "$GNUPGHOME" "$EMPTY_GNUPGHOME"' EXIT
gpg --batch --quiet --pinentry-mode loopback --passphrase '' \
    --quick-gen-key author@example.org ed25519 sign never
git -C "$GPG_REPO" config user.signingkey author@example.org
git -C "$GPG_REPO" tag -s v1.0.0 -m "Release v1.0.0"
check "gpg tag with a known key passes" 0 "v1.0.0: Signed and verified" -- run_in "$GPG_REPO" v1.0.0
GNUPGHOME="$EMPTY_GNUPGHOME" check "gpg tag with an unknown key is signed, not trusted" 1 \
    "v1.0.0: Signed, but the signing key is not trusted here" -- run_in "$GPG_REPO" v1.0.0
check "unknown gpg key is named" 1 "NO_PUBKEY" -- env GNUPGHOME="$EMPTY_GNUPGHOME" bash -c "cd '$GPG_REPO' && bash '$SCRIPT' v1.0.0"
tamper "$GPG_REPO" v1.0.0 v1.0.1
check "tampered gpg tag is invalid" 1 "v1.0.1: Signature INVALID" -- run_in "$GPG_REPO" v1.0.1

summary "verify-signed-tags.sh"
