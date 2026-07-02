# AI Stack — Software Development Environment

Local AI stack built for software development. Claude Code is the primary interface for coding and automation. Open WebUI provides a secondary interface for local model exploration.

## Primary Interface

**Claude Code** (CLI / VS Code extension) — handles file editing, git, shell commands, and multi-step dev tasks directly. Install separately from https://claude.ai/code.

## Model Backends

| Backend            | Role                                      | When to use                          |
|--------------------|-------------------------------------------|--------------------------------------|
| Claude (Anthropic) | Primary — coding, reasoning, PR generation | Default for all dev tasks            |
| Ollama             | Local inference                           | Privacy-sensitive code, offline work |
| NVIDIA NIM         | Specialized NVIDIA models                 | OCR on docs, Nemotron exploration    |

## What This Repo Installs

| Service    | Purpose                                         | Port |
|------------|-------------------------------------------------|------|
| Open WebUI | Secondary interface — local model chat          | 3000 |
| LiteLLM    | Model router — single endpoint for all backends | 4000 |

> Ollama runs natively on the host (not in Docker).

---

## Prerequisites (one-time per machine)

### 1. Claude Code
Install from https://claude.ai/code. This is the primary dev interface.

For VS Code integration: install the **Claude Code extension** from the VS Code marketplace.

### 2. Docker Desktop
- **Windows:** https://docs.docker.com/desktop/install/windows-install/
- **macOS:** https://docs.docker.com/desktop/install/mac-install/

Verify: `docker --version`

### 3. Ollama
Download from https://ollama.com/download

Verify: `ollama --version`

### 4. Node.js (needed for MCP Servers, step 3)
Not required up front — `scripts/setup.ps1` / `scripts/setup.sh` detect and auto-install it for
you (via winget on Windows, Homebrew on macOS) when you run the setup script. See
[docs/mcp.md](docs/mcp.md) for the full walkthrough.

### 5. NVIDIA Container Toolkit (Windows only, optional)
Required for NVIDIA NIM. Enables GPU passthrough into Docker.

```bash
docker run --rm --gpus all nvidia/cuda:12.9.0-base-ubuntu22.04 nvidia-smi
```

> **Mac note:** NVIDIA NIM is not supported on Mac. Ollama runs via Metal automatically on Apple Silicon.

---

## Installation

### 1. Clone

```bash
git clone https://github.com/BrianDRC/ai-stack.git
cd ai-stack
```

### 2. Configure environment

```bash
cp .env.example .env
```

Fill in `.env`:
- `WEBUI_SECRET_KEY` — any random string
- `ANTHROPIC_API_KEY` — from https://console.anthropic.com

### 3. Start the stack

**macOS / Linux:**
```bash
chmod +x scripts/setup.sh && ./scripts/setup.sh
```

**Windows (PowerShell):**
```powershell
.\scripts\setup.ps1
```

### 4. Verify

- Open WebUI: http://localhost:3000
- Claude Code: run `claude` in any project directory

---

## Roadmap

| Step | What                           | Guide                              | Status  |
|------|--------------------------------|------------------------------------|---------|
| 1    | Infrastructure (WebUI + Ollama) | This file                         | Done    |
| 2    | LiteLLM — model router         | [docs/litellm.md](docs/litellm.md) | Done    |
| 3    | MCP Servers                    | [docs/mcp.md](docs/mcp.md)         | In progress (GitHub done) |
| 4    | NVIDIA NIM                     | [docs/nim.md](docs/nim.md)         | Planned |

---

## Platform Notes

| Feature             | Windows (NVIDIA) | macOS (Apple Silicon) |
|---------------------|------------------|-----------------------|
| Claude Code         | Yes              | Yes                   |
| Ollama GPU accel.   | CUDA             | Metal (automatic)     |
| NVIDIA NIM          | Supported        | Not supported         |
| 14B local models    | Fast             | Good                  |

---

## Useful Commands

```bash
# Start stack
docker compose up -d

# Stop stack
docker compose down

# View logs
docker compose logs -f open-webui

# Update Open WebUI
docker compose pull open-webui && docker compose up -d open-webui

# Stack status
docker compose ps
```
