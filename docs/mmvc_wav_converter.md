# MMVC WAV変換機能

このドキュメントでは、MMVCサーバーでWAVファイルを変換する方法について説明します。

## 概要

MMVC WAV変換機能は、事前に録音されたWAVファイルの音声をMMVCの音声変換モデルを使って変換するための機能です。以下の2つの方法で利用できます：

1. Base64エンコードされたWAVデータを送信して変換
2. WAVファイルをアップロードして変換

## Dockerコンテナの使用方法

### Dockerイメージのビルド

```bash
# Dockerイメージをビルド
./docker/build-mmvc-wav.sh
```

### Dockerコンテナの実行

```bash
# デフォルト設定でコンテナを実行
./docker/run-mmvc-wav.sh

# カスタム設定でコンテナを実行
./docker/run-mmvc-wav.sh --port 18889 --model-dir /path/to/models --name my-mmvc-converter
```

利用可能なオプション：
- `-p, --port PORT`: ポート番号（デフォルト: 18888）
- `-m, --model-dir DIR`: モデルディレクトリのパス（デフォルト: カレントディレクトリ/model_dir）
- `-n, --name NAME`: コンテナ名（デフォルト: mmvc-wav-converter）
- `-h, --help`: ヘルプを表示

## API エンドポイント

### 1. Base64エンコードされたWAVデータを変換

**エンドポイント**: `POST /convert_wav`

**パラメータ**:
- `wav_base64`: Base64エンコードされたWAVデータ（Form Data）

**レスポンス**:
```json
{
  "changedVoiceBase64": "変換後の音声データ（Base64エンコード）"
}
```

**サンプルリクエスト（curl）**:
```bash
curl -X POST "http://localhost:18888/convert_wav" \
  -F "wav_base64=$(base64 -w 0 input.wav)"
```

### 2. WAVファイルをアップロードして変換

**エンドポイント**: `POST /convert_wav_file`

**パラメータ**:
- `file`: WAVファイル（multipart/form-data）
- `output_filename`: 出力ファイル名（オプション）

**レスポンス**:
変換されたWAVファイルがダウンロードされます。

**サンプルリクエスト（curl）**:
```bash
curl -X POST "http://localhost:18888/convert_wav_file" \
  -F "file=@input.wav" \
  -F "output_filename=output.wav" \
  --output output.wav
```

## ブラウザからの使用例

1. ブラウザで `http://localhost:18888` にアクセスします。
2. モデルを選択してロードします。
3. APIエンドポイントを直接呼び出すか、以下のようなHTMLフォームを使用します：

```html
<!DOCTYPE html>
<html>
<head>
  <title>MMVC WAV変換</title>
</head>
<body>
  <h1>MMVC WAV変換</h1>
  
  <h2>WAVファイルをアップロード</h2>
  <form action="http://localhost:18888/convert_wav_file" method="post" enctype="multipart/form-data">
    <input type="file" name="file" accept=".wav" required>
    <input type="text" name="output_filename" placeholder="出力ファイル名（オプション）">
    <button type="submit">変換</button>
  </form>
</body>
</html>
```

## 注意事項

- WAVファイルのサンプリングレートは、ロードしたモデルと互換性がある必要があります。
- 大きなファイルの処理には時間がかかる場合があります。
- Dockerコンテナを実行するにはNVIDIA GPUとDocker環境が必要です。 