# AI Stack

Local AI dev stack: Open WebUI + LiteLLM + Ollama, with MCP servers and NVIDIA NIM as
in-progress additions. Machine-specific facts and secrets live in the parent
`E:/source/CLAUDE.md` (not this file — this one is committed to git).

## Repo Layout
- **Compose file:** `docker-compose.yml`
- **Env vars:** `.env` (gitignored — never commit; see machine-level values in the parent workstation `CLAUDE.md`)
- **LiteLLM config:** `config/litellm.yaml` (gitignored — copy from `config/litellm.yaml.example`)
- **Docs:** `docs/litellm.md`, `docs/mcp.md`, `docs/nim.md`, `docs/models.md`
- **Setup scripts:** `scripts/setup.sh` (Mac/Linux), `scripts/setup.ps1` (Windows)

## Current Stack
| Component   | Status      | Details                                                |
|-------------|-------------|---------------------------------------------------------|
| Claude Code | Running     | Via Claude desktop app — primary dev interface           |
| Docker      | Running     |                                                           |
| Open WebUI  | Running     | `localhost:3000` — volume: `open-webui`                  |
| LiteLLM     | Running     | `localhost:4000` — routes Ollama models to Open WebUI    |
| Ollama      | Running     | Native (host), port 11434                                |
| MCP Servers | In progress | GitHub done, Docker skipped, Browser/Database pending    |
| NVIDIA NIM  | Not started | NVIDIA account created, Docker GPU verified               |

## Target Architecture
```
Claude Code (desktop app)
        │
     LiteLLM  ◄── single model gateway (localhost:4000)
        │
  ┌─────┼──────────┐
  │     │          │
Ollama  NIM   Anthropic API (future)
        │
   MCP Servers
        │
GitHub · Docker · Browser · Database · Google Drive
```

## Roadmap
1. [x] Infrastructure — Open WebUI + Ollama
2. [x] LiteLLM — model router (Ollama models available in Open WebUI)
3. [ ] MCP Servers — GitHub (done) → ~~Docker (skipped, redundant with terminal access)~~ → Browser → Database (`docs/mcp.md`)
4. [ ] NVIDIA NIM (`docs/nim.md`)

## Model Strategy
| Backend                | Models                                          | When to use                      |
|-------------------------|--------------------------------------------------|-----------------------------------|
| Claude (subscription)   | Via Claude Code desktop app                      | All dev tasks — primary          |
| Ollama (local)          | qwen2.5-coder:14b, qwen3:14b, nomic-embed-text   | Local/private, Open WebUI chat   |
| NVIDIA NIM              | Nemotron Nano 8B, Nemotron OCR                   | Specialized tasks (Step 4)       |

## Key Decisions Made
- Claude Code used via **desktop app** (not terminal) — enables image pasting
- **No Anthropic API key** in LiteLLM — Claude subscription covers Claude Code separately
- LiteLLM routes **Ollama only** for now; Claude and NIM entries are commented out
- Ollama runs **natively on host**, not in Docker — models live on disk, not in containers
- Stack is entirely focused on **software development**
- No macOS Intel support — only Windows (NVIDIA) and macOS (Apple Silicon)

## Principles
- Claude Code is the primary interface — not Open WebUI
- LiteLLM is the single model gateway — nothing talks to Ollama/NIM directly
- All supporting services run in Docker; components are independently replaceable
- MCP servers extend Claude Code — install before NIM
- Modular architecture; avoid vendor lock-in

## Use Cases
Software dev automation · GitHub PRs · local file management · Docker management · PDF/OCR on specs and docs

## Start / Stop Stack
```bash
docker compose up -d    # start
docker compose down     # stop
docker compose ps       # status
```
