#!/usr/bin/env bash
# Install direnv — per-directory environment via .envrc. mac + Linux.
# The zsh config hooks it in automatically (`eval "$(direnv hook zsh)"`).
set -euo pipefail
DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
# shellcheck source=common.sh
. "$DIR/common.sh"

if need_cmd direnv; then
    info "direnv already installed: $(direnv version 2>/dev/null)"
    exit 0
fi

# Packaged everywhere we support; fall back to the official installer (no sudo).
if pkg_install direnv; then
    info "direnv installed via $PKG"
else
    warn "direnv not in repos; using the official installer into ~/.local/bin"
    need_cmd curl || pkg_install curl
    mkdir -p "$HOME/.local/bin"
    export bin_path="$HOME/.local/bin"
    curl -fsSL https://direnv.net/install.sh | bash || warn "direnv install failed"
fi

info "direnv ready. New shells load it via the hook in ~/.zshrc."
echo "Allow a project's .envrc with: direnv allow"
