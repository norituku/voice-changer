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
docker run -it --rm --shm-size=1024M \
-e EX_IP="`hostname -I 2>/dev/null || hostname`" \
-e EX_PORT=${EX_PORT} \
-e LOCAL_UID=$(id -u $USER) \
-e LOCAL_GID=$(id -g $USER) \
-v `pwd`/docker_folder/model_dir:/voice-changer/server/model_dir \
-v `pwd`/docker_folder/pretrain:/voice-changer/server/pretrain \
-p ${EX_PORT}:18888 \
$DOCKER_IMAGE -p 18888 --https true \
    --content_vec_500 pretrain/checkpoint_best_legacy_500.pt  \
    --content_vec_500_onnx pretrain/content_vec_500.onnx \
    --content_vec_500_onnx_on true \
    --hubert_base pretrain/hubert_base.pt \
    --hubert_base_jp pretrain/rinna_hubert_base_jp.pt \
    --hubert_soft pretrain/hubert/hubert-soft-0d54a1f4.pt \
    --nsf_hifigan pretrain/nsf_hifigan/model \
    --crepe_onnx_full pretrain/crepe_onnx_full.onnx \
    --crepe_onnx_tiny pretrain/crepe_onnx_tiny.onnx \
    --rmvpe pretrain/rmvpe.pt \
    --model_dir model_dir \
    --samples samples.json \
    --onnxgpu -1