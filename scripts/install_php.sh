#!/usr/bin/env bash
# Install the latest stable PHP + common dev extensions, cross-distro.
#   Arch    : pacman php (currently tracks the newest stable, e.g. 8.5)
#   Ubuntu  : Ondrej PPA, then the highest available php8.x
#   Fedora  : distro php (recent) + extensions
# Override the Ubuntu version explicitly with PHP_VERSION=8.4 if you need to.
set -euo pipefail
DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
# shellcheck source=common.sh
. "$DIR/common.sh"

# Appwrite core runs on Swoole; enable it opt-in so a plain PHP install stays
# lean. INSTALL_SWOOLE=1 attempts the native package for the active manager.
: "${INSTALL_SWOOLE:=0}"

if need_cmd php && [ "$INSTALL_SWOOLE" != "1" ]; then
    info "php already installed: $(php -v | head -1)"
    exit 0
fi

# Extensions most PHP projects (and Composer) expect.
COMMON_EXTS="mbstring curl xml zip bcmath intl gd mysqli pdo_mysql pdo_pgsql pdo_sqlite sqlite3 gmp soap"

if ! need_cmd php; then
case "$PKG" in
    brew)   pkg_install php ;;   # brew php bundles the common extensions
    pacman)
        pkg_install php
        # Extensions that live in their own packages on Arch (best-effort).
        pkg_install php-gd php-sqlite php-pgsql || warn "some php-* extension packages skipped"
        # The rest ship as shared .so inside the php package but are OFF by
        # default in php.ini — enable the ones that actually exist via a
        # conf.d drop-in so mbstring/intl/etc. work out of the box.
        extdir="$(php -r 'echo ini_get("extension_dir");' 2>/dev/null || true)"
        if [ -n "$extdir" ] && [ -d "$extdir" ]; then
            conf="/etc/php/conf.d/99-dotfiles.ini"
            {
                echo "; extensions enabled by dotfiles scripts/install_php.sh"
                for e in $COMMON_EXTS iconv sodium xsl exif fileinfo openssl pdo phar; do
                    [ -f "$extdir/$e.so" ] && echo "extension=$e"
                done
            } | $SUDO tee "$conf" >/dev/null || warn "couldn't write $conf"
            info "enabled bundled php extensions in $conf"
        fi
        ;;
    apt)
        pkg_install software-properties-common ca-certificates
        if need_cmd add-apt-repository || need_cmd apt-add-repository; then
            info "adding Ondrej PHP PPA (latest stable releases)"
            $SUDO add-apt-repository -y ppa:ondrej/php || warn "couldn't add ondrej PPA; using distro php"
        fi
        pkg_refresh
        # Pick the newest php8.x the repos offer, unless PHP_VERSION is pinned.
        ver="${PHP_VERSION:-}"
        if [ -z "$ver" ]; then
            ver="$(apt-cache pkgnames 2>/dev/null | grep -oE '^php8\.[0-9]+' \
                    | sort -Vu | tail -1 | sed 's/php//')"
        fi
        [ -n "$ver" ] || ver="8.3"
        info "installing php ${ver} + extensions"
        pkgs="php${ver}-cli"
        for e in $COMMON_EXTS; do
            case "$e" in
                # apt names differ slightly from the ext id.
                pdo_mysql|mysqli) pkgs="$pkgs php${ver}-mysql" ;;
                pdo_pgsql)        pkgs="$pkgs php${ver}-pgsql" ;;
                pdo_sqlite|sqlite3) pkgs="$pkgs php${ver}-sqlite3" ;;
                *)                pkgs="$pkgs php${ver}-${e}" ;;
            esac
        done
        # de-dupe the package list
        pkgs="$(printf '%s\n' $pkgs | awk '!seen[$0]++' | tr '\n' ' ')"
        # shellcheck disable=SC2086
        pkg_install $pkgs || warn "some php extension packages were unavailable"
        $SUDO update-alternatives --set php "/usr/bin/php${ver}" 2>/dev/null || true
        ;;
    dnf)
        pkg_install php-cli php-mbstring php-xml php-gd php-mysqlnd php-pgsql \
                    php-intl php-bcmath php-zip php-gmp php-soap || warn "some php pkgs skipped"
        ;;
    zypper)
        pkg_install php8 php8-mbstring php8-curl php8-xml php8-zip php8-gd || pkg_install php
        ;;
    apk)
        pkg_install php php-cli php-mbstring php-curl php-xml php-openssl php-phar || true
        ;;
    *) err "Unsupported package manager for php install"; exit 1 ;;
esac
info "php installed: $(php -v | head -1)"
fi

# ---- Swoole (opt-in: INSTALL_SWOOLE=1) -------------------------------------
# Appwrite core is built on Swoole. Best-effort via the native package; if it's
# not packaged, fall back to PECL, and otherwise point at the usual Docker path.
if [ "${INSTALL_SWOOLE:-0}" = "1" ]; then
    if php -m 2>/dev/null | grep -qiE '^(swoole|openswoole)$'; then
        info "swoole already enabled in php"
    else
        info "=== enabling Swoole (Appwrite core) ==="
        swoole_ok=0
        case "$PKG" in
            brew)   pkg_install swoole && swoole_ok=1 || true ;;
            pacman) pkg_install php-swoole && swoole_ok=1 || true ;;   # AUR/extra where available
            apt)    ver="$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;' 2>/dev/null)"
                    pkg_install "php${ver}-swoole" && swoole_ok=1 || true ;;
            dnf)    pkg_install php-swoole && swoole_ok=1 || true ;;
            *)      : ;;
        esac
        if [ "$swoole_ok" != "1" ]; then
            warn "no Swoole package for $PKG; try:  pecl install swoole"
            warn "(Appwrite dev usually runs Swoole inside its Docker image, so native Swoole is optional)"
        else
            info "swoole installed"
        fi
    fi
fi
