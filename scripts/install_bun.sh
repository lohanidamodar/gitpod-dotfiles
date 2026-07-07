#!/usr/bin/env bash
# Install Bun via the official installer (distro-agnostic).
set -euo pipefail
DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
# shellcheck source=common.sh
. "$DIR/common.sh"

if need_cmd bun; then
    info "bun $(bun --version) already installed"
    exit 0
fi

need_cmd unzip || pkg_install unzip
need_cmd curl  || pkg_install curl

info "installing bun from bun.sh"
curl -fsSL https://bun.sh/install | bash

# The installer appends PATH lines to ~/.bashrc; make sure fish picks it up too.
BUN_FISH="$HOME/.config/fish/conf.d/bun.fish"
if [ -d "$HOME/.config/fish" ] && [ ! -f "$BUN_FISH" ]; then
    mkdir -p "$HOME/.config/fish/conf.d"
    {
        echo 'set -gx BUN_INSTALL "$HOME/.bun"'
        echo 'fish_add_path "$BUN_INSTALL/bin"'
    } > "$BUN_FISH"
    info "wrote $BUN_FISH"
fi

info "bun installed to ~/.bun/bin (open a new shell or: export PATH=\"\$HOME/.bun/bin:\$PATH\")"
