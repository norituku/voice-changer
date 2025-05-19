#!/bin/bash
set -eu

### DEFAULT VAR ###
DEFAULT_EX_PORT=18888
DEFAULT_USE_LOCAL=on # on|off

### ENV VAR ###
EX_PORT=${EX_PORT:-${DEFAULT_EX_PORT}}
USE_LOCAL=${USE_LOCAL:-${DEFAULT_USE_LOCAL}}

# Create necessary directories
echo "Creating required directories..."
mkdir -p docker_folder/model_dir
mkdir -p docker_folder/pretrain
mkdir -p docker_folder/pretrain/hubert
mkdir -p docker_folder/pretrain/nsf_hifigan

# Check if required model files exist
if [ ! -f "docker_folder/pretrain/hubert-soft-0d54a1f4.pt" ]; then
    echo "Warning: Required model files not found in docker_folder/pretrain/"
    echo "Please download the models from https://huggingface.co/wok000/vcclient000/tree/main"
    echo "and place them in the docker_folder/pretrain directory before running the server."
    echo "Continuing with build..."
fi

# Always build local image for Mac M3
if [ "${USE_LOCAL}" = "on" ]; then
    echo "Building local Docker image for Mac M3..."
    # Create a timestamp file for build
    date +%Y%m%d%H%M%S > docker_vcclient/dummy
    # Copy ARM-specific exec.sh
    cp docker_vcclient/exec.sh.arm docker_vcclient/exec.sh
    # Build the Docker image
    DOCKER_BUILDKIT=1 docker build -f docker_vcclient/Dockerfile.arm docker_vcclient/ -t vcclient-m3
    DOCKER_IMAGE=vcclient-m3
else
    echo "Error: For Mac M3, only local builds are supported."
    exit 1
fi

echo "VC Client starting for Mac M3..."
CONTAINER_ID=$(docker run -d --rm --shm-size=1024M \
-e EX_IP="`hostname -I 2>/dev/null || hostname`" \
-e EX_PORT=${EX_PORT} \
-e LOCAL_UID=$(id -u $USER) \
-e LOCAL_GID=$(id -g $USER) \
-v `pwd`/docker_folder/model_dir:/voice-changer/server/model_dir \
-v `pwd`/docker_folder/pretrain:/voice-changer/server/pretrain \
-p ${EX_PORT}:18888 \
$DOCKER_IMAGE python3 MMVCServerSIO.py -p 18888 --https true \
    --model_dir model_dir \
    --debug true \
    --onnxgpu -1)

echo "Container started with ID: $CONTAINER_ID"
echo "Waiting for server to initialize..."
sleep 5

# Check if container is still running
if docker ps | grep -q $CONTAINER_ID; then
    echo "Server is running! Access https://localhost:${EX_PORT} in your browser."
    echo "To stop the server, run: docker stop $CONTAINER_ID"
else
    echo "Server failed to start. Checking logs:"
    docker logs $CONTAINER_ID || echo "Container has already exited. No logs available."
fi