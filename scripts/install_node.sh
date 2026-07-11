#!/usr/bin/env bash
# Install Node.js + npm cross-distro.
# Arch/Fedora ship current Node in their repos; Debian/Ubuntu's is stale, so we
# pull NodeSource (Node 22 LTS) there. npm comes bundled either way.
set -euo pipefail
DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
# shellcheck source=common.sh
. "$DIR/common.sh"

if need_cmd node && need_cmd npm; then
    info "node $(node -v) / npm $(npm -v) already installed"
    exit 0
fi

case "$PKG" in
    brew)   pkg_install node ;;                 # bundles npm
    pacman) pkg_install nodejs npm ;;
    dnf)    pkg_install nodejs npm ;;
    zypper) pkg_install nodejs npm ;;
    apk)    pkg_install nodejs npm ;;
    apt)
        info "adding NodeSource repo (Node 22 LTS)"
        pkg_install curl ca-certificates
        curl -fsSL https://deb.nodesource.com/setup_22.x | $SUDO -E bash -
        pkg_install nodejs
        ;;
    *) err "Unsupported package manager for node install"; exit 1 ;;
esac

info "node $(node -v) / npm $(npm -v) installed"
