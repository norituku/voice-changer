#!/bin/bash
set -eu

# Create necessary directories
mkdir -p docker_folder/pretrain/hubert
mkdir -p docker_folder/pretrain/nsf_hifigan

# Download models from Hugging Face
echo "Downloading pre-trained models..."

# URLs for model files
HUBERT_BASE_URL="https://huggingface.co/wok000/vcclient000/resolve/main/model/hubert_base.pt"
HUBERT_SOFT_URL="https://huggingface.co/wok000/vcclient000/resolve/main/model/hubert-soft-0d54a1f4.pt"
CONTENT_VEC_PT_URL="https://huggingface.co/wok000/vcclient000/resolve/main/model/checkpoint_best_legacy_500.pt"
CONTENT_VEC_ONNX_URL="https://huggingface.co/wok000/vcclient000/resolve/main/model/content_vec_500.onnx"
CREPE_FULL_URL="https://huggingface.co/wok000/vcclient000/resolve/main/model/crepe_onnx_full.onnx"
CREPE_TINY_URL="https://huggingface.co/wok000/vcclient000/resolve/main/model/crepe_onnx_tiny.onnx"
RMVPE_URL="https://huggingface.co/wok000/vcclient000/resolve/main/model/rmvpe.pt"
HUBERT_JP_URL="https://huggingface.co/wok000/vcclient000/resolve/main/model/rinna_hubert_base_jp.pt"
NSF_HIFIGAN_URL="https://huggingface.co/wok000/vcclient000/resolve/main/model/nsf_hifigan.zip"

# Download function with error handling
download_file() {
    local url=$1
    local dest=$2
    echo "Downloading $dest..."
    
    if curl -L -o "$dest" "$url"; then
        echo "Successfully downloaded $dest"
    else
        echo "Failed to download $dest"
        return 1
    fi
}

# Download individual model files
download_file "$HUBERT_BASE_URL" "docker_folder/pretrain/hubert_base.pt"
download_file "$HUBERT_SOFT_URL" "docker_folder/pretrain/hubert/hubert-soft-0d54a1f4.pt"
download_file "$CONTENT_VEC_PT_URL" "docker_folder/pretrain/checkpoint_best_legacy_500.pt"
download_file "$CONTENT_VEC_ONNX_URL" "docker_folder/pretrain/content_vec_500.onnx"
download_file "$CREPE_FULL_URL" "docker_folder/pretrain/crepe_onnx_full.onnx"
download_file "$CREPE_TINY_URL" "docker_folder/pretrain/crepe_onnx_tiny.onnx"
download_file "$RMVPE_URL" "docker_folder/pretrain/rmvpe.pt"
download_file "$HUBERT_JP_URL" "docker_folder/pretrain/rinna_hubert_base_jp.pt"

# Download and extract NSF HifiGAN
echo "Downloading NSF HifiGAN..."
if curl -L -o "docker_folder/pretrain/nsf_hifigan.zip" "$NSF_HIFIGAN_URL"; then
    echo "Extracting NSF HifiGAN..."
    unzip -o "docker_folder/pretrain/nsf_hifigan.zip" -d "docker_folder/pretrain/"
    echo "Successfully set up NSF HifiGAN"
else
    echo "Failed to download NSF HifiGAN"
fi

echo "Model download complete!"
echo "You can now run './start_docker_mac_m3.sh' to start the voice changer server."