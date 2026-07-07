#!/usr/bin/env bash
# Install the OpenSSH client (ssh, scp, ssh-keygen, ssh-agent), cross-distro.
set -euo pipefail
DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
# shellcheck source=common.sh
. "$DIR/common.sh"

if need_cmd ssh; then
    info "ssh already installed: $(ssh -V 2>&1)"
    exit 0
fi

case "$PKG" in
    pacman) pkg_install openssh ;;              # client + sshd + agent
    apt)    pkg_install openssh-client ;;
    dnf)    pkg_install openssh-clients ;;
    zypper) pkg_install openssh-clients ;;
    apk)    pkg_install openssh-client ;;
    *) err "Unsupported package manager for ssh install"; exit 1 ;;
esac

# ~/.ssh with correct perms so ssh doesn't complain later.
mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

info "ssh installed: $(ssh -V 2>&1)"
echo "Generate a key with:  ssh-keygen -t ed25519 -C \"$USER@$(uname -n)\""
