#!/bin/sh
cp ./.profile ~/.profile
cp -r fish ~/.config/fish
sudo chsh -s /usr/bin/fish