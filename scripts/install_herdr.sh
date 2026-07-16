#!/usr/bin/env bash
# Install herdr — a Rust, AI-agent-aware terminal multiplexer (a tmux alternative
# that detects the agents running in each pane and shows their state in a
# sidebar). https://github.com/ogulcancelik/herdr
# Also deploys this repo's config to ~/.config/herdr/config.toml.
set -euo pipefail
DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
# shellcheck source=common.sh
. "$DIR/common.sh"

install_config() {
    info "installing herdr config to ~/.config/herdr/config.toml"
    mkdir -p "$HOME/.config/herdr"
    cp "$DIR/../herdr/config.toml" "$HOME/.config/herdr/config.toml"
    # Validate it parses (and, if a server is running, hot-reload it).
    if need_cmd herdr; then
        herdr config check 2>&1 | grep -qi 'ok' && info "herdr config: ok" \
            || warn "herdr config check reported issues (run: herdr config check)"
        herdr server reload-config >/dev/null 2>&1 || true
    fi
}

if need_cmd herdr; then
    info "herdr already installed: $(herdr --version 2>/dev/null | head -1)"
    install_config
    exit 0
fi

# macOS: Homebrew formula.
if is_mac; then
    if pkg_install herdr; then
        info "herdr installed via brew"
        install_config
        exit 0
    fi
    warn "brew herdr failed; falling back to the official installer"
fi

# Cross-platform: the official installer (drops the binary on PATH).
need_cmd curl || pkg_install curl
info "installing herdr via https://herdr.dev/install.sh"
if curl -fsSL https://herdr.dev/install.sh | sh; then
    install_config
    info "herdr installed. Start it by running: herdr   (prefix is Ctrl+Space)"
else
    err "herdr install failed; grab a binary from https://github.com/ogulcancelik/herdr/releases"
    exit 1
fi
