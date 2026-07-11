#!/usr/bin/env bash
# Install zsh + the plugins our ~/.zshrc expects (autosuggestions, syntax
# highlighting) and the starship prompt. Cross-distro and macOS (Homebrew).
set -uo pipefail
DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
# shellcheck source=common.sh
. "$DIR/common.sh"

# ---- zsh itself ------------------------------------------------------------
if need_cmd zsh; then
    info "zsh already installed: $(zsh --version)"
else
    pkg_install zsh || warn "zsh install had issues"
    info "zsh installed: $(zsh --version 2>/dev/null || echo '?')"
fi

# ---- autosuggestions + syntax highlighting ---------------------------------
# Package names are identical across the managers we support; the .zshrc knows
# how to find them wherever each manager drops them. Fall back to a git clone
# into ~/.zsh (also a path the .zshrc searches) when the packages are absent.
if ! pkg_install zsh-autosuggestions zsh-syntax-highlighting; then
    warn "plugin packages unavailable; cloning into ~/.zsh instead"
    need_cmd git || pkg_install git
    mkdir -p "$HOME/.zsh"
    clone() {  # clone <repo> <dest-subdir>
        local dest="$HOME/.zsh/$2"
        if [ -d "$dest/.git" ]; then
            git -C "$dest" pull --ff-only --quiet || warn "update $2 failed"
        else
            git clone --depth 1 "$1" "$dest" || warn "clone $2 failed"
        fi
    }
    clone https://github.com/zsh-users/zsh-autosuggestions       zsh-autosuggestions
    clone https://github.com/zsh-users/zsh-syntax-highlighting   zsh-syntax-highlighting
fi

# ---- starship prompt -------------------------------------------------------
if need_cmd starship; then
    info "starship already installed: $(starship --version | head -1)"
elif [ "$PKG" = "brew" ]; then
    pkg_install starship || warn "starship install failed"
elif [ "$PKG" = "pacman" ] && pkg_install starship; then
    info "starship installed via pacman"
else
    info "installing starship into ~/.local/bin (no sudo)"
    need_cmd curl || pkg_install curl
    mkdir -p "$HOME/.local/bin"
    curl -fsSL https://starship.rs/install.sh \
        | sh -s -- --yes --bin-dir "$HOME/.local/bin" \
        || warn "starship install failed"
fi

info "zsh environment ready. Config is deployed by setup.sh to ~/.zshrc."
