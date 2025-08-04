#!/bin/bash
set -e

echo "Building Docker image..."
sudo docker build -t gueraf/dev:latest .

echo "Pushing Docker image to Docker Hub..."
docker push gueraf/dev:latest

echo "Done! Image gueraf/dev:latest has been built and pushed."
