#!/usr/bin/env bash
# Install Docker cross-distro.
# The get.docker.com convenience script does NOT support Arch, so we install
# from the repos there; everywhere else we use the official script.
set -euo pipefail
DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
# shellcheck source=common.sh
. "$DIR/common.sh"

if need_cmd docker; then
    info "docker already installed: $(docker --version)"
    exit 0
fi

# macOS: Docker Engine isn't native — install Docker Desktop via cask.
if is_mac; then
    info "installing Docker Desktop via brew (--cask docker)"
    brew install --cask docker \
        && info "Docker Desktop installed; launch it once to start the engine" \
        || warn "Docker Desktop install failed"
    exit 0
fi

case "$PKG" in
    pacman)
        pkg_install docker docker-compose
        if need_cmd systemctl && ! is_wsl; then
            $SUDO systemctl enable --now docker.service || true
        fi
        ;;
    *)
        info "installing docker via get.docker.com"
        need_cmd curl || pkg_install curl
        tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
        curl -fsSL https://get.docker.com -o "$tmp/get-docker.sh"
        $SUDO sh "$tmp/get-docker.sh"
        ;;
esac

# Let the current user run docker without sudo.
if [ "$(id -u)" -ne 0 ] && getent group docker >/dev/null 2>&1; then
    $SUDO usermod -aG docker "$USER" || true
    info "added $USER to the docker group (log out/in for it to take effect)"
fi

if need_cmd docker; then
    info "docker installed: $(docker --version)"
else
    err "docker installation failed"
    exit 1
fi
