#!/usr/bin/env bash
# Install Vim if it isn't already present, cross-distro + macOS (Homebrew).
# The zsh config aliases `vi` -> `vim`, so both open Vim.
set -euo pipefail
DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
# shellcheck source=common.sh
. "$DIR/common.sh"

if need_cmd vim; then
    info "vim already installed: $(vim --version 2>/dev/null | head -1)"
    exit 0
fi

# `vim` is the package name on brew and every Linux manager we support.
pkg_install vim || { err "vim install failed"; exit 1; }
info "vim installed: $(vim --version 2>/dev/null | head -1)"
