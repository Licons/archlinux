#!/bin/bash

set -e

read -p "Your model: " MODEL

cat <<EOF > ./Modelfile
FROM $MODEL
PARAMETER num_ctx 65536
PARAMETER temperature 0.1
PARAMETER repeat_penalty 1.05
EOF

ollama create $MODEL-64k -f Modelfile
