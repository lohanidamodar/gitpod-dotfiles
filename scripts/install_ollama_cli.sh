#!/usr/bin/env bash
# Install the Ollama CLI from the official release archive, cross-distro.
set -euo pipefail
DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
# shellcheck source=common.sh
. "$DIR/common.sh"

if need_cmd ollama; then
    info "ollama already installed at $(command -v ollama): $(ollama --version 2>&1 | head -1)"
    exit 0
fi

# macOS: brew (the release archive below is Linux-only and unpacks into /usr).
if is_mac; then
    pkg_install ollama && { info "ollama installed via brew"; exit 0; } || { err "ollama brew install failed"; exit 1; }
fi

case "$(uname -m)" in
    x86_64)        pkg=ollama-linux-amd64.tar.zst ;;
    aarch64|arm64) pkg=ollama-linux-arm64.tar.zst ;;
    *) err "Unsupported architecture: $(uname -m)"; exit 1 ;;
esac

need_cmd curl || pkg_install curl
if ! need_cmd zstd; then
    info "installing zstd (required to extract the release archive)"
    pkg_install zstd
fi

tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
url="https://github.com/ollama/ollama/releases/latest/download/$pkg"
info "downloading $url"
curl --fail --location --progress-bar "$url" -o "$tmp/$pkg"

info "extracting to /usr"
$SUDO tar --zstd -C /usr -xf "$tmp/$pkg"

info "ollama installed: $(ollama --version 2>&1 | head -1)"
echo "OLLAMA_HOST is read from your environment; do not run 'ollama serve' here."
