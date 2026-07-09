#!/usr/bin/env bash
# Install eza (the maintained successor to exa) cross-distro.
# Prefers the native package; falls back to the official GitHub release binary.
# The fish config already aliases ls/ll/la/lt to eza when present.
set -euo pipefail
DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
# shellcheck source=common.sh
. "$DIR/common.sh"

if need_cmd eza; then
    info "eza already installed: $(eza --version | tail -1)"
    exit 0
fi

# ---- native package where available ----------------------------------------
case "$PKG" in
    pacman) pkg_install eza && { info "eza installed via pacman"; exit 0; } || true ;;
    dnf)    pkg_install eza && { info "eza installed via dnf"; exit 0; } || true ;;
    apk)    pkg_install eza && { info "eza installed via apk"; exit 0; } || true ;;
    apt)    pkg_install eza 2>/dev/null && { info "eza installed via apt"; exit 0; } || \
                info "eza not in apt repos; using GitHub release" ;;
esac

# ---- fallback: official release tarball -------------------------------------
need_cmd curl || pkg_install curl
need_cmd tar  || pkg_install tar

case "$(uname -m)" in
    x86_64)        target="x86_64-unknown-linux-gnu" ;;
    aarch64|arm64) target="aarch64-unknown-linux-gnu" ;;
    *) err "Unsupported architecture: $(uname -m)"; exit 1 ;;
esac

tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
url="https://github.com/eza-community/eza/releases/latest/download/eza_${target}.tar.gz"
info "downloading eza (${target})"
curl -fsSL "$url" -o "$tmp/eza.tar.gz"
tar -xzf "$tmp/eza.tar.gz" -C "$tmp"
$SUDO install -m 0755 "$tmp/eza" /usr/local/bin/eza

info "eza installed: $(eza --version | tail -1)"
