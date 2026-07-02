#!/bin/bash
# setup.sh — macOS / Linux
# Run once per machine to verify prerequisites and start the stack.
set -e

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${CYAN}=== AI Stack Setup ===${NC}"
echo ""

# ── Check prerequisites ────────────────────────────────────────
fail=0

if ! command -v docker &>/dev/null; then
  echo -e "${RED}✗ Docker not found.${NC} Install from https://docs.docker.com/desktop/"
  fail=1
else
  echo -e "${GREEN}✓ Docker:${NC} $(docker --version)"
fi

if ! command -v ollama &>/dev/null; then
  echo -e "${RED}✗ Ollama not found.${NC} Install from https://ollama.com/download"
  fail=1
else
  echo -e "${GREEN}✓ Ollama:${NC} $(ollama --version)"
fi

if [ $fail -ne 0 ]; then
  echo ""
  echo -e "${RED}Fix the above issues and re-run this script.${NC}"
  exit 1
fi

echo ""

# ── Environment file ──────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$ROOT_DIR"

if [ ! -f .env ]; then
  cp .env.example .env
  echo -e "${YELLOW}Created .env from .env.example — set a strong WEBUI_SECRET_KEY before use.${NC}"
else
  echo -e "${GREEN}✓ .env exists${NC}"
fi

echo ""

# ── Start stack ───────────────────────────────────────────────
echo "Starting Docker services..."
docker compose up -d

echo ""
echo -e "${GREEN}=== Stack is running ===${NC}"
echo ""
echo "  Open WebUI:  http://localhost:3000"
echo ""
echo "Next steps:"
echo "  - Add models:   see docs/models.md"
echo "  - Add LiteLLM:  see docs/litellm.md"
