#!/usr/bin/env bash
# Install OpenAI Codex CLI. Prefers the official installer, falls back to npm.
# NOTE: the correct npm package is @openai/codex (the bare "codex" is unrelated).
set -euo pipefail
DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
# shellcheck source=common.sh
. "$DIR/common.sh"

if need_cmd codex; then
    info "codex already installed: $(codex --version 2>/dev/null | head -1)"
    exit 0
fi

need_cmd curl || pkg_install curl

info "installing Codex CLI from chatgpt.com/codex/install.sh"
if curl -fsSL https://chatgpt.com/codex/install.sh | sh; then
    info "Codex CLI installed (open a new shell, then run: codex)"
    exit 0
fi

warn "installer failed, falling back to npm (@openai/codex)"
if ! need_cmd npm; then
    info "npm missing, installing node first"
    "$DIR/install_node.sh"
fi
npm install -g @openai/codex
info "codex installed: $(codex --version 2>/dev/null | head -1)"
