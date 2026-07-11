#!/usr/bin/env bash
# Install Visual Studio Code + the `code` CLI, cross-platform (macOS + Linux).
#   macOS         : brew cask
#   Debian/Ubuntu : Microsoft apt repo
#   Fedora/openSUSE: Microsoft rpm repo
#   Arch          : AUR (visual-studio-code-bin) if a helper exists, else Code-OSS
#   fallback      : snap (--classic) or flatpak
#
# Opt-in extras: INSTALL_VSCODE_EXTENSIONS=1 installs a curated set for this
# stack (Flutter/Dart, PHP, Docker, ESLint/Prettier, GitLens, YAML).
set -uo pipefail
DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
# shellcheck source=common.sh
. "$DIR/common.sh"

link_mac_cli() {   # expose the `code` CLI from the app bundle on ~/.local/bin
    local codebin="/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"
    if [ -x "$codebin" ] && ! need_cmd code; then
        mkdir -p "$HOME/.local/bin"
        ln -sf "$codebin" "$HOME/.local/bin/code"
        info "linked the 'code' CLI into ~/.local/bin"
    fi
}

install_extensions() {
    need_cmd code || { warn "'code' CLI not on PATH; skipping extensions (open a new shell and re-run)"; return; }
    info "installing curated VS Code extensions"
    local ext
    for ext in \
        Dart-Code.dart-code Dart-Code.flutter \
        bmewburn.vscode-intelephense-client \
        ms-azuretools.vscode-docker \
        dbaeumer.vscode-eslint esbenp.prettier-vscode \
        eamodio.gitlens redhat.vscode-yaml \
        ms-kubernetes-tools.vscode-kubernetes-tools; do
        code --install-extension "$ext" --force >/dev/null 2>&1 \
            && info "  + $ext" || warn "  ! $ext failed"
    done
}

if need_cmd code; then
    info "VS Code already installed: $(code --version 2>/dev/null | head -1)"
    [ "${INSTALL_VSCODE_EXTENSIONS:-0}" = "1" ] && install_extensions
    exit 0
fi

# ---- macOS -----------------------------------------------------------------
if is_mac; then
    if brew list --cask visual-studio-code >/dev/null 2>&1; then
        info "VS Code cask already installed"
    else
        info "installing VS Code via brew (--cask visual-studio-code)"
        brew install --cask visual-studio-code || warn "VS Code cask install failed"
    fi
    link_mac_cli
    [ "${INSTALL_VSCODE_EXTENSIONS:-0}" = "1" ] && install_extensions
    info "VS Code ready."
    exit 0
fi

# ---- Linux -----------------------------------------------------------------
installed=0
case "$PKG" in
    apt)
        info "adding the Microsoft VS Code apt repo"
        need_cmd curl || pkg_install curl
        pkg_install gpg ca-certificates || true
        tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
        curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > "$tmp/microsoft.gpg"
        $SUDO install -D -m 0644 "$tmp/microsoft.gpg" /etc/apt/keyrings/microsoft.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/code stable main" \
            | $SUDO tee /etc/apt/sources.list.d/vscode.list >/dev/null
        pkg_refresh
        pkg_install code && installed=1 || true
        ;;
    dnf|zypper)
        info "adding the Microsoft VS Code rpm repo"
        $SUDO rpm --import https://packages.microsoft.com/keys/microsoft.asc || warn "rpm key import failed"
        printf '[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\nautorefresh=1\ntype=rpm-md\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc\n' \
            | $SUDO tee /etc/yum.repos.d/vscode.repo >/dev/null
        pkg_install code && installed=1 || true
        ;;
    pacman)
        # Official build lives in the AUR; fall back to the Code-OSS repo package.
        aur=""; for h in paru yay; do need_cmd "$h" && { aur="$h"; break; }; done
        if [ -n "$aur" ]; then
            info "installing visual-studio-code-bin from the AUR via $aur"
            "$aur" -S --needed --noconfirm visual-studio-code-bin && installed=1 || true
        fi
        if [ "$installed" != "1" ]; then
            info "installing Code - OSS from the official repo (open-source build)"
            pkg_install code && installed=1 || true
        fi
        ;;
esac

# ---- fallback: snap / flatpak ----------------------------------------------
if [ "$installed" != "1" ]; then
    if need_cmd snap; then
        info "installing VS Code via snap"
        $SUDO snap install code --classic && installed=1 || true
    elif need_cmd flatpak; then
        info "installing VS Code via flatpak"
        flatpak install -y flathub com.visualstudio.code && installed=1 || true
    fi
fi

if [ "$installed" = "1" ] && need_cmd code; then
    info "VS Code installed: $(code --version 2>/dev/null | head -1)"
    [ "${INSTALL_VSCODE_EXTENSIONS:-0}" = "1" ] && install_extensions
else
    err "VS Code install failed; grab it from https://code.visualstudio.com/download"
    exit 1
fi
