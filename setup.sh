#!/usr/bin/env bash

DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

echo "copy bashrc"
cp $DIR/.bashrc $HOME/.bashrc

echo "copying bash profile"
cp $DIR/.bash_profile $HOME/.bash_profile


echo "installing exa"
sh $DIR/scripts/build_exa/build_exa.sh
# sh $DIR/scripts/install_exa.sh

# echo "installing fish 3"
# sh $DIR/scripts/install_fish3.sh

echo "installing fish config and setthing fish as default shell"
mkdir -p ~/.config/fish >/dev/null 2>&1
cp  -r $DIR/fish/* ~/.config/fish
sudo chsh -s /usr/bin/fish