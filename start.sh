docker pull gueraf/dev:latest && \
docker run -d --name fabian-dontkillorelse -v /mnt/data/local/fabian:/home/fabian/host_fabian --privileged --runtime=nvidia --gpus all gueraf/dev:latest
