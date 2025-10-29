#!/bin/bash

# Ensure the necessary environment variables are set
if [ -z "$DOCKER_HUB_TOKEN" ] || [ -z "$DOCKER_HUB_USERNAME" ]; then
  echo "Warning: DOCKER_HUB_TOKEN or DOCKER_HUB_USERNAME environment variable is not set. docker login not success"
  exit 0 // exit without failing
fi

# Log in to Docker Hub using the token
echo "$DOCKER_HUB_TOKEN" | docker login -u "$DOCKER_HUB_USERNAME" --password-stdin
