#!/usr/bin/env bash
# Install Nerd Fonts so tmux/terminal icons render.
#   - JetBrainsMono Nerd Font : a full patched monospace font
#   - Symbols Nerd Font        : just the glyphs, handy as a fallback font
# Tries the native package manager first, then falls back to the GitHub
# release zips. Fonts go to ~/.local/share/fonts and fc-cache is refreshed.
#
# NOTE (WSL): Windows Terminal renders fonts from the *Windows* side, so a
# Linux-installed font won't show up there on its own. Install the same Nerd
# Font on Windows (the .ttf files land in ~/.local/share/fonts here) and pick
# it in your terminal's font setting.
set -euo pipefail
DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
# shellcheck source=common.sh
. "$DIR/common.sh"

NERD_VERSION="${NERD_VERSION:-v3.4.0}"
FONT_DIR="$HOME/.local/share/fonts/NerdFonts"

# macOS: install via Homebrew casks (fonts land in ~/Library/Fonts, no fc-cache).
if is_mac; then
    info "installing Nerd Fonts via brew casks"
    brew install --cask font-jetbrains-mono-nerd-font font-symbols-only-nerd-font \
        && info "Nerd Fonts installed. Set your terminal font to 'JetBrainsMono Nerd Font'." \
        || warn "Nerd Font cask install failed"
    exit 0
fi

# fc-cache lives in fontconfig; make sure it's around for the fallback path.
need_cmd fc-cache || pkg_install fontconfig || warn "couldn't install fontconfig"

# ---- fast path: native packages --------------------------------------------
case "$PKG" in
    pacman)
        if pkg_install ttf-jetbrains-mono-nerd ttf-nerd-fonts-symbols; then
            info "installed Nerd Fonts via pacman"; fc-cache -f >/dev/null 2>&1 || true; exit 0
        fi ;;
    dnf)
        if pkg_install jetbrains-mono-fonts-all; then
            info "installed JetBrains Mono via dnf (adding symbols from release below)"
        fi ;;
esac

# ---- fallback: download the release zips -----------------------------------
if ! need_cmd unzip; then pkg_install unzip || { err "need unzip"; exit 1; }; fi

base="https://github.com/ryanoasis/nerd-fonts/releases/download/${NERD_VERSION}"
mkdir -p "$FONT_DIR"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

for font in JetBrainsMono NerdFontsSymbolsOnly; do
    info "downloading ${font} (${NERD_VERSION})"
    if curl -fsSL "$base/${font}.zip" -o "$tmp/${font}.zip"; then
        unzip -oq "$tmp/${font}.zip" -d "$FONT_DIR" -x "*.md" "LICENSE*" || warn "unzip ${font} failed"
    else
        warn "download of ${font} failed; skipping"
    fi
done

info "refreshing font cache"
fc-cache -f "$FONT_DIR" >/dev/null 2>&1 || fc-cache -f >/dev/null 2>&1 || true

if fc-list 2>/dev/null | grep -qi "nerd"; then
    info "Nerd Fonts installed. Set your terminal font to 'JetBrainsMono Nerd Font'."
else
    warn "Nerd Fonts may not have registered; check ~/.local/share/fonts/NerdFonts"
fi
