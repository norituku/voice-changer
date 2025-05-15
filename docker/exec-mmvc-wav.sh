#!/bin/bash

# サーバーを実行するスクリプト
cd /voice-changer/server

# デフォルトのパラメータ
PORT=${EX_PORT:-18888}
HOST="0.0.0.0"
HTTPS=0
MODEL_DIR="model_dir"
SAMPLE_MODE="production"

# 引数の解析
while (( $# > 0 )); do
  case $1 in
    -p | --port)
      PORT="$2"
      shift 2
      ;;
    -h | --host)
      HOST="$2"
      shift 2
      ;;
    --https)
      HTTPS=1
      shift
      ;;
    --model_dir)
      MODEL_DIR="$2"
      shift 2
      ;;
    --sample_mode)
      SAMPLE_MODE="$2"
      shift 2
      ;;
    *)
      shift
      ;;
  esac
done

# HTTPSオプションの設定
HTTPS_OPTION=""
if [ "$HTTPS" -eq 1 ]; then
  HTTPS_OPTION="--https 1"
fi

# サーバープロセスの起動
echo "Starting MMVC Wav Converter Server on $HOST:$PORT"
echo "Model directory: $MODEL_DIR"
echo "Sample mode: $SAMPLE_MODE"

# 環境変数を設定
export PYTHONPATH=$PYTHONPATH:/voice-changer

# 新しいコンバーターアプリを起動
python3 wav_converter.py 