#!/usr/bin/env bash
# Install Flutter (stable) via git clone (distro-agnostic). Bundles its own Dart.
set -euo pipefail
DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
# shellcheck source=common.sh
. "$DIR/common.sh"

if need_cmd flutter; then
    info "flutter already installed: $(flutter --version 2>/dev/null | head -1)"
    exit 0
fi

# Toolchain Flutter needs on Linux.
info "installing Flutter build dependencies"
case "$PKG" in
    pacman) pkg_install git curl unzip xz which zip base-devel clang cmake ninja gtk3 || true ;;
    apt)    pkg_install git curl unzip xz-utils zip libglu1-mesa clang cmake ninja-build pkg-config libgtk-3-dev || true ;;
    dnf)    pkg_install git curl unzip xz zip clang cmake ninja-build gtk3-devel || true ;;
    *)      pkg_install git curl unzip xz zip || true ;;
esac

dest="$HOME/flutter"
if [ -d "$dest" ]; then
    info "$dest already exists; pulling latest stable"
    git -C "$dest" pull --ff-only || true
else
    info "cloning flutter stable to $dest"
    git clone --depth 1 -b stable https://github.com/flutter/flutter.git "$dest"
fi

# PATH for bash + fish
grep -q 'flutter/bin' "$HOME/.bash_profile" 2>/dev/null || \
    echo 'export PATH="$HOME/flutter/bin:$PATH"' >> "$HOME/.bash_profile"
if [ -d "$HOME/.config/fish" ]; then
    mkdir -p "$HOME/.config/fish/conf.d"
    echo 'fish_add_path "$HOME/flutter/bin"' > "$HOME/.config/fish/conf.d/flutter.fish"
fi

export PATH="$dest/bin:$PATH"
info "running flutter precache (this downloads the Dart SDK + artifacts)"
flutter --disable-analytics >/dev/null 2>&1 || true
flutter precache

info "flutter installed: $("$dest/bin/flutter" --version 2>/dev/null | head -1)"
echo "Tip: run 'flutter doctor' to check remaining setup (Android SDK, Chrome, etc.)."
