#!/usr/bin/env bash
# Create a non-root user with passwordless-optional sudo, primarily for Arch,
# and wire it up as the default WSL user when running under WSL.
#
# Run this AS ROOT (it's the thing you do right after a fresh Arch/WSL install,
# before sudo even exists):
#     bash create_sudo_user.sh <username>
#
# It installs sudo if missing, creates the user in the admin group, grants sudo,
# and (under WSL) sets it as the default login user via /etc/wsl.conf.
set -euo pipefail
DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
# shellcheck source=common.sh
. "$DIR/common.sh"

if [ "$(id -u)" -ne 0 ]; then
    err "This script must be run as root."
    err "  On WSL:  wsl -d <distro> -u root   (or just log in as root once)"
    exit 1
fi

# --- username ---------------------------------------------------------------
user="${1:-}"
if [ -z "$user" ]; then
    printf 'New username: '
    read -r user
fi
[ -n "$user" ] || { err "No username given."; exit 1; }

# admin group differs by distro
case "$DISTRO_ID" in
    debian|ubuntu) admin_group="sudo" ;;
    *)             admin_group="wheel" ;;   # arch, fedora, opensuse, ...
esac

# --- ensure sudo is installed ----------------------------------------------
if ! need_cmd sudo; then
    info "sudo not found — installing it"
    pkg_refresh
    pkg_install sudo
fi

# --- ensure admin group exists ----------------------------------------------
getent group "$admin_group" >/dev/null 2>&1 || groupadd "$admin_group"

# --- create (or update) the user -------------------------------------------
login_shell=/bin/bash
[ -x /usr/bin/fish ] && login_shell=/usr/bin/fish  # use fish if already present

if id "$user" >/dev/null 2>&1; then
    info "user '$user' already exists — adding to $admin_group"
    usermod -aG "$admin_group" "$user"
else
    info "creating user '$user'"
    useradd -m -G "$admin_group" -s "$login_shell" "$user"
    info "set a password for '$user':"
    passwd "$user"
fi

# --- grant sudo to the admin group ------------------------------------------
sudoers_file="/etc/sudoers.d/10-${admin_group}"
echo "%${admin_group} ALL=(ALL:ALL) ALL" > "$sudoers_file"
chmod 0440 "$sudoers_file"
info "granted sudo to %$admin_group ($sudoers_file)"

# Optional passwordless sudo — uncomment if you want it:
# echo "%${admin_group} ALL=(ALL:ALL) NOPASSWD: ALL" > "$sudoers_file"

# --- WSL: make this the default user ---------------------------------------
if is_wsl; then
    info "WSL detected — setting '$user' as the default user in /etc/wsl.conf"
    if [ -f /etc/wsl.conf ] && grep -q '^\[user\]' /etc/wsl.conf; then
        # replace existing default= under [user]
        sed -i "s/^default=.*/default=$user/" /etc/wsl.conf
    else
        printf '\n[user]\ndefault=%s\n' "$user" >> /etc/wsl.conf
    fi
    cat <<EOF

[ok] Done. To apply the default user, from Windows PowerShell run:
       wsl --shutdown
     then reopen the distro — you'll land as '$user'.
EOF
else
    cat <<EOF

[ok] Done. Log in as '$user' (e.g. 'su - $user') and re-run setup.sh from there.
EOF
fi
