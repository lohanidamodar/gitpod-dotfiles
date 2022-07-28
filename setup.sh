#!/usr/bin/env bash

DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

echo "copy bashrc"
cp $DIR/.bashrc $HOME/.bashrc

echo "copying bash profile"
cp $DIR/.bash_profile $HOME/.bash_profile


echo "installing exa"
sh $DIR/scripts/install_exa.sh

echo "installing fish 3"
sh $DIR/scripts/install_fish3.sh

echo "installing fish config and setthing fish as default shell"
cp  -r $DIR/fish/* ~/.config/fish
sudo chsh -s /usr/bin/fish