#!/usr/bin/env bash
# Install mise (https://mise.jdx.dev) — polyglot runtime version manager.
# One tool to pin Node / Flutter / PHP / Bun / Java versions per project via a
# .mise.toml. mac + Linux. The zsh config activates it (`mise activate zsh`).
set -euo pipefail
DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
# shellcheck source=common.sh
. "$DIR/common.sh"

if need_cmd mise; then
    info "mise already installed: $(mise --version 2>/dev/null)"
    exit 0
fi

if is_mac; then
    pkg_install mise && { info "mise installed via brew"; exit 0; } || warn "brew mise failed; trying official installer"
fi

# Official installer drops the binary in ~/.local/bin (no sudo needed).
need_cmd curl || pkg_install curl
info "installing mise via https://mise.run"
curl -fsSL https://mise.run | sh || { err "mise install failed"; exit 1; }

info "mise ready. New shells activate it via the hook in ~/.zshrc."
cat <<'EOF'
Usage in a project:
  mise use node@lts       # pin Node for this dir
  mise use java@temurin-17 flutter@stable php@8.3
EOF
