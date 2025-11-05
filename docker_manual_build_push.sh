#!/bin/bash
set -e

# Check if fabian is not in the docker group
if ! groups fabian | grep -q "docker"; then
    echo "Adding fabian to the docker group..."
    usermod -aG docker fabian
    echo "Running as fabian..."
    su fabian -
fi

# Check if a multi-platform builder exists, if not, create one
if ! docker buildx inspect multiarch_builder > /dev/null 2>&1; then
    echo "Creating multi-platform buildx builder..."
    docker buildx create --name multiarch_builder --use
fi

echo "Building and pushing multi-arch Docker image..."
docker buildx build --platform linux/arm64 -t gueraf/dev:arm . --push

echo "Done! Image gueraf/dev:latest has been built and pushed for amd64 and arm64."
