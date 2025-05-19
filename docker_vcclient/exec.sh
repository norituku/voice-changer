#!/bin/bash

set -eu

# Enable error logging
exec > >(tee /tmp/server_output.log) 2>&1

echo "Starting voice changer server with parameters: $@"
echo "Directory content:"
ls -la

# Run with specific parameters for ARM architecture
python3 MMVCServerSIO.py $@ --onnxgpu -1 || {
    echo "Error: Server failed to start" 
    echo "Error details:"
    cat /tmp/server_output.log
    exit 1
}