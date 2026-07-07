#!/usr/bin/env bash
# WSL side of "Windows SSH uses the WSL ssh-agent".
#
# Runs ONE ssh-agent inside WSL on a fixed socket (~/.ssh/agent.sock), used by
# both your WSL shells and — via the companion Windows relay — by native Windows
# ssh.exe / git. Your private keys live only in WSL. Add them once with:
#     ssh-add ~/.ssh/id_ed25519
#
# After running this, run the Windows-side relay (see the path printed at the
# end): scripts/windows/wsl-ssh-agent-relay.ps1
#
# NOTE: this is the OPPOSITE of scripts/setup_wsl_ssh_agent.sh (which uses the
# Windows agent from WSL). Use one or the other, not both.
set -euo pipefail
DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
# shellcheck source=common.sh
. "$DIR/common.sh"

if ! is_wsl; then
    err "This only makes sense under WSL."
    exit 1
fi

need_cmd ssh   || pkg_install openssh || "$DIR/install_ssh.sh"
need_cmd socat || { info "installing socat (used by the Windows relay)"; pkg_install socat; }

mkdir -p "$HOME/.ssh"; chmod 700 "$HOME/.ssh"

# Warn if the other (opposite-direction) setup is wired up.
if [ -f "$HOME/.bashrc.d/50-wsl-ssh-agent.sh" ] || [ -f "$HOME/.config/fish/conf.d/wsl_ssh_agent.fish" ]; then
    warn "Found the Windows->WSL bridge (setup_wsl_ssh_agent.sh) hooks."
    warn "They conflict with this direction; remove them if you switch:"
    warn "  rm -f ~/.bashrc.d/50-wsl-ssh-agent.sh ~/.config/fish/conf.d/wsl_ssh_agent.fish"
fi

# --- agent launcher (idempotent) -------------------------------------------
bindir="$HOME/.local/bin"; mkdir -p "$bindir"
launcher="$bindir/wsl-ssh-agent-serve"
cat > "$launcher" <<'EOS'
#!/usr/bin/env sh
# Ensure a persistent ssh-agent is listening on ~/.ssh/agent.sock.
SOCK="$HOME/.ssh/agent.sock"
# ssh-add -l exit codes: 0 = has keys, 1 = agent up (no keys), 2 = no agent.
if ! SSH_AUTH_SOCK="$SOCK" ssh-add -l >/dev/null 2>&1; then
    if [ "$?" -eq 2 ] || [ ! -S "$SOCK" ]; then
        rm -f "$SOCK"
        ssh-agent -a "$SOCK" >/dev/null 2>&1 || true
    fi
fi
echo "$SOCK"
EOS
chmod +x "$launcher"
info "installed agent launcher $launcher"

# --- wire WSL shells to this agent -----------------------------------------
mkdir -p "$HOME/.bashrc.d"
cat > "$HOME/.bashrc.d/51-wsl-ssh-serve.sh" <<'EOS'
# Use the WSL-hosted ssh-agent (shared with Windows via the relay).
if [ -n "${WSL_DISTRO_NAME:-}" ] && [ -x "$HOME/.local/bin/wsl-ssh-agent-serve" ]; then
    "$HOME/.local/bin/wsl-ssh-agent-serve" >/dev/null
    export SSH_AUTH_SOCK="$HOME/.ssh/agent.sock"
fi
EOS

if [ -d "$HOME/.config/fish" ]; then
    mkdir -p "$HOME/.config/fish/conf.d"
    cat > "$HOME/.config/fish/conf.d/wsl_ssh_serve.fish" <<'EOS'
# Use the WSL-hosted ssh-agent (shared with Windows via the relay).
if set -q WSL_DISTRO_NAME; and test -x "$HOME/.local/bin/wsl-ssh-agent-serve"
    "$HOME/.local/bin/wsl-ssh-agent-serve" >/dev/null
    set -gx SSH_AUTH_SOCK "$HOME/.ssh/agent.sock"
end
EOS
fi

# --- start it now -----------------------------------------------------------
"$launcher" >/dev/null
export SSH_AUTH_SOCK="$HOME/.ssh/agent.sock"

echo
info "WSL ssh-agent is up at $SSH_AUTH_SOCK"
if ssh-add -l >/dev/null 2>&1; then
    info "loaded keys:"; ssh-add -l
else
    warn "no keys loaded yet — add one with:  ssh-add ~/.ssh/id_ed25519"
fi

win_path="\\\\wsl\$\\${WSL_DISTRO_NAME}\\home\\${USER}\\.dotfiles\\scripts\\windows\\wsl-ssh-agent-relay.ps1"
cat <<EOF

Now set up the WINDOWS side so native Windows ssh.exe / git use this agent:

  1. Open Windows PowerShell as Administrator.
  2. Run the relay (it takes over the Windows agent pipe and forwards to WSL):
        powershell -ExecutionPolicy Bypass -File "$win_path" -StopWindowsAgent
     (adjust the path; the repo is at \\\\wsl\$\\${WSL_DISTRO_NAME}\\home\\${USER}\\.dotfiles)
  3. For Git for Windows, point it at the Windows OpenSSH client:
        git config --global core.sshCommand "C:/Windows/System32/OpenSSH/ssh.exe"

To auto-start the relay at logon, see the header of wsl-ssh-agent-relay.ps1.

Caveat: if WSL fully shuts down (all processes exit) the agent stops and you
must 'ssh-add' again. Keeping any WSL shell open avoids this.
EOF
