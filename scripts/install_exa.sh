#!/usr/bin/env bash

# Ensure the necessary dependencies are installed
sudo apt update
sudo apt install -y curl unzip

# Get the latest version of exa from GitHub
EXA_VERSION=$(curl -s "https://api.github.com/repos/ogham/exa/releases/latest" | grep -Po '"tag_name": "v\K[0-9.]+')

# Determine the system architecture
ARCH=$(uname -m)

if [ "$ARCH" == "x86_64" ]; then
    ARCH_TYPE="linux-x86_64"
elif [ "$ARCH" == "aarch64" ]; then
    ARCH_TYPE="linux-armv7"
else
    echo "Unsupported architecture: $ARCH"
    exit 1
fi

echo "v${EXA_VERSION}/exa-${ARCH_TYPE}-v${EXA_VERSION}.zip" 

# Download the correct binary for the system architecture
curl -Lo exa.zip "https://github.com/ogham/exa/releases/download/v${EXA_VERSION}/exa-${ARCH_TYPE}-v${EXA_VERSION}.zip"

# Extract the binary and move it to /usr/local/bin
sudo unzip -q exa.zip bin/exa -d /usr/local
sudo chmod +x /usr/local/bin/exa

# Verify the installation
exa --version

# Clean up the zip file
rm -rf exa.zip
