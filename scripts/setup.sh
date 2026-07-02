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
# Auto-installs via Homebrew (macOS) where possible so a fresh machine only
# needs this script run once. Falls back to a manual-install message if
# Homebrew is unavailable (e.g. Linux) or the install fails.
fail=0
has_brew=0
command -v brew &>/dev/null && has_brew=1

install_prereq() {
  local name="$1" bin="$2" brew_cask="$3" manual_url="$4"

  if command -v "$bin" &>/dev/null; then
    echo -e "${GREEN}✓ $name:${NC} $("$bin" --version)"
    return 0
  fi

  if [ "$has_brew" -eq 1 ]; then
    echo -e "${YELLOW}… $name not found. Installing via Homebrew ($brew_cask)...${NC}"
    brew install --cask "$brew_cask" 2>/dev/null || brew install "$brew_cask"
  fi

  if command -v "$bin" &>/dev/null; then
    echo -e "${GREEN}✓ $name installed:${NC} $("$bin" --version)"
    return 0
  fi

  echo -e "${RED}✗ $name not found and could not be auto-installed.${NC} Install manually from $manual_url"
  return 1
}

install_prereq "Docker" "docker" "docker" "https://docs.docker.com/desktop/" || fail=1
install_prereq "Ollama" "ollama" "ollama" "https://ollama.com/download" || fail=1
install_prereq "Node.js" "node" "node" "https://nodejs.org/en/download" || fail=1

if [ $fail -ne 0 ]; then
  echo ""
  echo -e "${RED}Fix the above issues (may require restarting the shell after install) and re-run this script.${NC}"
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
echo "  - Add models:      see docs/models.md"
echo "  - Add LiteLLM:     see docs/litellm.md"
echo "  - Add MCP servers: see docs/mcp.md"
