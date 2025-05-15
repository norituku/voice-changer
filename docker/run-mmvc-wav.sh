#!/bin/bash

# デフォルト設定
IMAGE_NAME="mmvc-wav-converter"
TAG="latest"
PORT=18888
MODEL_DIR="$PWD/model_dir"
CONTAINER_NAME="mmvc-wav-converter"

# ヘルプメッセージ表示関数
function show_help {
    echo "MMVC WAV Converter Docker コンテナ実行スクリプト"
    echo ""
    echo "使用方法:"
    echo "  $0 [options]"
    echo ""
    echo "オプション:"
    echo "  -p, --port PORT       ポート番号（デフォルト: 18888）"
    echo "  -m, --model-dir DIR   モデルディレクトリのパス（デフォルト: カレントディレクトリ/model_dir）"
    echo "  -n, --name NAME       コンテナ名（デフォルト: mmvc-wav-converter）"
    echo "  -h, --help            このヘルプを表示"
    echo ""
}

# 引数の解析
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        -p|--port)
            PORT="$2"
            shift
            shift
            ;;
        -m|--model-dir)
            MODEL_DIR="$2"
            shift
            shift
            ;;
        -n|--name)
            CONTAINER_NAME="$2"
            shift
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo "不明なオプション: $1"
            show_help
            exit 1
            ;;
    esac
done

# モデルディレクトリの確認
if [ ! -d "$MODEL_DIR" ]; then
    echo "警告: モデルディレクトリ $MODEL_DIR が存在しません。自動的に作成します。"
    mkdir -p "$MODEL_DIR"
fi

# 既存のコンテナを停止・削除
if [ "$(docker ps -aq -f name=$CONTAINER_NAME)" ]; then
    echo "既存のコンテナを停止・削除します..."
    docker stop $CONTAINER_NAME > /dev/null 2>&1
    docker rm $CONTAINER_NAME > /dev/null 2>&1
fi

# Docker コンテナの実行
echo "MMVCサーバーコンテナを開始します..."
echo "ポート: $PORT"
echo "モデルディレクトリ: $MODEL_DIR"

if command -v nvidia-smi &> /dev/null; then
    # NVIDIA GPUが利用可能な場合
    docker run -it --gpus all \
        --name $CONTAINER_NAME \
        -p $PORT:$PORT \
        -e EX_PORT=$PORT \
        -v "$MODEL_DIR":/voice-changer/server/model_dir \
        $IMAGE_NAME:$TAG
else
    # GPUが利用できない場合
    echo "GPUが検出されませんでした。CPUモードで実行します。"
    docker run -it \
        --name $CONTAINER_NAME \
        -p $PORT:$PORT \
        -e EX_PORT=$PORT \
        -v "$MODEL_DIR":/voice-changer/server/model_dir \
        $IMAGE_NAME:$TAG
fi 