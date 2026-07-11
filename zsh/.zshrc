# ~/.zshrc — portable version of the macOS setup, works on macOS and Linux.
# Managed by https://github.com/lohanidamodar/gitpod-dotfiles (setup.sh copies
# this over ~/.zshrc). Edit the repo copy, not this file, to keep changes.

# --- TERMINAL PERFORMANCE & LOCALE ---
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# --- HOMEBREW (Apple Silicon, Intel mac, or Linuxbrew) ---
# Load whichever brew exists so its bin/ and share/ are available below.
for _brew in /opt/homebrew /usr/local /home/linuxbrew/.linuxbrew "$HOME/.linuxbrew"; do
    if [ -x "$_brew/bin/brew" ]; then
        eval "$("$_brew/bin/brew" shellenv)"
        break
    fi
done
unset _brew

# --- FAST PLUGIN LOADERS (autosuggestions + syntax highlighting) ---
# Source a plugin from the first location that has it: brew's share dir on
# macOS/Linuxbrew, or the distro package paths on native Linux (Arch nests
# them under zsh/plugins; Debian/Fedora put them directly in /usr/share).
_zsh_source_plugin() {  # _zsh_source_plugin <subdir/file.zsh>
    local f
    for f in \
        "${HOMEBREW_PREFIX:-/usr}/share/$1" \
        "/usr/share/$1" \
        "/usr/share/zsh/plugins/$1" \
        "$HOME/.zsh/$1"; do
        [ -r "$f" ] && { source "$f"; return 0; }
    done
    return 1
}

# 1. Inline historical autosuggestions (like fish shell)
_zsh_source_plugin zsh-autosuggestions/zsh-autosuggestions.zsh
# 2. Real-time syntax highlighting (must be loaded last)
_zsh_source_plugin zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# 3. Blazing fast Rust-based prompt
command -v starship >/dev/null 2>&1 && eval "$(starship init zsh)"

# --- CMUX SIDEBAR NOTIFICATION UTILITY ---
cmux_notify() {
  printf '\e]777;notify;%s;%s\a' "$1" "$2"
}

# --- RESTORE AI AGENTS & VS CODE CLI PATHS + local dev bins ---
# 1. Standalone Claude Code / VS Code CLIs and other ~/.local/bin tools
export PATH="$HOME/.local/bin:$PATH"
# 2. Official-installer tool dirs (bun, cargo, flutter, dart) when present
for _dir in "$HOME/.bun/bin" "$HOME/.cargo/bin" "$HOME/flutter/bin" "$HOME/dart-sdk/bin"; do
    [ -d "$_dir" ] && case ":$PATH:" in *":$_dir:"*) ;; *) export PATH="$_dir:$PATH" ;; esac
done
unset _dir

# --- MODERN CLI TOOL INIT (installed by scripts/install_shell_utils.sh) ---
# Each is optional; the aliases below fall back to the classic tool when absent.
command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init zsh)"
if command -v fzf >/dev/null 2>&1; then
    # fzf >= 0.48 ships shell integration (key bindings + completion) this way.
    source <(fzf --zsh) 2>/dev/null
fi

# --- DEV TOOL HOOKS (mise version manager, direnv per-dir env) ---
command -v mise   >/dev/null 2>&1 && eval "$(mise activate zsh)"
command -v direnv >/dev/null 2>&1 && eval "$(direnv hook zsh)"

# --- ANDROID / FLUTTER SDK ---
# Point at the Android SDK from install_flutter_deps.sh (or Android Studio).
if [ -d "$HOME/Library/Android/sdk" ]; then
    export ANDROID_HOME="$HOME/Library/Android/sdk"     # macOS default
elif [ -d "$HOME/Android/Sdk" ]; then
    export ANDROID_HOME="$HOME/Android/Sdk"             # Linux default
fi
if [ -n "${ANDROID_HOME:-}" ]; then
    export ANDROID_SDK_ROOT="$ANDROID_HOME"
    for _d in "$ANDROID_HOME/cmdline-tools/latest/bin" "$ANDROID_HOME/platform-tools" "$ANDROID_HOME/emulator"; do
        [ -d "$_d" ] && case ":$PATH:" in *":$_d:"*) ;; *) export PATH="$PATH:$_d" ;; esac
    done
    unset _d
fi

# --- EDITOR ---
# Mirror the fish config's micro/kate preference, but only point at binaries
# that actually exist so a missing editor never becomes a broken $EDITOR.
for _ed in micro nano vim vi; do
    command -v "$_ed" >/dev/null 2>&1 && { export EDITOR="$_ed"; break; }
done
unset _ed
command -v kate >/dev/null 2>&1 && export VISUAL=kate

# --- ALIASES (ported from the fish config) ---
# ls family: prefer eza, then exa, else classic ls (GNU or BSD colour flag).
if command -v eza >/dev/null 2>&1; then
    alias ls='eza -al --color=always --group-directories-first'
    alias la='eza -a  --color=always --group-directories-first'
    alias ll='eza -l  --color=always --group-directories-first'
    alias lt='eza -aT --color=always --group-directories-first'
elif command -v exa >/dev/null 2>&1; then
    alias ls='exa -al --color=always --group-directories-first'
    alias la='exa -a  --color=always --group-directories-first'
    alias ll='exa -l  --color=always --group-directories-first'
    alias lt='exa -aT --color=always --group-directories-first'
elif ls --version >/dev/null 2>&1; then   # GNU coreutils
    alias ls='ls --color=auto'
    alias la='ls -A --color=auto'
    alias ll='ls -alh --color=auto'
    alias lt='ls -R --color=auto'
else                                       # BSD / macOS ls
    alias ls='ls -G'
    alias la='ls -AG'
    alias ll='ls -alhG'
    alias lt='ls -RG'
fi

# cat -> bat when present (aliases affect interactive shells only, not scripts).
command -v bat >/dev/null 2>&1 && alias cat='bat --paging=never'

alias tarnow='tar -acf '
alias untar='tar -zxvf '
alias wget='wget -c '
alias psmem='ps auxf | sort -nr -k 4'
alias psmem10='ps auxf | sort -nr -k 4 | head -10'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias ......='cd ../../../../..'
alias grep='grep --color=auto'
command -v dir  >/dev/null 2>&1 && alias dir='dir --color=auto'
command -v vdir >/dev/null 2>&1 && alias vdir='vdir --color=auto'

# Arch-only: refresh mirrors then full system upgrade.
command -v pacman >/dev/null 2>&1 && \
    alias upd='sudo reflector --latest 5 --age 2 --fastest 5 --protocol https --sort rate --save /etc/pacman.d/mirrorlist && sudo pacman -Syu'

# Git (git-delta, if installed, is wired up via ~/.gitconfig, not a shell alias).
alias gff='git flow feature'
alias gfr='git flow release'
alias gco='git checkout'
alias gcb='git checkout -b'
alias gl='git log --oneline --graph --decorate --all'

# Docker
alias dc="docker compose"
alias dce="docker compose exec"
alias dcea="docker compose exec appwrite"
alias dcfr="docker compose up -d --force-recreate"
alias dcl="docker compose logs -f"
alias dcb="docker compose build"
alias dcdl="docker compose down --rmi all --volumes --remove-orphans"
alias dclo="$HOME/.dotfiles/scripts/docker_login.sh"
alias aprf="$HOME/.dotfiles/scripts/redis_flushall.sh"

# Composer / Appwrite
alias cinst="composer install --ignore-platform-reqs"
alias cupdt="composer update --ignore-platform-reqs"
alias cfmt="composer format"
alias acinit="dclo && cinst && composer format && dc build appwrite && dc up -d && dc logs -f appwrite"

# --- FUNCTIONS (ported from the fish config) ---
backup() { cp -- "$1" "$1.bak"; }          # backup <file>  ->  <file>.bak
copy() {                                    # copy <src> <dst>  (directory-aware)
    if [ "$#" -eq 2 ] && [ -d "$1" ]; then
        command cp -r -- "${1%/}" "$2"
    else
        command cp -- "$@"
    fi
}
