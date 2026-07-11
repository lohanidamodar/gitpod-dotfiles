#!/usr/bin/env bash
# Flutter mobile build toolchain (beyond the Flutter SDK itself):
#   JDK 17 (Temurin/OpenJDK)  Android Gradle needs it
#   Android Studio            IDE + bundled emulator/AVD manager
#   Android SDK               cmdline-tools, platform-tools, platform, build-tools
#   Xcode Command Line Tools  macOS only (iOS/macOS builds)
#   CocoaPods                 macOS only (iOS/macOS plugin deps)
#   fastlane                  mobile build/release automation
#
# mac + Linux. Best-effort: each piece is non-fatal so a partial toolchain still
# lands. Env is wired into ~/.zshrc (ANDROID_HOME + SDK bins).
#
# Overridable: ANDROID_API=35  ANDROID_BUILD_TOOLS=35.0.0  CLT_VER=11076708
set -uo pipefail
DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
# shellcheck source=common.sh
. "$DIR/common.sh"

ANDROID_API="${ANDROID_API:-35}"
ANDROID_BUILD_TOOLS="${ANDROID_BUILD_TOOLS:-35.0.0}"
CLT_VER="${CLT_VER:-11076708}"   # Google cmdline-tools build; sdkmanager self-updates after

if is_mac; then
    ANDROID_HOME="${ANDROID_HOME:-$HOME/Library/Android/sdk}"
    CLT_OS="mac"
else
    ANDROID_HOME="${ANDROID_HOME:-$HOME/Android/Sdk}"
    CLT_OS="linux"
fi

# ---- 1. JDK 17 -------------------------------------------------------------
if need_cmd javac || [ -n "${JAVA_HOME:-}" ]; then
    info "a JDK is already present ($(javac -version 2>&1 || echo JAVA_HOME=$JAVA_HOME))"
else
    info "=== JDK 17 ==="
    if is_mac; then
        brew install --cask temurin@17 || brew install --cask temurin || warn "JDK install failed"
    else
        case "$PKG" in
            pacman) pkg_install jdk17-openjdk ;;
            apt)    pkg_install openjdk-17-jdk ;;
            dnf)    pkg_install java-17-openjdk-devel ;;
            zypper) pkg_install java-17-openjdk-devel ;;
            apk)    pkg_install openjdk17 ;;
            *) warn "no JDK package mapping for $PKG" ;;
        esac
    fi
fi

# ---- 2. Android Studio ------------------------------------------------------
info "=== Android Studio ==="
if is_mac; then
    brew install --cask android-studio || warn "Android Studio cask failed"
elif need_cmd snap; then
    $SUDO snap install android-studio --classic || warn "snap android-studio failed"
elif need_cmd flatpak; then
    flatpak install -y flathub com.google.AndroidStudio || warn "flatpak android-studio failed"
else
    warn "no snap/flatpak found; install Android Studio manually:"
    warn "  https://developer.android.com/studio"
fi

# ---- 3. Android SDK (cmdline-tools + platform-tools + platform + build-tools)
info "=== Android SDK -> $ANDROID_HOME ==="
need_cmd curl  || pkg_install curl
need_cmd unzip || pkg_install unzip
SDKMANAGER="$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager"

if [ ! -x "$SDKMANAGER" ]; then
    tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
    url="https://dl.google.com/android/repository/commandlinetools-${CLT_OS}-${CLT_VER}_latest.zip"
    info "downloading Android command-line tools (${CLT_OS} ${CLT_VER})"
    if curl -fsSL "$url" -o "$tmp/clt.zip" && unzip -q "$tmp/clt.zip" -d "$tmp"; then
        mkdir -p "$ANDROID_HOME/cmdline-tools"
        rm -rf "$ANDROID_HOME/cmdline-tools/latest"
        mv "$tmp/cmdline-tools" "$ANDROID_HOME/cmdline-tools/latest"
        info "cmdline-tools installed"
    else
        warn "cmdline-tools download failed; use Android Studio's SDK Manager instead"
    fi
fi

if [ -x "$SDKMANAGER" ]; then
    info "accepting licenses + installing platform-tools, platforms;android-${ANDROID_API}, build-tools;${ANDROID_BUILD_TOOLS}"
    yes | "$SDKMANAGER" --sdk_root="$ANDROID_HOME" --licenses >/dev/null 2>&1 || warn "license acceptance had issues"
    "$SDKMANAGER" --sdk_root="$ANDROID_HOME" \
        "platform-tools" "platforms;android-${ANDROID_API}" "build-tools;${ANDROID_BUILD_TOOLS}" \
        || warn "some SDK packages failed (check ANDROID_API / ANDROID_BUILD_TOOLS)"
    # Point Flutter at this SDK if Flutter is installed.
    need_cmd flutter && flutter config --android-sdk "$ANDROID_HOME" >/dev/null 2>&1 || true
fi

# ---- 4. Xcode Command Line Tools (macOS only) ------------------------------
if is_mac; then
    info "=== Xcode Command Line Tools ==="
    if xcode-select -p >/dev/null 2>&1; then
        info "Xcode CLT already installed ($(xcode-select -p))"
    else
        warn "triggering the Xcode CLT installer (a GUI dialog will open) …"
        xcode-select --install || warn "run 'xcode-select --install' manually"
    fi
fi

# ---- 5. CocoaPods (macOS only) ---------------------------------------------
if is_mac; then
    info "=== CocoaPods ==="
    if need_cmd pod; then
        info "cocoapods already installed: $(pod --version 2>/dev/null)"
    else
        brew install cocoapods || warn "cocoapods install failed"
    fi
fi

# ---- 6. fastlane -----------------------------------------------------------
info "=== fastlane ==="
if need_cmd fastlane; then
    info "fastlane already installed: $(fastlane --version 2>/dev/null | grep -m1 fastlane || echo present)"
elif is_mac; then
    brew install fastlane || warn "fastlane brew install failed"
elif need_cmd gem; then
    $SUDO gem install fastlane -N || gem install fastlane -N || warn "fastlane gem install failed"
else
    warn "no gem/brew to install fastlane; install Ruby first (INSTALL_RUBY=1) or: gem install fastlane"
fi

echo
info "Mobile toolchain done. Open a NEW shell (for ANDROID_HOME), then run:"
info "  flutter doctor        # verify Android/iOS setup"
info "  flutter doctor --android-licenses   # if any licenses remain"
