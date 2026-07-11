#!/usr/bin/env bash
# Install a curated set of modern CLI replacements, cross-distro and macOS.
#
#   eza        modern ls        colours, tree view, git status
#   bat        modern cat       syntax highlighting + paging
#   fd         modern find      fast, sane defaults
#   ripgrep    modern grep      rg — fast recursive search
#   fzf        fuzzy finder     Ctrl-R history, Ctrl-T files
#   zoxide     modern cd        z — jump to "frecent" directories
#   git-delta  modern git diff  side-by-side, syntax-highlighted diffs
#   duf        modern df        readable disk-usage tables
#   btop       modern top       resource monitor
#   jq         JSON processor   slice/filter/transform JSON
#   tealdeer   tldr client      concise, example-first command help
#
# The zsh config (zsh/.zshrc) wires up aliases / init for these when present and
# always falls back to the classic tool when one is missing — so a partial
# install is never a broken shell. Run standalone or via INSTALL_SHELL_UTILS=1.
set -uo pipefail
DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
# shellcheck source=common.sh
. "$DIR/common.sh"

# eza has its own robust installer (native package + GitHub-release fallback);
# reuse it instead of duplicating the fallback logic here.
info "=== eza ==="
bash "$DIR/install_eza.sh" || warn "eza install had issues; continuing"

# Everything else: install by the package name the active manager uses. Most
# names are identical; the exceptions are Debian's fd-find and Alpine's delta.
# fields:   canonical  | brew      | pacman    | apt       | dnf       | zypper    | apk
UTILS=(
  "bat|bat|bat|bat|bat|bat|bat"
  "fd|fd|fd|fd-find|fd-find|fd|fd"
  "ripgrep|ripgrep|ripgrep|ripgrep|ripgrep|ripgrep|ripgrep"
  "fzf|fzf|fzf|fzf|fzf|fzf|fzf"
  "zoxide|zoxide|zoxide|zoxide|zoxide|zoxide|zoxide"
  "git-delta|git-delta|git-delta|git-delta|git-delta|git-delta|delta"
  "duf|duf|duf|duf|duf|duf|duf"
  "btop|btop|btop|btop|btop|btop|btop"
  "jq|jq|jq|jq|jq|jq|jq"
  "tealdeer|tealdeer|tealdeer|tealdeer|tealdeer|tealdeer|tealdeer"
)

# Which pipe-delimited column holds the package name for this manager?
case "$PKG" in
  brew)   col=2 ;;
  pacman) col=3 ;;
  apt)    col=4 ;;
  dnf)    col=5 ;;
  zypper) col=6 ;;
  apk)    col=7 ;;
  *)      err "Unsupported package manager: $PKG"; exit 1 ;;
esac

pkg_refresh || true
failed=()
for spec in "${UTILS[@]}"; do
    IFS='|' read -r name b pm ap dn zy ak <<<"$spec"
    cols=("" "$name" "$b" "$pm" "$ap" "$dn" "$zy" "$ak")
    pkgname="${cols[$col]}"
    [ "$pkgname" = "-" ] && { warn "$name: no package for $PKG; skipping"; continue; }
    info "installing $name ($pkgname)"
    pkg_install "$pkgname" || failed+=("$name")
done

# Debian/Ubuntu ship bat as `batcat` and fd as `fdfind` (name clashes with other
# packages). Expose the expected names via ~/.local/bin so aliases + habits work.
mkdir -p "$HOME/.local/bin"
if ! need_cmd bat && need_cmd batcat; then
    ln -sf "$(command -v batcat)" "$HOME/.local/bin/bat"; info "linked bat -> batcat"
fi
if ! need_cmd fd && need_cmd fdfind; then
    ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"; info "linked fd -> fdfind"
fi

# Seed the tealdeer cache so `tldr <cmd>` works right away.
need_cmd tldr && { tldr --update >/dev/null 2>&1 || true; }

if [ "${#failed[@]}" -gt 0 ]; then
    warn "not available via $PKG, skipped: ${failed[*]}"
    warn "(the shell still works — each has a classic fallback)"
fi
info "shell utils done. Open a new shell to pick up their aliases/init."
