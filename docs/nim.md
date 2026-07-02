# Step 3 — Add NVIDIA NIM

NVIDIA NIM runs optimized inference containers for Nemotron and other NVIDIA models. Requires an NVIDIA GPU with CUDA support.

## Prerequisites

- NVIDIA GPU (RTX series recommended, 8 GB+ VRAM)
- NVIDIA Container Toolkit installed
- NVIDIA account at https://build.nvidia.com (free)
- LiteLLM running (Step 2 complete)

## Steps

### 1. Get your NGC API key

Log into https://build.nvidia.com → API Key → Generate.

Add to `.env`:
```bash
NGC_API_KEY=your_key_here
```

### 2. Authenticate Docker with NGC registry

```bash
echo "$NGC_API_KEY" | docker login nvcr.io -u '$oauthtoken' --password-stdin
```

### 3. Add a NIM service to docker-compose.yml

Example for Nemotron Nano (8B, fits in 8 GB VRAM):

```yaml
nim-nemotron-nano:
  image: nvcr.io/nim/nvidia/llama-3.1-nemotron-nano-8b-v1:latest
  container_name: nim-nemotron-nano
  restart: unless-stopped
  ports:
    - "8001:8000"
  environment:
    - NGC_API_KEY=${NGC_API_KEY}
  deploy:
    resources:
      reservations:
        devices:
          - driver: nvidia
            count: 1
            capabilities: [gpu]
  volumes:
    - nim-cache:/root/.cache/nim

volumes:
  nim-cache:
```

### 4. Register in LiteLLM config

In `config/litellm.yaml`, uncomment and adjust the NIM entry:

```yaml
- model_name: nemotron-nano
  litellm_params:
    model: openai/nvidia/llama-3.1-nemotron-nano-8b-v1
    api_base: http://nim-nemotron-nano:8000/v1
    api_key: nim-local
```

### 5. Restart the stack

```bash
docker compose down
docker compose up -d
```

## VRAM Requirements by Model

| Model                        | VRAM    |
|------------------------------|---------|
| Nemotron Nano 8B             | 8 GB    |
| Nemotron Super 49B           | 40 GB   |
| Nemotron Ultra 253B          | 200 GB+ |
| Nemotron OCR                 | 8 GB    |

> With 16 GB VRAM (RTX 4070 Ti Super), Nemotron Nano and Nemotron OCR are the practical options for single-GPU setups.

## Platform Compatibility

NIM is **Windows / Linux only**. macOS is not supported. Skip this step on Mac machines.
