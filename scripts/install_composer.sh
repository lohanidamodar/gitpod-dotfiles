#!/bin/bash

# Bash script to install Composer on Ubuntu

# Exit script on error
set -e

# Function to print messages
echo_info() {
    echo -e "\033[1;34m[INFO]\033[0m $1"
}
echo_success() {
    echo -e "\033[1;32m[SUCCESS]\033[0m $1"
}
echo_error() {
    echo -e "\033[1;31m[ERROR]\033[0m $1"
}

# Check for root privileges
if [ "$EUID" -ne 0 ]; then
    echo_error "Please run as root or use sudo."
    exit 1
fi

# Update package list
echo_info "Updating package list..."
apt update

# Install PHP and required dependencies
echo_info "Installing PHP and required dependencies..."
apt install -y php-cli unzip curl

# Download the Composer installer
echo_info "Downloading Composer installer..."
curl -sS https://getcomposer.org/installer -o composer-setup.php

# Verify the installer checksum
echo_info "Verifying installer checksum..."
EXPECTED_SIGNATURE=$(curl -sS https://composer.github.io/installer.sig)
ACTUAL_SIGNATURE=$(php -r "echo hash_file('SHA384', 'composer-setup.php');")

if [ "$EXPECTED_SIGNATURE" != "$ACTUAL_SIGNATURE" ]; then
    echo_error "Installer checksum verification failed. Aborting."
    rm composer-setup.php
    exit 1
fi

echo_success "Installer checksum verified."

# Run the installer
echo_info "Installing Composer..."
php composer-setup.php --install-dir=/usr/local/bin --filename=composer

# Clean up
echo_info "Cleaning up..."
rm composer-setup.php

# Verify installation
echo_info "Verifying Composer installation..."
if command -v composer > /dev/null; then
    echo_success "Composer installed successfully!"
    composer --version
else
    echo_error "Composer installation failed."
    exit 1
fi
