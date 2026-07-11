#!/usr/bin/env bash
# Install Ruby (+ bundler) cross-distro.
set -euo pipefail
DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
# shellcheck source=common.sh
. "$DIR/common.sh"

if need_cmd ruby; then
    info "ruby already installed: $(ruby --version)"
    exit 0
fi

case "$PKG" in
    brew)   pkg_install ruby ;;               # bundler handled below via gem
    pacman) pkg_install ruby ruby-bundler ;;
    apt)    pkg_install ruby-full ;;          # ruby-full pulls dev headers + bundler
    dnf)    pkg_install ruby ruby-devel rubygem-bundler ;;
    zypper) pkg_install ruby ruby-devel ;;
    apk)    pkg_install ruby ruby-bundler ;;
    *) err "Unsupported package manager for ruby install"; exit 1 ;;
esac

# Make sure bundler is present (some distros don't bundle it).
if ! need_cmd bundle && ! need_cmd bundler && need_cmd gem; then
    gem install bundler --no-document || warn "bundler install via gem failed"
fi

info "ruby installed: $(ruby --version)"
