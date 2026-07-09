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

# ---- install the plugins headlessly ----------------------------------------
# TPM's installer reads the plugin list from the config we just copied.
if [ -x "$TPM_DIR/bin/install_plugins" ]; then
    info "installing tmux plugins"
    TMUX_PLUGIN_MANAGER_PATH="$HOME/.tmux/plugins/" \
        "$TPM_DIR/bin/install_plugins" || warn "plugin install had issues; run prefix+I inside tmux"
fi

info "tmux ready. Start it with: tmux   (prefix is Ctrl+Space)"
