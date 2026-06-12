#!/bin/bash

set -e

read -p "Your GPU (n/nvidia or i/intel or amd): " GPU

cat <<EOF >> ~/.config/fish/config.fish
set -x CLAUDE_CODE_SHELL fish
set -x ANTHROPIC_AUTH_TOKEN ollama
set -x ANTHROPIC_API_KEY ""
set -x ANTHROPIC_BASE_URL http://localhost:11434
EOF

cat <<EOF >> ~/.config/fish/functions/claude.fish
function cc
    claude --model qwen3-coder
end
EOF

case $GPU in
    n|nvidia)
        sudo pacman -S ollama-cuda
        ;;
    i|intel)
        sudo pacman -S ollama
        ;;
    amd)
        sudo pacman -S ollama-rocm
        ;;
    *)
        echo "You must be install later."
        ;;
esac

sudo systemctl enable --now ollama.service

systemctl status ollama

curl -fsSL https://claude.ai/install.sh | bash

ollama --version
ollama pull qwen3-coder
ollama run qwen3-coder
# >>> /set parameter num_ctx 65536
ollama launch claude --config
