#!/bin/bash

# スクリプトの説明
echo "=== MMVC WAV変換サーバーをビルド・実行するスクリプト ==="
echo "このスクリプトはRVCモデルを使ってWAVファイルを変換するDockerコンテナをビルドし、実行します。"

# ディレクトリの確認
if [ ! -d "model_dir" ]; then
  echo "エラー: model_dirディレクトリが見つかりません。"
  echo "RVCモデルを model_dir/(スロットID) ディレクトリに配置してください。"
  exit 1
fi

# Dockerfileの確認
if [ ! -f "docker/Dockerfile-mmvc-wav-converter" ]; then
  echo "エラー: Dockerfileが見つかりません。"
  exit 1
fi

# wav_converter.pyをDockerディレクトリにコピー
echo "wav_converter.pyをDockerディレクトリにコピーします..."
cp wav_converter.py docker/

# Dockerイメージをビルド
echo "Dockerイメージをビルドしています..."
docker build -t mmvc-wav-converter -f docker/Dockerfile-mmvc-wav-converter docker/

# 必要なディレクトリを作成
mkdir -p upload_dir/temp

# Dockerコンテナを実行
echo "MMVCサーバーを起動しています..."
docker run --rm -it \
  -p 18888:18888 \
  -v "$(pwd)/model_dir:/voice-changer/server/model_dir" \
  -v "$(pwd)/upload_dir:/voice-changer/server/upload_dir" \
  --name mmvc-wav-converter \
  mmvc-wav-converter

echo "サーバーは http://localhost:18888 で実行中です"
echo "Ctrl+Cで終了できます" 