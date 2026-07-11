#!/usr/bin/env bash
# Dotfiles setup — works on macOS, Arch, Debian/Ubuntu, Fedora, and under WSL.
# macOS uses Homebrew (auto-installed if missing); Linux uses the native manager.
#
# If you are on a fresh Arch/WSL box that is still root-only, create a
# non-root sudo user FIRST, then run this as that user:
#     bash scripts/create_sudo_user.sh <username>   # run as root (no sudo yet)
#
# Every install is a toggle set via env var. Flip any default with VAR=0/1, e.g.:
#     INSTALL_CLAUDE=1 bash setup.sh                 # add the Claude CLI
#     INSTALL_CLAUDE=1 INSTALL_CODEX=1 bash setup.sh # add several
#     INSTALL_DOCKER=0 bash setup.sh                 # skip a default install
# The AI coding CLIs (claude/codex/antigravity) and the extra languages/tools
# are OPT-IN (default 0) so a plain `bash setup.sh` stays lean. See README.md
# for the full list of options and copy-paste commands.
set -uo pipefail

DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
# shellcheck source=scripts/common.sh
. "$DIR/scripts/common.sh"

# ---- CLI args --------------------------------------------------------------
INTERACTIVE="${INTERACTIVE:-0}"
for _arg in "$@"; do
    case "$_arg" in
        -i|--interactive) INTERACTIVE=1 ;;
        -h|--help)
            cat <<'USAGE'
Usage: bash setup.sh [-i|--interactive]
  -i, --interactive   Pick what to install from a menu (the default run is unchanged).
  Or toggle anything non-interactively with env vars, e.g.:
    INSTALL_DOCKER=0 INSTALL_KUBE=1 bash setup.sh
USAGE
            exit 0 ;;
        *) warn "unknown argument: $_arg (ignored)" ;;
    esac
done
unset _arg

# Ordered menu for interactive mode; "#" entries are section headers. Each other
# entry is "ENV_VAR|Label" and is toggled against the defaults set just below.
_MENU=(
    "#|Base — shell + dev (default ON)"
    "INSTALL_SSH|OpenSSH client"
    "INSTALL_DOCKER|Docker (Desktop on macOS)"
    "INSTALL_ZSH|zsh + config + starship"
    "SET_ZSH_DEFAULT|Make zsh the default shell"
    "INSTALL_GITCONFIG|git config (delta, aliases)"
    "INSTALL_TMUX|tmux + Catppuccin config"
    "INSTALL_NERD_FONT|Nerd Fonts"
    "INSTALL_NODE|Node.js + npm"
    "INSTALL_BUN|Bun"
    "INSTALL_GH|GitHub CLI"
    "INSTALL_DOCTL|DigitalOcean CLI"
    "INSTALL_FISH|fish shell + config"
    "#|AI coding CLIs"
    "INSTALL_CLAUDE|Claude Code CLI"
    "INSTALL_CODEX|OpenAI Codex CLI"
    "INSTALL_ANTIGRAVITY|Google Antigravity CLI"
    "#|Infra + platform dev"
    "INSTALL_KUBE|Kubernetes tools (kubectl/helm/k9s/kubectx/kubens/stern)"
    "INSTALL_APPWRITE_CLI|Appwrite CLI"
    "INSTALL_MISE|mise (runtime version manager)"
    "INSTALL_DIRENV|direnv (per-dir env)"
    "INSTALL_YQ|yq (YAML/JSON processor)"
    "#|Languages / mobile"
    "INSTALL_FLUTTER|Flutter SDK"
    "INSTALL_FLUTTER_DEPS|Flutter build deps (JDK/Android/Xcode/CocoaPods/fastlane)"
    "INSTALL_DART|Dart SDK"
    "INSTALL_PHP|PHP + extensions"
    "INSTALL_SWOOLE|Swoole for PHP (Appwrite core)"
    "INSTALL_COMPOSER|Composer"
    "INSTALL_RUBY|Ruby + bundler"
    "INSTALL_SWIFT|Swift"
    "#|Extra tools"
    "INSTALL_SHELL_UTILS|Modern CLI utils (eza/bat/fd/rg/fzf/zoxide/…)"
    "INSTALL_EZA|eza only"
    "INSTALL_OLLAMA|Ollama"
)

# Draw the menu, toggle selections by number, then apply. Reads /dev/tty so it
# works even under `curl … | bash`. Bash 3.2-safe (no associative arrays).
interactive_menu() {
    local tty=/dev/tty entry v label input token n idx cur mark
    local _vars=() _defs=()
    for entry in "${_MENU[@]}"; do
        v="${entry%%|*}"; [ "$v" = "#" ] && continue
        _vars+=("$v"); _defs+=("${!v}")           # snapshot defaults for 'd'
    done

    while :; do
        printf '\n\033[1mSelect what to install\033[0m — toggle by number, then Enter to run.\n'
        idx=0
        for entry in "${_MENU[@]}"; do
            v="${entry%%|*}"; label="${entry#*|}"
            if [ "$v" = "#" ]; then
                printf '\n  \033[1;34m%s\033[0m\n' "$label"
            else
                idx=$((idx+1)); cur="${!v}"
                if [ "$cur" = "1" ]; then mark='\033[1;32mx\033[0m'; else mark=' '; fi
                printf '   %2d) [%b] %s\n' "$idx" "$mark" "$label"
            fi
        done
        printf '\n  numbers=toggle   a=all on   n=all off   d=defaults   Enter=run   q=quit\n> '
        IFS= read -r input <"$tty" || input=""
        case "$input" in
            "")  break ;;
            q|Q) info "aborted; nothing installed"; exit 0 ;;
            a|A) for v in "${_vars[@]}"; do printf -v "$v" '%s' 1; done ;;
            n|N) for v in "${_vars[@]}"; do printf -v "$v" '%s' 0; done ;;
            d|D) idx=0; for v in "${_vars[@]}"; do printf -v "$v" '%s' "${_defs[$idx]}"; idx=$((idx+1)); done ;;
            *)
                for token in $input; do
                    case "$token" in *[!0-9]*|"") continue ;; esac
                    n=$((token-1))
                    { [ "$n" -ge 0 ] && [ "$n" -lt "${#_vars[@]}" ]; } || continue
                    v="${_vars[$n]}"; cur="${!v}"
                    if [ "$cur" = "1" ]; then printf -v "$v" '%s' 0; else printf -v "$v" '%s' 1; fi
                done ;;
        esac
    done

    local chosen=""
    for v in "${_vars[@]}"; do [ "${!v}" = "1" ] && chosen="$chosen ${v#INSTALL_}"; done
    info "installing:${chosen:- (nothing selected)}"
}

# ---- what to install -------------------------------------------------------
# Default ON: the base shell + dev environment.
: "${INSTALL_SSH:=1}"
: "${INSTALL_DOCKER:=1}"
: "${INSTALL_ZSH:=1}"
: "${SET_ZSH_DEFAULT:=1}"
: "${INSTALL_FISH:=0}"       # fish is now opt-in; zsh is the default shell
: "${INSTALL_GITCONFIG:=1}"  # deploy ~/.gitconfig (identity kept in ~/.gitconfig.local)
: "${INSTALL_TMUX:=1}"
: "${INSTALL_NERD_FONT:=1}"
: "${INSTALL_NODE:=1}"
: "${INSTALL_BUN:=1}"
: "${INSTALL_GH:=1}"
: "${INSTALL_DOCTL:=1}"

# Opt-in (default 0): AI coding CLIs. Enable with INSTALL_CLAUDE=1 etc.
: "${INSTALL_CLAUDE:=0}"
: "${INSTALL_CODEX:=0}"
: "${INSTALL_ANTIGRAVITY:=0}"

# Opt-in (default 0): extra languages / tools.
: "${INSTALL_FLUTTER:=0}"      # heavy
: "${INSTALL_FLUTTER_DEPS:=0}" # JDK + Android Studio/SDK + Xcode CLT + CocoaPods + fastlane
: "${INSTALL_DART:=0}"         # (Flutter already bundles Dart)
: "${INSTALL_PHP:=0}"          # latest stable PHP + common extensions
: "${INSTALL_SWOOLE:=0}"       # add Swoole to PHP (Appwrite core); read by install_php.sh
: "${INSTALL_COMPOSER:=0}"     # implies PHP
: "${INSTALL_RUBY:=0}"
: "${INSTALL_SWIFT:=0}"
: "${INSTALL_SHELL_UTILS:=0}"  # modern CLI bundle: eza/bat/fd/rg/fzf/zoxide/...
: "${INSTALL_EZA:=0}"          # just eza on its own (subset of shell utils)
: "${INSTALL_OLLAMA:=0}"

# Opt-in (default 0): infra + platform-dev tooling.
: "${INSTALL_KUBE:=0}"         # kubectl, helm, k9s, kubectx, kubens, stern
: "${INSTALL_APPWRITE_CLI:=0}" # appwrite CLI (deploy functions, manage projects)
: "${INSTALL_MISE:=0}"         # polyglot runtime version manager (node/flutter/php/…)
: "${INSTALL_DIRENV:=0}"       # per-directory env via .envrc
: "${INSTALL_YQ:=0}"           # YAML/JSON processor (compose + k8s manifests)

# INSTALL_SWOOLE / PHP_VERSION are consumed by the child install_php.sh process,
# so export them (env-passed vars already are; interactive picks need this too).
export INSTALL_SWOOLE
[ -n "${PHP_VERSION:-}" ] && export PHP_VERSION

# Interactive picker (opt-in via -i / --interactive); default run is unchanged.
if [ "$INTERACTIVE" = "1" ]; then
    if { true >/dev/tty; } 2>/dev/null; then
        interactive_menu
    else
        warn "interactive mode requested but no terminal (/dev/tty) available; using defaults/env"
    fi
fi

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

# ---- zsh + config (default login shell) ------------------------------------
run "$INSTALL_ZSH" "zsh shell" "$DIR/scripts/install_zsh.sh"

info "installing zsh config to ~/.zshrc"
cp "$DIR/zsh/.zshrc" "$HOME/.zshrc"

info "installing starship config to ~/.config/starship.toml"
mkdir -p "$HOME/.config"
cp "$DIR/starship/starship.toml" "$HOME/.config/starship.toml"

# ---- fish + config (opt-in) ------------------------------------------------
run "$INSTALL_FISH" "fish shell" "$DIR/scripts/install_fish3.sh"

if [ "$INSTALL_FISH" = "1" ]; then
    info "installing fish config"
    mkdir -p "$HOME/.config/fish"
    # Copy everything EXCEPT fish_variables: that file holds per-machine universal
    # state (including a captured $PATH) and deploying it clobbers the local shell's
    # PATH — which previously hid the WSL-native `claude` behind Windows' claude.exe.
    find "$DIR/fish" -mindepth 1 -maxdepth 1 ! -name fish_variables \
        -exec cp -r {} "$HOME/.config/fish/" \;
fi

# ---- make zsh the default login shell --------------------------------------
if [ "$SET_ZSH_DEFAULT" = "1" ] && need_cmd zsh; then
    zsh_path="$(command -v zsh)"
    case "${SHELL:-}" in
        */zsh) info "default shell already zsh (${SHELL})" ;;
        *)
            grep -qx "$zsh_path" /etc/shells 2>/dev/null \
                || echo "$zsh_path" | $SUDO tee -a /etc/shells >/dev/null
            info "setting zsh ($zsh_path) as default shell"
            $SUDO chsh -s "$zsh_path" "$USER" || chsh -s "$zsh_path" \
                || warn "chsh failed; change your shell manually"
            ;;
    esac
fi

# ---- git config ------------------------------------------------------------
# Deploy the shared ~/.gitconfig, but keep personal identity in the untracked
# ~/.gitconfig.local so this (public) config never clobbers your name/email.
if [ "$INSTALL_GITCONFIG" = "1" ]; then
    info "installing git config to ~/.gitconfig (identity -> ~/.gitconfig.local)"
    _gn="$(git config --global user.name 2>/dev/null || true)"
    _ge="$(git config --global user.email 2>/dev/null || true)"
    cp "$DIR/git/.gitconfig" "$HOME/.gitconfig"
    if [ ! -f "$HOME/.gitconfig.local" ]; then
        {
            echo "# Personal git identity — untracked, not part of the dotfiles repo."
            echo "[user]"
            echo "    name = ${_gn}"
            echo "    email = ${_ge}"
        } > "$HOME/.gitconfig.local"
        info "wrote ~/.gitconfig.local${_gn:+ (identity: $_gn <$_ge>)}"
    fi
    if [ -z "$_gn" ] || [ -z "$_ge" ]; then
        warn "git identity incomplete; set it with:"
        warn "  git config --file ~/.gitconfig.local user.name  \"Your Name\""
        warn "  git config --file ~/.gitconfig.local user.email \"you@example.com\""
    fi
    unset _gn _ge
fi

# ---- terminal multiplexer + fonts ------------------------------------------
run "$INSTALL_NERD_FONT" "nerd fonts"  "$DIR/scripts/install_nerd_font.sh"
run "$INSTALL_TMUX"      "tmux"        "$DIR/scripts/install_tmux.sh"

# ---- dev CLIs (default on) -------------------------------------------------
run "$INSTALL_NODE"        "node + npm"        "$DIR/scripts/install_node.sh"
run "$INSTALL_BUN"         "bun"               "$DIR/scripts/install_bun.sh"
run "$INSTALL_GH"          "github cli"        "$DIR/scripts/install_gh.sh"
run "$INSTALL_DOCTL"       "digitalocean cli"  "$DIR/scripts/install_doctl.sh"

# ---- AI coding CLIs (opt-in: INSTALL_CLAUDE=1 etc.) ------------------------
run "$INSTALL_CLAUDE"      "claude cli"        "$DIR/scripts/install_claude_cli.sh"
run "$INSTALL_CODEX"       "codex cli"         "$DIR/scripts/install_codex_cli.sh"
run "$INSTALL_ANTIGRAVITY" "antigravity cli"   "$DIR/scripts/install_antigravity_cli.sh"

# ---- infra + platform-dev tooling (opt-in) ---------------------------------
run "$INSTALL_KUBE"         "kubernetes tools"   "$DIR/scripts/install_kube_tools.sh"
run "$INSTALL_APPWRITE_CLI" "appwrite cli"       "$DIR/scripts/install_appwrite_cli.sh"
run "$INSTALL_MISE"         "mise"               "$DIR/scripts/install_mise.sh"
run "$INSTALL_DIRENV"       "direnv"             "$DIR/scripts/install_direnv.sh"
run "$INSTALL_YQ"           "yq"                 "$DIR/scripts/install_yq.sh"

# ---- extra languages / tools (opt-in) --------------------------------------
run "$INSTALL_FLUTTER"      "flutter"            "$DIR/scripts/install_flutter.sh"
run "$INSTALL_FLUTTER_DEPS" "flutter build deps" "$DIR/scripts/install_flutter_deps.sh"
run "$INSTALL_DART"         "dart"               "$DIR/scripts/install_dart.sh"
run "$INSTALL_PHP"         "php"               "$DIR/scripts/install_php.sh"
run "$INSTALL_COMPOSER"    "composer"          "$DIR/scripts/install_composer.sh"
run "$INSTALL_RUBY"        "ruby"              "$DIR/scripts/install_ruby.sh"
run "$INSTALL_SWIFT"       "swift"             "$DIR/scripts/install_swift.sh"
run "$INSTALL_SHELL_UTILS" "shell utils"       "$DIR/scripts/install_shell_utils.sh"
run "$INSTALL_EZA"         "eza"               "$DIR/scripts/install_eza.sh"
run "$INSTALL_OLLAMA"      "ollama"            "$DIR/scripts/install_ollama_cli.sh"

echo
info "Done. Open a new shell (or run: exec zsh) to pick up PATH and shell changes."

if is_wsl; then
    info "WSL SSH-agent sharing (pick ONE direction):"
    info "  keys in Windows, use from WSL:   bash $DIR/scripts/setup_wsl_ssh_agent.sh"
    info "  keys in WSL, use from Windows:    bash $DIR/scripts/wsl_ssh_agent_serve.sh"
fi
