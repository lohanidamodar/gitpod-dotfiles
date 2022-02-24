#!/usr/bin/env bash

DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

cp $DIR/.bash_profile ~/.bash_profile

source ~/.bash_profile

sh $DIR/install_exa.sh

cp  -r $DIR/fish/ ~/.config/fish
sudo chsh -s /usr/bin/fish