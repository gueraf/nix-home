#!/bin/bash
set -e

# Check if fabian is not in the docker group
if ! groups fabian | grep -q "docker"; then
    echo "Adding fabian to the docker group..."
    usermod -aG docker fabian
    echo "Running as fabian..."
    su fabian -
fi

echo "Building and pushing multi-arch Docker image..."
docker buildx build --platform linux/amd64,linux/arm64 -t gueraf/dev:latest . --push

echo "Done! Image gueraf/dev:latest has been built and pushed for amd64 and arm64."
