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
