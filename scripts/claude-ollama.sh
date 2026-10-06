#!/usr/bin/env bash
set -e

echo "== AI Router Setup =="

# -----------------------------
# 1. Create project folder
# -----------------------------
mkdir -p ~/ai-router
cd ~/ai-router

echo "[1/6] Creating venv..."
python -m venv .venv

source .venv/bin/activate

echo "[2/6] Upgrading pip..."
pip install --upgrade pip

echo "[3/6] Installing dependencies..."
pip install fastapi uvicorn requests

# -----------------------------
# 2. Create router.py
# -----------------------------
echo "[4/6] Writing router.py..."

cat > router.py << 'EOF'
from fastapi import FastAPI, Request
import requests

app = FastAPI()

OLLAMA_URL = "http://127.0.0.1:11434/v1/chat/completions"

def choose_model(prompt: str) -> str:
    p = prompt.lower()

    coding = [
        "fix", "bug", "error", "stack trace",
        "refactor", "implement", "code",
        "class", "function", "debug"
    ]

    research = [
        "design", "architecture", "explain",
        "why", "what is", "system", "analysis"
    ]

    if any(k in p for k in coding):
        return "qwen2.5-coder:14b"

    if any(k in p for k in research):
        return "qwen3.6"

    return "qwen2.5-coder:14b"


@app.post("/v1/chat/completions")
async def chat(req: Request):
    body = await req.json()

    messages = body.get("messages", [])
    prompt = " ".join([m.get("content", "") for m in messages])

    model = choose_model(prompt)

    payload = {
        "model": model,
        "messages": messages,
        "stream": body.get("stream", False),
        "temperature": body.get("temperature", 0.2)
    }

    print("MODEL USED:", model)

    r = requests.post(OLLAMA_URL, json=payload, timeout=600)
    return r.json()
EOF

# -----------------------------
# 3. check Ollama models
# -----------------------------
echo "[5/6] Checking Ollama models..."

if command -v ollama >/dev/null 2>&1; then
    echo "Ollama found"
    echo "Pulling models (if missing)..."

    ollama pull qwen3.6 || true
    ollama pull qwen2.5-coder:14b || true
else
    echo "WARNING: Ollama not installed"
fi

# -----------------------------
# 4. instructions
# -----------------------------
echo "[6/6] Done!"

cat << 'EOF'

== NEXT STEPS ==

Start router:
  cd ~/ai-router
  source .venv/bin/activate
  uvicorn router:app --host 127.0.0.1 --port 8080

Fish shell function:

function cc
    set -e ANTHROPIC_API_KEY
    set -e ANTHROPIC_BASE_URL
    set -e CLAUDE_CODE_OAUTH_TOKEN
    set -e CLAUDE_SESSION

    set -lx ANTHROPIC_BASE_URL http://127.0.0.1:8080/v1
    set -lx ANTHROPIC_API_KEY ollama
    set -lx OLLAMA_NUM_CTX 8192

    claude
end

Test:
  cc

EOF
