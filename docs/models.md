# Managing Models

This stack supports three model backends. Each is independent — use one or all of them simultaneously through Open WebUI once LiteLLM is running (Step 2).

---

## Claude (Anthropic)

**Requires:** Anthropic API key and LiteLLM running (Step 2).

1. Get your API key at https://console.anthropic.com
2. Add to `.env`:
   ```
   ANTHROPIC_API_KEY=sk-ant-...
   ```
3. Models are pre-configured in `config/litellm.yaml.example`:

| Model name in UI  | Actual model              | Best for                     |
|-------------------|---------------------------|------------------------------|
| `claude-sonnet`   | claude-sonnet-4-6         | Default — balanced            |
| `claude-opus`     | claude-opus-4-7           | Complex reasoning, long tasks |
| `claude-haiku`    | claude-haiku-4-5-20251001 | Fast, lightweight tasks       |

No download required. Usage is billed to your Anthropic account.

---

## Ollama (local)

**Requires:** Ollama installed on the host machine.

### Pull a model

```bash
ollama pull <model-name>
```

### Recommended models

| Model                  | Size   | Best for              |
|------------------------|--------|-----------------------|
| `qwen3:14b`            | 9.3 GB | General reasoning      |
| `qwen2.5-coder:14b`   | 9.0 GB | Code generation        |
| `nomic-embed-text`     | 274 MB | Embeddings (RAG)       |
| `qwen3:8b`             | 5.2 GB | Lighter alternative    |
| `gemma3:12b`           | 8.1 GB | Google's model         |

> For machines with less than 16 GB RAM, prefer 7b/8b variants.

### Register a new model in LiteLLM

After pulling, add an entry to `config/litellm.yaml`:

```yaml
- model_name: my-model-alias
  litellm_params:
    model: ollama/model-name
    api_base: http://host.docker.internal:11434
```

Then restart LiteLLM: `docker compose restart litellm`

### Useful Ollama commands

```bash
ollama list              # show downloaded models
ollama pull <model>      # download a model
ollama rm <model>        # remove a model
ollama ps                # show currently loaded model
```

---

## NVIDIA NIM

**Requires:** NVIDIA GPU, NVIDIA Container Toolkit, NGC API key, LiteLLM running.  
**Platform:** Windows / Linux only. Not available on macOS.

See [docs/nim.md](nim.md) for full setup instructions.

### Available NIM models (RTX 4070 Ti Super — 16 GB VRAM)

| Model                              | VRAM  | Use case                  |
|------------------------------------|-------|---------------------------|
| `llama-3.1-nemotron-nano-8b-v1`   | 8 GB  | General reasoning          |
| `nemotron-ocr`                     | 8 GB  | Document / image OCR       |
| `llama-3.3-nemotron-super-49b-v1` | 40 GB | Too large for single GPU   |

Once a NIM container is running, register it in `config/litellm.yaml` under the NIM section.
