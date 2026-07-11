#!/usr/bin/env bash
# Install the standalone Dart SDK from the official archive (distro-agnostic).
# (Arch's dart lives in the AUR; the zip avoids needing an AUR helper.)
set -euo pipefail
DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
# shellcheck source=common.sh
. "$DIR/common.sh"

if need_cmd dart; then
    info "dart already installed: $(dart --version 2>&1 | head -1)"
    exit 0
fi

need_cmd curl  || pkg_install curl
need_cmd unzip || pkg_install unzip

case "$(uname -m)" in
    x86_64)        arch=x64 ;;
    aarch64|arm64) arch=arm64 ;;
    *) err "Unsupported architecture: $(uname -m)"; exit 1 ;;
esac
os=linux; is_mac && os=macos      # the archive ships linux/macos/windows builds

dest="$HOME/dart-sdk"
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
url="https://storage.googleapis.com/dart-archive/channels/stable/release/latest/sdk/dartsdk-${os}-${arch}-release.zip"
info "downloading Dart SDK (${os}-${arch})"
curl -fsSL "$url" -o "$tmp/dart.zip"
unzip -q "$tmp/dart.zip" -d "$tmp"
rm -rf "$dest"
mv "$tmp/dart-sdk" "$dest"

# PATH for bash + fish
grep -q 'dart-sdk/bin' "$HOME/.bash_profile" 2>/dev/null || \
    echo 'export PATH="$HOME/dart-sdk/bin:$PATH"' >> "$HOME/.bash_profile"
if [ -d "$HOME/.config/fish" ]; then
    mkdir -p "$HOME/.config/fish/conf.d"
    echo 'fish_add_path "$HOME/dart-sdk/bin"' > "$HOME/.config/fish/conf.d/dart.fish"
fi

info "dart installed to $dest/bin ($("$dest/bin/dart" --version 2>&1 | head -1))"
