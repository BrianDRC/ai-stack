# AI Stack — Local Installation Guide

Local AI environment built around three model backends, unified through Open WebUI and LiteLLM.

## Model Backends

| Backend          | Purpose                              | When to use                        |
|------------------|--------------------------------------|------------------------------------|
| Claude (Anthropic) | Primary AI — complex reasoning, coding, writing | Default for most tasks |
| Ollama           | Local, private, offline inference    | Privacy-sensitive or offline work  |
| NVIDIA NIM       | NVIDIA-optimized models (Nemotron, OCR, multimodal) | Exploration, specialized tasks |

## What This Installs

| Service     | Purpose                                   | Port  |
|-------------|-------------------------------------------|-------|
| Open WebUI  | Unified chat interface for all backends   | 3000  |
| LiteLLM     | Model router — single endpoint for all backends | 4000 |

> Ollama runs natively on the host (not in Docker).

---

## Prerequisites (manual, one-time per machine)

### 1. Docker Desktop
- **Windows:** https://docs.docker.com/desktop/install/windows-install/
- **macOS:** https://docs.docker.com/desktop/install/mac-install/

Verify: `docker --version`

### 2. Ollama
Download and install from https://ollama.com/download

Verify: `ollama --version`

### 3. NVIDIA Container Toolkit (Windows only, optional)
Required only for NVIDIA NIM. Enables GPU passthrough into Docker containers.

Verify GPU in Docker:
```bash
docker run --rm --gpus all nvidia/cuda:12.9.0-base-ubuntu22.04 nvidia-smi
```

> **Mac note:** Apple Silicon runs Ollama via Metal automatically. NVIDIA NIM is not supported on Mac.

---

## Installation

### 1. Clone this repo

```bash
git clone https://github.com/BrianDRC/ai-stack.git
cd ai-stack
```

### 2. Configure environment

```bash
cp .env.example .env
```

Open `.env` and fill in:
- `WEBUI_SECRET_KEY` — any random string
- `ANTHROPIC_API_KEY` — your Anthropic API key (from https://console.anthropic.com)

### 3. Run setup

**macOS / Linux:**
```bash
chmod +x scripts/setup.sh && ./scripts/setup.sh
```

**Windows (PowerShell):**
```powershell
.\scripts\setup.ps1
```

### 4. Open the interface

Visit http://localhost:3000

The stack is ready. See [docs/models.md](docs/models.md) to add models to each backend.

---

## Roadmap

| Step | What                              | Guide                   |
|------|-----------------------------------|-------------------------|
| 1    | Open WebUI (done)                 | This file               |
| 2    | LiteLLM — unified model router    | [docs/litellm.md](docs/litellm.md) |
| 3    | NVIDIA NIM                        | [docs/nim.md](docs/nim.md)         |
| 4    | MCP Servers + agent wiring        | Planned                 |

---

## Platform Notes

| Feature              | Windows (NVIDIA) | macOS (Apple Silicon) | macOS (Intel) |
|----------------------|------------------|-----------------------|---------------|
| Claude (Anthropic)   | Yes              | Yes                   | Yes           |
| Ollama GPU accel.    | CUDA             | Metal (automatic)     | CPU only      |
| NVIDIA NIM           | Supported        | Not supported         | Not supported |
| 14B local models     | Fast             | Good                  | Slow          |

---

## Useful Commands

```bash
# Start stack
docker compose up -d

# Stop stack
docker compose down

# View logs
docker compose logs -f open-webui

# Update Open WebUI to latest
docker compose pull open-webui && docker compose up -d open-webui

# Check status
docker compose ps
```
