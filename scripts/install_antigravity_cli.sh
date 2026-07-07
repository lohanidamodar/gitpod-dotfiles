#!/usr/bin/env bash
# Install Google Antigravity CLI via the official installer (distro-agnostic).
# Installs the `agy` binary under ~/.local/bin.
set -euo pipefail
DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
# shellcheck source=common.sh
. "$DIR/common.sh"

if need_cmd agy; then
    info "antigravity (agy) already installed: $(agy --version 2>/dev/null | head -1)"
    exit 0
fi

need_cmd curl || pkg_install curl

info "installing Antigravity CLI from antigravity.google/cli/install.sh"
curl -fsSL https://antigravity.google/cli/install.sh | bash

info "Antigravity CLI installed to ~/.local/bin (open a new shell, then run: agy)"
