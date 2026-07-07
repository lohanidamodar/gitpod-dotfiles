#!/usr/bin/env bash
# Install the GitHub CLI (gh) cross-distro.
set -euo pipefail
DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
# shellcheck source=common.sh
. "$DIR/common.sh"

if need_cmd gh; then
    info "gh already installed: $(gh --version | head -1)"
    exit 0
fi

case "$PKG" in
    pacman) pkg_install github-cli ;;
    dnf)    pkg_install gh ;;
    zypper) pkg_install gh ;;
    apk)    pkg_install github-cli ;;
    apt)
        info "adding GitHub CLI apt repo"
        pkg_install curl ca-certificates
        $SUDO install -m 0755 -d /etc/apt/keyrings
        curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
            | $SUDO tee /etc/apt/keyrings/githubcli-archive-keyring.gpg >/dev/null
        $SUDO chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
            | $SUDO tee /etc/apt/sources.list.d/github-cli.list >/dev/null
        pkg_refresh
        pkg_install gh
        ;;
    *) err "Unsupported package manager for gh install"; exit 1 ;;
esac

info "gh installed: $(gh --version | head -1)"
