#!/usr/bin/env bash
# Install Claude Code CLI via the official installer (distro-agnostic).
set -euo pipefail
DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
# shellcheck source=common.sh
. "$DIR/common.sh"

if need_cmd claude; then
    info "claude already installed: $(claude --version 2>/dev/null | head -1)"
    exit 0
fi

need_cmd curl || pkg_install curl

info "installing Claude Code from claude.ai/install.sh"
curl -fsSL https://claude.ai/install.sh | bash

info "Claude Code installed to ~/.local/bin (open a new shell, then run: claude)"
