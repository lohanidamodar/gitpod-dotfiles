#!/usr/bin/env bash
# Install doctl (DigitalOcean CLI) from the official GitHub release tarball.
# Works on any glibc Linux regardless of package manager.
set -euo pipefail
DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
# shellcheck source=common.sh
. "$DIR/common.sh"

if need_cmd doctl; then
    info "doctl already installed: $(doctl version | head -1)"
    exit 0
fi

# On Arch it's packaged; prefer that when available.
if [ "$PKG" = "pacman" ]; then
    pkg_install doctl && { info "doctl installed via pacman"; exit 0; } || true
fi

need_cmd curl || pkg_install curl
need_cmd tar  || pkg_install tar

case "$(uname -m)" in
    x86_64)        arch=amd64 ;;
    aarch64|arm64) arch=arm64 ;;
    *) err "Unsupported architecture: $(uname -m)"; exit 1 ;;
esac

ver=$(curl -fsSL https://api.github.com/repos/digitalocean/doctl/releases/latest \
        | grep -Po '"tag_name": *"v\K[0-9.]+')
[ -n "$ver" ] || { err "Could not determine latest doctl version"; exit 1; }

tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
url="https://github.com/digitalocean/doctl/releases/download/v${ver}/doctl-${ver}-linux-${arch}.tar.gz"
info "downloading doctl ${ver} (${arch})"
curl -fsSL "$url" -o "$tmp/doctl.tar.gz"
tar -xzf "$tmp/doctl.tar.gz" -C "$tmp"
$SUDO install -m 0755 "$tmp/doctl" /usr/local/bin/doctl

info "doctl installed: $(doctl version | head -1)"
echo "Authenticate with: doctl auth init"
