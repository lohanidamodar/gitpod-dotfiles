#!/usr/bin/env bash
# Install tmux + TPM (tmux plugin manager) and drop in our Catppuccin config.
# Config lives at ~/.config/tmux/tmux.conf (needs tmux >= 3.1).
set -euo pipefail
DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
# shellcheck source=common.sh
. "$DIR/common.sh"

# ---- tmux itself -----------------------------------------------------------
if need_cmd tmux; then
    info "tmux already installed: $(tmux -V)"
else
    pkg_install tmux
    info "tmux installed: $(tmux -V)"
fi

# ---- config ----------------------------------------------------------------
info "installing tmux config to ~/.config/tmux/tmux.conf"
mkdir -p "$HOME/.config/tmux"
cp "$DIR/../tmux/tmux.conf" "$HOME/.config/tmux/tmux.conf"

# ---- TPM (plugin manager) --------------------------------------------------
TPM_DIR="$HOME/.tmux/plugins/tpm"
if [ -d "$TPM_DIR/.git" ]; then
    info "TPM already present; updating"
    git -C "$TPM_DIR" pull --ff-only --quiet || warn "TPM update failed; continuing"
else
    info "cloning TPM"
    git clone --depth 1 https://github.com/tmux-plugins/tpm "$TPM_DIR" \
        || warn "TPM clone failed; the theme still works, plugins won't install"
fi

# ---- install the plugins headlessly (only what's missing) ------------------
# TPM's installer reads the plugin list from the config we just copied. We only
# invoke it when a declared plugin dir is actually absent, so re-running setup
# is a no-op instead of re-cloning everything.
PLUGIN_PATH="$HOME/.tmux/plugins"
if [ -x "$TPM_DIR/bin/install_plugins" ]; then
    missing=0
    while read -r repo; do
        [ -d "$PLUGIN_PATH/${repo##*/}" ] || { missing=1; break; }
    done < <(grep -oE "@plugin '[^']+'" "$HOME/.config/tmux/tmux.conf" | sed -E "s/@plugin '([^']+)'/\1/")

    if [ "$missing" -eq 1 ]; then
        info "installing missing tmux plugins"
        TMUX_PLUGIN_MANAGER_PATH="$PLUGIN_PATH/" \
            "$TPM_DIR/bin/install_plugins" || warn "plugin install had issues; run prefix+I inside tmux"
    else
        info "tmux plugins already installed"
    fi
fi

info "tmux ready. Start it with: tmux   (prefix is Ctrl+Space)"
