# Step 2 — Add LiteLLM

LiteLLM becomes the single model gateway. Open WebUI stops talking to Ollama directly and routes everything through LiteLLM instead.

## Why

- One endpoint for Ollama, NVIDIA NIM, and cloud APIs
- Model aliasing and fallbacks
- Usage logging and rate limiting
- Easy to add/remove backends without touching Open WebUI

## Steps

### 1. Create the LiteLLM config

```bash
cp config/litellm.yaml.example config/litellm.yaml
```

Edit `config/litellm.yaml` if needed (model names, ports).

### 2. Add `LITELLM_MASTER_KEY` to `.env`

```bash
# .env
LITELLM_MASTER_KEY=sk-local
```

Use any string — this is a local-only install.

### 3. Uncomment LiteLLM in docker-compose.yml

In `docker-compose.yml`, uncomment the `litellm` service block.

### 4. Update Open WebUI to use LiteLLM

In `docker-compose.yml`, under the `open-webui` service, comment out `OLLAMA_BASE_URL` and uncomment:

```yaml
- OPENAI_API_BASE_URL=http://litellm:4000/v1
- OPENAI_API_KEY=${LITELLM_MASTER_KEY}
```

### 5. Restart the stack

```bash
docker compose down
docker compose up -d
```

### 6. Verify

- Visit http://localhost:3000
- Models should appear in the model selector (sourced from LiteLLM)
- LiteLLM admin UI: http://localhost:4000/ui

## Troubleshooting

**Models not showing in Open WebUI:** Check LiteLLM logs with `docker compose logs -f litellm`. Confirm Ollama is running on the host with `ollama list`.

**Connection refused to Ollama:** On Windows/Mac Docker Desktop, `host.docker.internal` resolves automatically. On Linux, ensure `extra_hosts: host.docker.internal:host-gateway` is in the compose file (already included).
