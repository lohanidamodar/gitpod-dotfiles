#!/usr/bin/env bash
# Install yq (mikefarah/yq) — the YAML/JSON/XML processor. mac + Linux.
# Handy for editing docker-compose.yml and Kubernetes manifests from scripts.
set -euo pipefail
DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
# shellcheck source=common.sh
. "$DIR/common.sh"

if need_cmd yq; then
    info "yq already installed: $(yq --version 2>/dev/null)"
    exit 0
fi

if is_mac; then
    pkg_install yq && { info "yq installed via brew"; exit 0; } || { err "yq brew install failed"; exit 1; }
fi

# Arch packages the Go yq as `go-yq`; prefer it when present.
[ "$PKG" = "pacman" ] && pkg_install go-yq && { info "yq installed via pacman (go-yq)"; exit 0; } || true

need_cmd curl || pkg_install curl
case "$(uname -m)" in
    x86_64)        arch=amd64 ;;
    aarch64|arm64) arch=arm64 ;;
    *) err "Unsupported architecture: $(uname -m)"; exit 1 ;;
esac

url="https://github.com/mikefarah/yq/releases/latest/download/yq_linux_${arch}"
info "downloading yq (${arch}) from GitHub release"
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
curl -fsSL "$url" -o "$tmp/yq"
$SUDO install -m 0755 "$tmp/yq" /usr/local/bin/yq

info "yq installed: $(yq --version 2>/dev/null)"
