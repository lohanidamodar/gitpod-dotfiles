#!/usr/bin/env bash
# Shared helpers for the dotfiles scripts.
# Source this file, do not execute it:  . "$(dirname "$0")/common.sh"
#
# Provides:
#   $SUDO        -> "" when root, else "sudo"/"doas"   (fixes "sudo: command not found")
#   $PKG         -> pacman | apt | dnf | zypper | apk | unknown
#   $DISTRO_ID   -> arch, ubuntu, debian, fedora, ...  (from /etc/os-release)
#   is_wsl                 -> return 0 when running under WSL
#   need_cmd <cmd>         -> return 0 if command exists
#   info/warn/err <msg>    -> coloured logging
#   pkg_refresh            -> refresh package metadata
#   pkg_install <pkgs...>  -> install packages with the native manager

# ---- logging ---------------------------------------------------------------
info() { printf '\033[1;34m[info]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[warn]\033[0m %s\n' "$*" >&2; }
err()  { printf '\033[1;31m[err ]\033[0m %s\n' "$*" >&2; }

need_cmd() { command -v "$1" >/dev/null 2>&1; }

# ---- privilege escalation --------------------------------------------------
# The original scripts hard-coded `sudo`, which breaks on a fresh Arch install
# or a WSL distro that runs as root (no sudo package present). Here we only
# reach for an escalation tool when we are NOT already root.
if [ "$(id -u)" -eq 0 ]; then
    SUDO=""
elif need_cmd sudo; then
    SUDO="sudo"
elif need_cmd doas; then
    SUDO="doas"
else
    SUDO=""
    warn "Not running as root and neither sudo nor doas is installed."
    warn "Run scripts/create_sudo_user.sh (as root) first, or re-run this as root."
fi

# ---- distro / package manager detection ------------------------------------
DISTRO_ID="unknown"
if [ -r /etc/os-release ]; then
    # shellcheck disable=SC1091
    DISTRO_ID=$(. /etc/os-release && echo "${ID:-unknown}")
fi

if   need_cmd pacman; then PKG="pacman"
elif need_cmd apt-get; then PKG="apt"
elif need_cmd dnf;    then PKG="dnf"
elif need_cmd zypper; then PKG="zypper"
elif need_cmd apk;    then PKG="apk"
else PKG="unknown"
fi

is_wsl() {
    [ -n "${WSL_DISTRO_NAME:-}" ] || \
    [ -e /proc/sys/fs/binfmt_misc/WSLInterop ] || \
    grep -qiE 'microsoft|wsl' /proc/version 2>/dev/null
}

# ---- package helpers -------------------------------------------------------
pkg_refresh() {
    case "$PKG" in
        pacman) $SUDO pacman -Sy --noconfirm ;;
        apt)    $SUDO apt-get update -qq ;;
        dnf)    $SUDO dnf -y makecache ;;
        zypper) $SUDO zypper --non-interactive refresh ;;
        apk)    $SUDO apk update ;;
        *) warn "Unknown package manager; skipping metadata refresh." ;;
    esac
}

pkg_install() {
    case "$PKG" in
        pacman) $SUDO pacman -S --needed --noconfirm "$@" ;;
        apt)    $SUDO apt-get install -y "$@" ;;
        dnf)    $SUDO dnf install -y "$@" ;;
        zypper) $SUDO zypper --non-interactive install "$@" ;;
        apk)    $SUDO apk add "$@" ;;
        *) err "Unknown package manager; cannot install: $*"; return 1 ;;
    esac
}
