#!/bin/bash

set -e

yay -Syu --noconfirm 

yay -S --noconfirm ollama

sudo systemctl enable --now ollama.service

mkdir -p /etc/systemd/system/ollama.service.d
sudo tee /etc/systemd/system/ollama.service.d/override.conf > /dev/null <<EOF
[Service]
Environment="OLLAMA_CONTEXT_LENGTH=131072"
Environment="OLLAMA_FLASH_ATTENTION=1"
Environment="OLLAMA_NUM_PARALLEL=2"
EOF
