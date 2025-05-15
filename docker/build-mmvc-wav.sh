#!/bin/bash

# 現在のディレクトリを取得（このスクリプトが配置されているdockerディレクトリと仮定）
SCRIPT_DIR=$(cd $(dirname $0); pwd)
ROOT_DIR=$(dirname $SCRIPT_DIR)

# ダミーファイル作成（Dockerビルド用）
mkdir -p $SCRIPT_DIR/dummy
touch $SCRIPT_DIR/dummy/dummy

# イメージ名とタグの設定
IMAGE_NAME="mmvc-wav-converter"
TAG="latest"

# ビルド開始
echo "Building Docker image: $IMAGE_NAME:$TAG"
docker build -f $SCRIPT_DIR/Dockerfile-mmvc-wav-converter -t $IMAGE_NAME:$TAG $SCRIPT_DIR

# ビルド完了
echo "Build completed."
echo "You can run the container with:"
echo "docker run -it --gpus all -p 18888:18888 -v /path/to/models:/voice-changer/server/model_dir $IMAGE_NAME:$TAG" 