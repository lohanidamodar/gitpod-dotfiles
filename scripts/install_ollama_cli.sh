#!/usr/bin/env bash
set -euo pipefail

if command -v ollama >/dev/null 2>&1; then
    echo "[info] ollama already installed at $(command -v ollama)"
    ollama --version 2>&1 | head -1 || true
    exit 0
fi

arch=$(uname -m)
case "$arch" in
    x86_64)        pkg=ollama-linux-amd64.tar.zst ;;
    aarch64|arm64) pkg=ollama-linux-arm64.tar.zst ;;
    *) echo "Unsupported architecture: $arch" >&2; exit 1 ;;
esac

if ! command -v zstd >/dev/null 2>&1; then
    echo "[info] installing zstd (required to extract release archive)"
    sudo apt-get update -qq && sudo apt-get install -y zstd
fi

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

url="https://github.com/ollama/ollama/releases/latest/download/$pkg"
echo "[info] downloading $url"
curl --fail --location --progress-bar "$url" -o "$tmp/$pkg"

echo "[info] extracting to /usr (requires sudo)"
sudo tar --zstd -C /usr -xf "$tmp/$pkg"

echo "[ok] installed: $(ollama --version 2>&1 | head -1)"
echo
echo "OLLAMA_HOST is read from your environment; do not run 'ollama serve' here."
