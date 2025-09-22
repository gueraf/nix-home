docker pull gueraf/dev:latest && \
docker rm -f fabian-dontkillorelse || true && \
docker run -d --name fabian-dontkillorelse -v /mnt/data/local/fabian:/home/fabian/host_fabian --privileged --runtime=nvidia --gpus all --shm-size 8G --restart unless-stopped gueraf/dev:latest
