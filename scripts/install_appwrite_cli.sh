#!/usr/bin/env bash
# Install the Appwrite CLI — manage projects, deploy functions, push/pull config.
# Prefers npm (cross-platform, matches the Node this repo installs); falls back
# to the official standalone installer.
set -euo pipefail
DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
# shellcheck source=common.sh
. "$DIR/common.sh"

if need_cmd appwrite; then
    info "appwrite cli already installed: $(appwrite -v 2>/dev/null | head -1)"
    exit 0
fi

if need_cmd npm; then
    info "installing appwrite-cli via npm"
    npm install -g appwrite-cli && { info "appwrite cli installed: $(appwrite -v 2>/dev/null | head -1)"; exit 0; } \
        || warn "npm install failed; falling back to the official installer"
fi

# Fallback: official installer (drops a standalone binary, may use sudo for
# /usr/local/bin). Requires the node runtime to be present.
need_cmd curl || pkg_install curl
info "installing appwrite cli via appwrite.io/cli/install.sh"
curl -fsSL https://appwrite.io/cli/install.sh | bash || { err "appwrite cli install failed"; exit 1; }

info "appwrite cli ready. Log in / point at your instance with: appwrite login"
