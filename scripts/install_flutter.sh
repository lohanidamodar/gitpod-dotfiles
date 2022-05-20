#!/usr/bin/env bash


git clone https://github.com/flutter/flutter.git -b stable

mv flutter ~/flutter

echo 'PATH="$HOME/flutter/bin:$PATH"' >> ~/.bash_profile
echo 'export PATH' >> ~/.bash_profile

source .bashrc

flutter precache