#!/usr/bin/env bash

# Create a temporary directory for the Dockerfile
mkdir exa-docker-build
cd exa-docker-build

# Create Dockerfile
cat <<EOF > Dockerfile
# Dockerfile for building exa from source

# Use a base image with Rust and build essentials
FROM rust:latest

# Install necessary dependencies
RUN apt-get update && apt-get install -y \
    git \
    libssl-dev \
    pkg-config \
    && rm -rf /var/lib/apt/lists/*

# Clone the exa repository and build it
RUN git clone https://github.com/ogham/exa.git /exa

WORKDIR /exa

# Build exa from source
RUN cargo build --release

# The final stage, copy the built binary to the target folder
RUN cp target/release/exa /usr/local/bin/exa

# Run the exa command as a test
CMD ["exa", "--version"]
EOF

# Build the Docker image
docker build -t exa-builder .

# Create a container from the image
docker create --name exa-container exa-builder

# Copy the exa binary from the container to your local system
docker cp exa-container:/usr/local/bin/exa .

# Clean up: remove the container and the image
docker rm exa-container
docker rmi exa-builder

# Move the exa binary to /usr/local/bin
sudo mv exa /usr/local/bin

# Verify installation
exa --version

# Clean up the temporary directory
cd ..
rm -rf exa-docker-build
