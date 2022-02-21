#!/usr/bin/env bash

DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

cp $DIR/.profile ~/.profile

cp  -r $DIR/fish/ ~/.config/fish
sudo chsh -s /usr/bin/fish