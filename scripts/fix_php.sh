#!/bin/bash

###############################################################################
# PHP and Composer Fix Script for Ubuntu 24.04
# 
# This script fixes PHP OpenSSL compatibility issues and ensures
# PHP and Composer are properly installed and working.
###############################################################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}PHP and Composer Fix Script${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Check if running as root (not needed for dev container, but good practice)
if [ "$EUID" -eq 0 ]; then 
    echo -e "${YELLOW}Warning: Running as root${NC}"
fi

# Step 1: Check current PHP status
echo -e "${YELLOW}Step 1: Checking current PHP installation...${NC}"
if php -v 2>&1 | grep -q "OPENSSL"; then
    echo -e "${RED}✗ PHP has OpenSSL compatibility issues${NC}"
    PHP_BROKEN=true
else
    if command -v php &> /dev/null; then
        echo -e "${GREEN}✓ PHP is working${NC}"
        php -v
        PHP_BROKEN=false
    else
        echo -e "${RED}✗ PHP not found${NC}"
        PHP_BROKEN=true
    fi
fi
echo ""

# Step 2: Update package lists
echo -e "${YELLOW}Step 2: Updating package lists...${NC}"
sudo apt-get update -qq
echo -e "${GREEN}✓ Package lists updated${NC}"
echo ""

# Step 3: Install PHP 8.3 from Ubuntu repositories
echo -e "${YELLOW}Step 3: Installing PHP 8.3 and required extensions...${NC}"

# Common PHP extensions needed for Composer and general development
PHP_PACKAGES=(
    php8.3-cli
    php8.3-common
    php8.3-curl
    php8.3-mbstring
    php8.3-xml
    php8.3-zip
    php8.3-bcmath
    php8.3-intl
    php8.3-opcache
    php8.3-readline
)

sudo apt-get install -y "${PHP_PACKAGES[@]}"
echo -e "${GREEN}✓ PHP 8.3 installed${NC}"
echo ""

# Step 4: Update alternatives to use system PHP
echo -e "${YELLOW}Step 4: Setting up PHP alternatives...${NC}"

# Check if /usr/bin/php8.3 exists
if [ -f /usr/bin/php8.3 ]; then
    # Remove old symlink if it exists
    if [ -L /usr/local/bin/php ]; then
        sudo rm -f /usr/local/bin/php
    fi
    
    # Create new symlink to system PHP 8.3
    sudo ln -sf /usr/bin/php8.3 /usr/local/bin/php
    
    # Also update PATH priority by creating symlink in /usr/local/bin
    sudo update-alternatives --install /usr/bin/php php /usr/bin/php8.3 100 || true
    
    echo -e "${GREEN}✓ PHP alternatives configured${NC}"
else
    echo -e "${RED}✗ PHP 8.3 binary not found${NC}"
    exit 1
fi
echo ""

# Step 5: Verify PHP installation
echo -e "${YELLOW}Step 5: Verifying PHP installation...${NC}"
export PATH="/usr/local/bin:/usr/bin:$PATH"
hash -r  # Clear bash command hash

if /usr/bin/php8.3 -v; then
    echo -e "${GREEN}✓ PHP 8.3 is working correctly${NC}"
else
    echo -e "${RED}✗ PHP verification failed${NC}"
    exit 1
fi
echo ""

# Step 6: Install/Update Composer
echo -e "${YELLOW}Step 6: Installing/Updating Composer...${NC}"

# Download and verify Composer installer
EXPECTED_CHECKSUM="$(wget -q -O - https://composer.github.io/installer.sig)"
/usr/bin/php8.3 -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
ACTUAL_CHECKSUM="$(/usr/bin/php8.3 -r "echo hash_file('sha384', 'composer-setup.php');")"

if [ "$EXPECTED_CHECKSUM" != "$ACTUAL_CHECKSUM" ]; then
    echo -e "${RED}✗ Composer installer corrupt${NC}"
    rm composer-setup.php
    exit 1
fi

# Install Composer globally
sudo /usr/bin/php8.3 composer-setup.php --quiet --install-dir=/usr/local/bin --filename=composer
rm composer-setup.php

echo -e "${GREEN}✓ Composer installed${NC}"
echo ""

# Step 7: Update environment for current session
echo -e "${YELLOW}Step 7: Updating environment...${NC}"

# Add to .bashrc if not already there
BASHRC="$HOME/.bashrc"
if [ -f "$BASHRC" ]; then
    if ! grep -q "export PATH=\"/usr/local/bin:\$PATH\"" "$BASHRC"; then
        echo "" >> "$BASHRC"
        echo "# PHP 8.3 priority path" >> "$BASHRC"
        echo "export PATH=\"/usr/local/bin:\$PATH\"" >> "$BASHRC"
        echo -e "${GREEN}✓ Updated .bashrc${NC}"
    fi
fi

# Also update for fish shell if present
if [ -f "$HOME/.config/fish/config.fish" ]; then
    FISHCONFIG="$HOME/.config/fish/config.fish"
    if ! grep -q "set -gx PATH /usr/local/bin" "$FISHCONFIG"; then
        echo "" >> "$FISHCONFIG"
        echo "# PHP 8.3 priority path" >> "$FISHCONFIG"
        echo "set -gx PATH /usr/local/bin \$PATH" >> "$FISHCONFIG"
        echo -e "${GREEN}✓ Updated fish config${NC}"
    fi
fi

echo ""

# Step 8: Final verification
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Final Verification${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

echo -e "${YELLOW}PHP Version:${NC}"
/usr/local/bin/php -v
echo ""

echo -e "${YELLOW}Composer Version:${NC}"
/usr/local/bin/composer --version
echo ""

echo -e "${YELLOW}PHP Modules:${NC}"
/usr/local/bin/php -m | head -20
echo "... (and more)"
echo ""

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✓ PHP and Composer are now fixed!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Close and reopen your terminal, or run: source ~/.bashrc"
echo "2. Run: composer install"
echo ""
echo -e "${YELLOW}To use the new PHP immediately in this session:${NC}"
echo "  export PATH=\"/usr/local/bin:\$PATH\""
echo "  hash -r"
echo ""
