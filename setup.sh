#!/usr/bin/env bash

DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

echo "copy bashrc"
cp $DIR/.bashrc $HOME/.bashrc

echo "copying bash profile"
cp $DIR/.bash_profile $HOME/.bash_profile

echo "checking for docker"
if ! command -v docker >/dev/null 2>&1; then
    echo "docker not found, installing docker"
    sh $DIR/scripts/install_docker.sh
else
    echo "docker already installed, skipping"
fi

echo "installing exa"
# sh $DIR/scripts/install_exa.sh
if ! command -v exa >/dev/null 2>&1; then
    echo "exa not found, installing exa"
    sh $DIR/scripts/build_exa/build_exa.sh
else
    echo "exa already installed, skipping"
fi

# echo "installing fish 3"
# sh $DIR/scripts/install_fish3.sh
echo "installing fish 3"
if ! command -v fish >/dev/null 2>&1; then
    echo "fish not found, installing fish 3"
    sh $DIR/scripts/install_fish3.sh
else
    echo "fish already installed, skipping"
fi


echo "installing fish config and setting fish as default shell"
mkdir -p ~/.config/fish >/dev/null 2>&1
cp  -r $DIR/fish/* ~/.config/fish
sudo chsh -s /usr/bin/fish