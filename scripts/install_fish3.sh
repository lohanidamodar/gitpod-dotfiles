#!/usr/bin/env bash
# Install the fish shell, cross-distro.
# (On Ubuntu the repo fish can be old, so we add the fish-shell PPA there.)
set -euo pipefail
DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
# shellcheck source=common.sh
. "$DIR/common.sh"

if need_cmd fish; then
    info "fish already installed: $(fish --version)"
    exit 0
fi

case "$PKG" in
    apt)
        if need_cmd add-apt-repository || need_cmd apt-add-repository; then
            $SUDO apt-add-repository -y ppa:fish-shell/release-3 || true
        fi
        pkg_refresh
        pkg_install fish
        ;;
    *)
        pkg_install fish
        ;;
esac

info "fish installed: $(fish --version)"
