# Managing Models

Three model backends, each with a specific role in the dev workflow. Claude handles the bulk of coding tasks; Ollama covers local/private work; NIM is for specialized NVIDIA models.

---

## Claude (Anthropic)

**Primary backend.** Used through Claude Code CLI and via LiteLLM in Open WebUI.

**Requires:** Anthropic API key + LiteLLM running (Step 2).

1. Get your key at https://console.anthropic.com
2. Add to `.env`: `ANTHROPIC_API_KEY=sk-ant-...`
3. Models are pre-configured in `config/litellm.yaml.example`

| Alias in UI       | Model                     | Best for                        |
|-------------------|---------------------------|---------------------------------|
| `claude-sonnet`   | claude-sonnet-4-6         | Default — coding, reasoning     |
| `claude-opus`     | claude-opus-4-7           | Complex architecture, long tasks |
| `claude-haiku`    | claude-haiku-4-5-20251001 | Fast edits, quick lookups       |

No download needed. Billed to your Anthropic account.

---

## Ollama (local)

**Local inference.** Best for privacy-sensitive code, offline work, or experimenting with open models.

**Requires:** Ollama installed on the host.

### Pull a model

```bash
ollama pull <model-name>
```

### Recommended models for development

| Model                 | Size   | Best for                          |
|-----------------------|--------|-----------------------------------|
| `qwen2.5-coder:14b`  | 9.0 GB | Code generation and completion    |
| `qwen3:14b`          | 9.3 GB | General reasoning and planning    |
| `nomic-embed-text`   | 274 MB | Embeddings for RAG / code search  |
| `qwen2.5-coder:7b`  | 4.7 GB | Lighter option for low-RAM machines |

> For machines with less than 16 GB RAM, use 7b variants.

### Register a new model in LiteLLM

After pulling, add an entry to `config/litellm.yaml` and restart:

```yaml
- model_name: my-model
  litellm_params:
    model: ollama/model-name
    api_base: http://host.docker.internal:11434
```

```bash
docker compose restart litellm
```

### Useful Ollama commands

```bash
ollama list              # show downloaded models
ollama pull <model>      # download
ollama rm <model>        # remove
ollama ps                # show currently loaded model
```

---

## NVIDIA NIM

**Specialized NVIDIA models.** Useful for OCR on documents/specs and exploring Nemotron models for coding tasks.

**Requires:** NVIDIA GPU + NGC API key + LiteLLM running.
**Platform:** Windows / Linux only.

See [docs/nim.md](nim.md) for full setup.

### Practical models for RTX 4070 Ti Super (16 GB VRAM)

| Model                            | VRAM | Dev use case                       |
|----------------------------------|------|------------------------------------|
| `llama-3.1-nemotron-nano-8b-v1` | 8 GB | Code reasoning, local alternative  |
| `nemotron-ocr`                   | 8 GB | Extract text from PDFs, screenshots |
