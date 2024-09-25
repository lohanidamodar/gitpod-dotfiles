#!/usr/bin/env bash

# Function to check if Docker is installed
check_docker_installed() {
    if [ -x "$(command -v docker)" ]; then
        echo "Docker is already installed."
        return 0
    else
        echo "Docker is not installed. Installing Docker..."
        return 1
    fi
}

# Function to install Docker using the official script from get.docker.com
install_docker() {
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    rm get-docker.sh
}

# Check if Docker is installed
if ! check_docker_installed; then
    # Install Docker if not present
    install_docker
fi

# Check Docker status and output Docker version
if [ -x "$(command -v docker)" ]; then
    echo "Docker installation was successful."
    docker --version
else
    echo "Docker installation failed."
fi
