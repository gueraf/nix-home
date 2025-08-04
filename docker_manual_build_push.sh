#!/bin/bash
set -e

# Check if fabian is not in the docker group
if ! groups fabian | grep -q "docker"; then
    echo "Adding fabian to the docker group..."
    usermod -aG docker fabian
    echo "Running as fabian..."
    su fabian -
fi

echo "Building Docker image..."
docker build -t gueraf/dev:latest .

echo "Pushing Docker image to Docker Hub..."
docker push gueraf/dev:latest

echo "Done! Image gueraf/dev:latest has been built and pushed."
