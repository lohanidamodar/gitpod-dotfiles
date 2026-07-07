#!/usr/bin/env bash
# Dotfiles setup — works on Arch, Debian/Ubuntu, Fedora, and under WSL.
#
# If you are on a fresh Arch/WSL box that is still root-only, create a
# non-root sudo user FIRST, then run this as that user:
#     bash scripts/create_sudo_user.sh <username>   # run as root (no sudo yet)
#
# Toggle optional installs with env vars, e.g.:
#     INSTALL_FLUTTER=1 INSTALL_DART=1 bash setup.sh
#     INSTALL_DOCKER=0 bash setup.sh
set -uo pipefail

DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
# shellcheck source=scripts/common.sh
. "$DIR/scripts/common.sh"

# ---- what to install (defaults) --------------------------------------------
: "${INSTALL_SSH:=1}"
: "${INSTALL_DOCKER:=1}"
: "${INSTALL_FISH:=1}"
: "${SET_FISH_DEFAULT:=1}"
: "${INSTALL_NODE:=1}"
: "${INSTALL_BUN:=1}"
: "${INSTALL_GH:=1}"
: "${INSTALL_DOCTL:=1}"
: "${INSTALL_CLAUDE:=1}"
: "${INSTALL_CODEX:=1}"
: "${INSTALL_ANTIGRAVITY:=1}"
: "${INSTALL_FLUTTER:=0}"   # heavy — opt in
: "${INSTALL_DART:=0}"      # opt in (Flutter already bundles Dart)

info "distro=$DISTRO_ID  pkg=$PKG  sudo='${SUDO:-<root>}'  wsl=$(is_wsl && echo yes || echo no)"

# ---- base tooling ----------------------------------------------------------
info "installing base tooling (git, curl, unzip)"
pkg_refresh || true
pkg_install git curl unzip || warn "base tooling install had issues; continuing"

# ---- shell config ----------------------------------------------------------
info "copying .bashrc and .bash_profile"
cp "$DIR/.bashrc" "$HOME/.bashrc"
cp "$DIR/.bash_profile" "$HOME/.bash_profile"

run() {  # run <flag-value> <label> <script...>
    local flag="$1" label="$2"; shift 2
    if [ "$flag" = "1" ]; then
        info "=== $label ==="
        bash "$@" || warn "$label failed; continuing"
    else
        info "skipping $label (disabled)"
    fi
}

# ---- ssh client ------------------------------------------------------------
run "$INSTALL_SSH" "ssh client" "$DIR/scripts/install_ssh.sh"

# ---- docker ----------------------------------------------------------------
run "$INSTALL_DOCKER" "docker" "$DIR/scripts/install_docker.sh"

# ---- exa: intentionally skipped (dropped from these dotfiles) --------------

# ---- fish + config ---------------------------------------------------------
run "$INSTALL_FISH" "fish shell" "$DIR/scripts/install_fish3.sh"

info "installing fish config"
mkdir -p "$HOME/.config/fish"
cp -r "$DIR"/fish/* "$HOME/.config/fish/"

if [ "$SET_FISH_DEFAULT" = "1" ] && need_cmd fish; then
    fish_path="$(command -v fish)"
    grep -q "$fish_path" /etc/shells 2>/dev/null || echo "$fish_path" | $SUDO tee -a /etc/shells >/dev/null
    if [ "${SHELL:-}" != "$fish_path" ]; then
        info "setting fish ($fish_path) as default shell"
        $SUDO chsh -s "$fish_path" "$USER" || chsh -s "$fish_path" || warn "chsh failed; change your shell manually"
    fi
fi

# ---- dev CLIs --------------------------------------------------------------
run "$INSTALL_NODE"        "node + npm"        "$DIR/scripts/install_node.sh"
run "$INSTALL_BUN"         "bun"               "$DIR/scripts/install_bun.sh"
run "$INSTALL_GH"          "github cli"        "$DIR/scripts/install_gh.sh"
run "$INSTALL_DOCTL"       "digitalocean cli"  "$DIR/scripts/install_doctl.sh"
run "$INSTALL_CLAUDE"      "claude cli"        "$DIR/scripts/install_claude_cli.sh"
run "$INSTALL_CODEX"       "codex cli"         "$DIR/scripts/install_codex_cli.sh"
run "$INSTALL_ANTIGRAVITY" "antigravity cli"   "$DIR/scripts/install_antigravity_cli.sh"
run "$INSTALL_FLUTTER"     "flutter"           "$DIR/scripts/install_flutter.sh"
run "$INSTALL_DART"        "dart"              "$DIR/scripts/install_dart.sh"

echo
info "Done. Open a new shell (or run: exec fish) to pick up PATH and shell changes."

if is_wsl; then
    info "WSL SSH-agent sharing (pick ONE direction):"
    info "  keys in Windows, use from WSL:   bash $DIR/scripts/setup_wsl_ssh_agent.sh"
    info "  keys in WSL, use from Windows:    bash $DIR/scripts/wsl_ssh_agent_serve.sh"
fi
