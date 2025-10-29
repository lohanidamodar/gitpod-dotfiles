#!/usr/bin/env bash
# clone https://github.com/lohanidamodar/gitpod-dotfiles.git to ~/.dotfiles
# then run the ~/.dotfiles/setup.sh script

if [ -d "${HOME}/.dotfiles" ]; then
  echo "Dotfiles directory already exists at ${HOME}/.dotfiles"
  echo "Updating existing dotfiles..."
  
  cd "${HOME}/.dotfiles" || exit 1
    git pull origin main
else
  git clone https://github.com/lohanidamodar/gitpod-dotfiles.git "${HOME}/.dotfiles"
fi


if [ ! -f "${HOME}/.dotfiles/setup.sh" ]; then
  echo "Setup script not found in cloned dotfiles repository."
  exit 1
fi

echo "Running setup script from dotfiles repository..."

bash "${HOME}/.dotfiles/setup.sh"