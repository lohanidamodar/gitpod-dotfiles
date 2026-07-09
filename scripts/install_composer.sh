#!/usr/bin/env bash
# Install Composer (PHP package manager) cross-distro.
# On Arch it's a repo package; elsewhere we use the official, checksum-verified
# installer and drop the phar into /usr/local/bin.
set -euo pipefail
DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
# shellcheck source=common.sh
. "$DIR/common.sh"

if need_cmd composer; then
    info "composer already installed: $(composer --version 2>/dev/null | head -1)"
    exit 0
fi

# Composer needs PHP. Install it via our php script if missing.
if ! need_cmd php; then
    info "php not found — installing it first"
    "$DIR/install_php.sh"
fi

# Arch packages Composer directly — simplest, keeps it updated with pacman.
if [ "$PKG" = "pacman" ]; then
    if pkg_install composer; then
        info "composer installed via pacman: $(composer --version 2>/dev/null | head -1)"
        exit 0
    fi
    warn "pacman composer install failed; falling back to the official installer"
fi

need_cmd curl  || pkg_install curl
need_cmd unzip || pkg_install unzip

tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
info "downloading Composer installer"
curl -fsSL https://getcomposer.org/installer -o "$tmp/composer-setup.php"

info "verifying installer checksum"
expected="$(curl -fsSL https://composer.github.io/installer.sig)"
actual="$(php -r "echo hash_file('sha384', '$tmp/composer-setup.php');")"
if [ "$expected" != "$actual" ]; then
    err "Composer installer checksum mismatch — aborting"
    exit 1
fi

info "installing composer to /usr/local/bin"
# Run the phar installer, then place the binary with the right privileges.
php "$tmp/composer-setup.php" --install-dir="$tmp" --filename=composer
$SUDO install -m 0755 "$tmp/composer" /usr/local/bin/composer

info "composer installed: $(composer --version 2>/dev/null | head -1)"
