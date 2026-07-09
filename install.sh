#!/usr/bin/env bash
# clone https://github.com/lohanidamodar/gitpod-dotfiles.git to ~/.dotfiles
# then run the ~/.dotfiles/setup.sh script'
# USE: curl -fsSL https://raw.githubusercontent.com/lohanidamodar/gitpod-dotfiles/main/install.sh | bash
#
# PREREQUISITES: git and curl (this script clones over git; curl fetched it).
# On a fresh box install them first (drop the `sudo` if you're root):
#   Arch:          sudo pacman -Sy --needed --noconfirm git curl
#   Debian/Ubuntu: sudo apt-get update && sudo apt-get install -y git curl
#   Fedora:        sudo dnf install -y git curl
#   openSUSE:      sudo zypper install -y git curl
#   Alpine:        sudo apk add git curl
#
# Root-only Arch/WSL? Create a non-root sudo user first (installs sudo too):
#   bash scripts/create_sudo_user.sh <username>   # run as root

REPO_URL="https://github.com/lohanidamodar/gitpod-dotfiles.git"
DOTFILES="${HOME}/.dotfiles"

echo "Checking dotfiles repository at ${DOTFILES}"

if [ -d "${DOTFILES}/.git" ]; then
  # Already a git clone — update it in place.
  echo "Dotfiles already cloned; pulling latest..."
  branch="$(git -C "${DOTFILES}" symbolic-ref --short HEAD 2>/dev/null || echo main)"
  git -C "${DOTFILES}" pull --ff-only origin "${branch}" \
    || echo "WARNING: git pull failed (local changes?); using existing checkout."
elif [ -d "${DOTFILES}" ]; then
  # Directory exists but isn't a git repo — don't clobber it, just warn.
  echo "WARNING: ${DOTFILES} exists but is not a git repo; using it as-is."
else
  echo "Cloning repository..."
  git clone "${REPO_URL}" "${DOTFILES}"
fi


if [ ! -f "${HOME}/.dotfiles/setup.sh" ]; then
  echo "Setup script not found in cloned dotfiles repository."
  exit 1
fi

echo "Running setup script from dotfiles repository..."

bash "${HOME}/.dotfiles/setup.sh"