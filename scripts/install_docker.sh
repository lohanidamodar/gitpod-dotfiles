#!/usr/bin/env bash
# Install Docker cross-distro.
# The get.docker.com convenience script does NOT support Arch, so we install
# from the repos there; everywhere else we use the official script.
set -euo pipefail
DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
# shellcheck source=common.sh
. "$DIR/common.sh"

# macOS: use Dory — a free, open-source (GPL-3.0) Docker/Linux-containers engine
# built on Apple's native macOS containerization (Apple silicon, macOS 15+).
# It's an OrbStack/Docker Desktop alternative: serves the Docker API on
# ~/.dory/dory.sock and registers a `dory` docker context, so existing
# docker/compose commands work unchanged. https://github.com/Augani/dory
if is_mac; then
    if brew list --cask dory >/dev/null 2>&1; then
        info "Dory already installed"
    else
        info "installing Dory (open-source Docker for macOS containers)"
        brew install --cask Augani/dory/dory || warn "Dory cask install failed"
    fi
    # Dory is the engine; the `docker` CLI client is separate — install it too.
    need_cmd docker || brew install docker || warn "docker CLI install failed"
    info "Open Dory once to start the engine (registers the 'dory' context / ~/.dory/dory.sock)."
    info "Intel Macs also need a separate engine (Colima/Podman/…); Apple silicon is native."
    exit 0
fi

if need_cmd docker; then
    info "docker already installed: $(docker --version)"
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
