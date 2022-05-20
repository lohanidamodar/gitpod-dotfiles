#!/usr/bin/env bash


git clone https://github.com/flutter/flutter.git -b stable

mv flutter ~/flutter

echo 'PATH="$HOME/flutter/bin:$PATH"' >> ~/.bash_profile
echo 'export PATH' >> ~/.bash_profile

sudo apt-get update

wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb

sudo dpkg -i google-chrome-stable_current_amd64.deb

sudo apt-get install -f

source ~/.bashrc

flutter precache
