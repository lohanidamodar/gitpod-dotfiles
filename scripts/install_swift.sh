#!/usr/bin/env bash
# Install Swift cross-distro.
#   Ubuntu/Debian/Fedora : the official `swiftly` toolchain manager (latest
#                          stable, self-updating) -> ~/.local/share/swiftly
#   Arch                 : swift-bin from the AUR (needs paru/yay)
set -euo pipefail
DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
# shellcheck source=common.sh
. "$DIR/common.sh"

if need_cmd swift; then
    info "swift already installed: $(swift --version 2>&1 | head -1)"
    exit 0
fi

# macOS: Swift ships with the Xcode Command Line Tools (the swiftly Linux
# toolchain below doesn't apply).
if is_mac; then
    if xcode-select -p >/dev/null 2>&1; then
        info "Xcode CLT present; 'swift' should be available. If not, run: xcode-select --install"
    else
        warn "installing Xcode Command Line Tools (a GUI dialog will open)…"
        xcode-select --install || warn "run 'xcode-select --install' manually"
    fi
    exit 0
fi

case "$(uname -m)" in
    x86_64)        march=x86_64 ;;
    aarch64|arm64) march=aarch64 ;;
    *) err "Unsupported architecture: $(uname -m)"; exit 1 ;;
esac

# ---- Arch: AUR ------------------------------------------------------------
if [ "$PKG" = "pacman" ]; then
    aur=""
    for h in paru yay; do need_cmd "$h" && { aur="$h"; break; }; done
    if [ -n "$aur" ]; then
        info "installing swift-bin from the AUR via $aur"
        "$aur" -S --needed --noconfirm swift-bin
        info "swift installed: $(swift --version 2>&1 | head -1)"
    else
        err "Swift isn't in Arch's official repos. Install an AUR helper first:"
        err "  git clone https://aur.archlinux.org/paru.git && cd paru && makepkg -si"
        err "then re-run this, or: <aur-helper> -S swift-bin"
        exit 1
    fi
    exit 0
fi

# ---- Debian/Ubuntu/Fedora: swiftly ----------------------------------------
# Base libs swiftly's toolchains link against at runtime.
info "installing swift build/runtime dependencies"
case "$PKG" in
    apt) pkg_install curl gnupg2 libcurl4-openssl-dev libedit2 libpython3-dev \
                     libsqlite3-0 libxml2-dev libz3-dev pkg-config tzdata zlib1g-dev \
                     libgcc-s1 libstdc++6 binutils clang || warn "some deps skipped" ;;
    dnf) pkg_install curl gcc-c++ libcurl-devel libedit-devel libuuid-devel \
                     libxml2-devel sqlite pkgconf-pkg-config python3-devel clang || warn "some deps skipped" ;;
    *)   need_cmd curl || pkg_install curl ;;
esac

tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
info "downloading swiftly (${march})"
curl -fsSL "https://download.swift.org/swiftly/linux/swiftly-${march}.tar.gz" \
    -o "$tmp/swiftly.tar.gz"
tar -xzf "$tmp/swiftly.tar.gz" -C "$tmp"

info "running swiftly init (installs the latest stable toolchain)"
"$tmp/swiftly" init --assume-yes --skip-install
swiftly_home="${SWIFTLY_HOME_DIR:-$HOME/.local/share/swiftly}"
# shellcheck disable=SC1091
[ -f "$swiftly_home/env.sh" ] && . "$swiftly_home/env.sh"
swiftly install latest --use

# Make `swift` visible to fish too (swiftly wires bash/zsh itself).
if [ -d "$HOME/.config/fish" ]; then
    mkdir -p "$HOME/.config/fish/conf.d"
    printf 'set -gx SWIFTLY_HOME_DIR "%s"\nfish_add_path "%s/bin"\n' \
        "$swiftly_home" "$swiftly_home" > "$HOME/.config/fish/conf.d/swiftly.fish"
fi

if need_cmd swift || [ -x "$swiftly_home/bin/swift" ]; then
    info "swift installed: $("$swiftly_home/bin/swift" --version 2>&1 | head -1 || swift --version 2>&1 | head -1)"
    info "open a new shell to get swift on PATH"
else
    warn "swiftly ran but swift isn't on PATH yet; open a new shell and run: swiftly install latest"
fi
