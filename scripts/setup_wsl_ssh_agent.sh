#!/usr/bin/env bash
# Reuse your Windows SSH keys inside WSL WITHOUT copying private keys onto Linux.
#
# It bridges the Windows OpenSSH agent's named pipe (//./pipe/openssh-ssh-agent)
# into a unix socket in WSL via `socat` + `npiperelay.exe`, then points
# SSH_AUTH_SOCK at it. Keys stay in Windows; WSL just asks the Windows agent to
# sign. Works for `ssh`, `git`, `scp`, etc. from inside WSL.
#
# WINDOWS SIDE (do this once, in an *admin* PowerShell):
#     Set-Service ssh-agent -StartupType Automatic
#     Start-Service ssh-agent
#     ssh-add                        # add your key(s); ssh-add -l to verify
# (1Password/other agents that expose the same pipe work too.)
set -euo pipefail
DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
# shellcheck source=common.sh
. "$DIR/common.sh"

if ! is_wsl; then
    err "This only makes sense under WSL."
    exit 1
fi

# --- dependencies -----------------------------------------------------------
need_cmd socat || { info "installing socat"; pkg_install socat; }
need_cmd curl  || pkg_install curl
need_cmd unzip || pkg_install unzip

# --- npiperelay.exe ---------------------------------------------------------
# Runs on the Windows side but is invoked from WSL via binfmt interop, so we can
# keep it in the Linux home dir.
bindir="$HOME/.local/bin"
npiperelay="$bindir/npiperelay.exe"
mkdir -p "$bindir"

if [ ! -x "$npiperelay" ]; then
    case "$(uname -m)" in
        x86_64) want="windows_amd64" ;;
        i686|i386) want="windows_386" ;;
        *) want="windows_amd64" ;;   # WSL is x64 in practice
    esac
    info "fetching npiperelay ($want)"
    url=$(curl -fsSL https://api.github.com/repos/jstarks/npiperelay/releases/latest \
            | grep -Po '"browser_download_url":\s*"\K[^"]*'"$want"'[^"]*\.zip' | head -1)
    [ -n "$url" ] || { err "Could not find npiperelay $want asset"; exit 1; }
    tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
    curl -fsSL "$url" -o "$tmp/npiperelay.zip"
    unzip -o -q "$tmp/npiperelay.zip" npiperelay.exe -d "$bindir"
    chmod +x "$npiperelay"
    info "installed $npiperelay"
else
    info "npiperelay already present at $npiperelay"
fi

# --- the bridge launcher (idempotent; sourced by every shell) --------------
bridge="$bindir/wsl-ssh-agent-bridge"
cat > "$bridge" <<'EOS'
#!/usr/bin/env sh
# Ensure a socat listener is bridging the Windows OpenSSH agent into WSL.
# Idempotent: safe to call from every new shell.
SOCK="$HOME/.ssh/wsl-ssh-agent.sock"
NPIPERELAY="$HOME/.local/bin/npiperelay.exe"
[ -n "${WSL_DISTRO_NAME:-}" ] || exit 0
command -v socat >/dev/null 2>&1 || exit 0
[ -x "$NPIPERELAY" ] || exit 0
mkdir -p "$HOME/.ssh"; chmod 700 "$HOME/.ssh"
if ! ss -lx 2>/dev/null | grep -q "$SOCK"; then
    rm -f "$SOCK"
    setsid socat UNIX-LISTEN:"$SOCK,fork,mode=0600" \
        EXEC:"$NPIPERELAY -ei -s //./pipe/openssh-ssh-agent",nofork \
        >/dev/null 2>&1 &
fi
EOS
chmod +x "$bridge"
info "installed bridge launcher $bridge"

# --- wire into bash + fish --------------------------------------------------
mkdir -p "$HOME/.bashrc.d"
cat > "$HOME/.bashrc.d/50-wsl-ssh-agent.sh" <<'EOS'
# Point SSH at the bridged Windows agent (see scripts/setup_wsl_ssh_agent.sh).
if [ -n "${WSL_DISTRO_NAME:-}" ] && [ -x "$HOME/.local/bin/wsl-ssh-agent-bridge" ]; then
    "$HOME/.local/bin/wsl-ssh-agent-bridge"
    export SSH_AUTH_SOCK="$HOME/.ssh/wsl-ssh-agent.sock"
fi
EOS

if [ -d "$HOME/.config/fish" ]; then
    mkdir -p "$HOME/.config/fish/conf.d"
    cat > "$HOME/.config/fish/conf.d/wsl_ssh_agent.fish" <<'EOS'
# Point SSH at the bridged Windows agent (see scripts/setup_wsl_ssh_agent.sh).
if set -q WSL_DISTRO_NAME; and test -x "$HOME/.local/bin/wsl-ssh-agent-bridge"
    "$HOME/.local/bin/wsl-ssh-agent-bridge"
    set -gx SSH_AUTH_SOCK "$HOME/.ssh/wsl-ssh-agent.sock"
end
EOS
fi

# --- start it now and verify ------------------------------------------------
"$bridge"
export SSH_AUTH_SOCK="$HOME/.ssh/wsl-ssh-agent.sock"

echo
info "Bridge set up. Testing against the Windows agent..."
if ssh-add -l >/dev/null 2>&1; then
    info "keys visible from the Windows agent:"
    ssh-add -l
    echo
    info "Open a new shell and 'git clone git@github.com:...' / 'ssh host' will use them."
else
    warn "No keys reported yet. On Windows (admin PowerShell) run:"
    warn "    Set-Service ssh-agent -StartupType Automatic; Start-Service ssh-agent; ssh-add"
    warn "then open a NEW WSL shell and run: ssh-add -l"
fi
