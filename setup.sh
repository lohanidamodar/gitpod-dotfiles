#!/bin/sh
cp ./.profile ~/.profile
cp -r ./fish ~/.config/
sudo chsh -s /usr/bin/fish