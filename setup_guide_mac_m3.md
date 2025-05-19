# Mac M3 Setup Guide for RVC Voice Changer

This guide will help you set up the RVC voice changer server on a Mac with an M3 chip using Docker.

## Prerequisites

1. Install Docker Desktop for Mac (Apple Silicon version) from [Docker's official website](https://www.docker.com/products/docker-desktop/)
2. Download and extract this repository
3. Make sure you have at least 10GB of free disk space

## Setup Steps

### 1. Make the scripts executable

```bash
chmod +x start_docker_mac_m3.sh download_models_mac_m3.sh
```

### 2. Download pre-trained models

Use the provided download script to automatically download required pre-trained models:

```bash
./download_models_mac_m3.sh
```

The script will download these essential models to the proper locations:
- `hubert_base.pt`
- `hubert/hubert-soft-0d54a1f4.pt`
- `rinna_hubert_base_jp.pt` 
- `nsf_hifigan/model`
- `content_vec_500.onnx`
- `checkpoint_best_legacy_500.pt`
- `crepe_onnx_full.onnx`
- `crepe_onnx_tiny.onnx`
- `rmvpe.pt`

If you prefer to download manually, get the models from [HuggingFace VCClient repository](https://huggingface.co/wok000/vcclient000/tree/main) and place them in the `docker_folder/pretrain` directory.

### 3. Start the server

```bash
./start_docker_mac_m3.sh
```

This will:
1. Create necessary directory structure if it doesn't exist
2. Build a Docker image optimized for Mac M3
3. Start the RVC voice changer server in CPU-only mode
4. Make the server available on port 18888

The first time you run this script, it will build the Docker image which may take several minutes.

### 4. Connect to the server

Open Chrome and navigate to:

```
https://localhost:18888
```

You may see a security warning since it uses a self-signed certificate. Click "Advanced" and proceed to the website.

## Troubleshooting

### Build Issues

- If you encounter build errors related to packages like onnxruntime-gpu or onnxsim, the Dockerfile has been configured to handle these by filtering them out and using CPU-compatible alternatives.

- If you see connection errors in Chrome, ensure Docker is properly running and that port 18888 isn't being used by another application.

### Performance Tips

- The server runs in CPU-only mode since GPU acceleration isn't available for ARM Macs yet
- For better performance:
  - Increase the CHUNK value in the GUI settings (try 1024 or 2048)
  - Set F0 Det to "dio" in the settings for lightweight processing
  - Use smaller models if available
  - Close other CPU-intensive applications

### Custom Models

To use your own RVC models:
1. Place them in the `docker_folder/model_dir` directory
2. They will be available in the model selection dropdown in the web interface

## Usage Notes

Once running, you can:
1. Select a voice model from the dropdown
2. Configure input/output audio devices
3. Adjust settings like TUNE (pitch), INDEX (feature weight), and other parameters
4. Click START to begin voice conversion

For detailed usage instructions, refer to the tutorials in the main project documentation.