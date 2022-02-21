#!/bin/sh
cp ./.bash_profile ~/.bash_profile
cp -r ./fish ~/.config/
sudo chsh -s /usr/bin/fish