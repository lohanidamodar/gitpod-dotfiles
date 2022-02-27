#!/usr/bin/env bash

sudo apt install clang libicu-dev libpython2.7-dev libtinfo5 libncurses5 libpython2.7 libz3-dev

wget https://download.swift.org/swift-5.5.2-release/ubuntu2004/swift-5.5.2-RELEASE/swift-5.5.2-RELEASE-ubuntu20.04.tar.gz

tar xzf swift-5.5.2-RELEASE-ubuntu20.04.tar.gz
sudo mv swift-5.5.2-RELEASE-ubuntu20.04 /usr/share/swift
echo "export PATH=/usr/share/swift/usr/bin:$PATH" >> ~/.bashrc
source  ~/.bashrc

swift --version