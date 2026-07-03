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

Pull each with `ollama pull <model>` — the name in the table is the exact string to use.

| Model                    | Size    | Purpose                                          | MCP tool-calling (Open WebUI) |
|--------------------------|---------|---------------------------------------------------|--------------------------------|
| `devstral:24b`          | 14 GB   | **Best coding + tool-use combo.** Purpose-built for agentic coding tasks | Verified working |
| `gpt-oss:20b`           | 13.8 GB | General reasoning with reliable tool-calling; OpenAI's open model | Verified working |
| `qwen3:14b`             | 9.3 GB  | General reasoning and planning, smaller footprint than the two above | Verified working |
| `qwen2.5-coder:14b`     | 9.0 GB  | Code generation, completion, and fill-in-middle (FIM) — plain coding chat, not tool use | Verified **not** working — returns tool calls as plain text instead of executing them |
| `deepseek-coder-v2:16b` | 8.9 GB  | Code generation, 160K context — plain coding chat, not tool use | Verified **not** working — same failure mode as qwen2.5-coder:14b |
| `nomic-embed-text`      | 274 MB  | Embeddings for RAG / semantic code search         | N/A — embedding model, not a chat model |
| `qwen2.5-coder:7b`      | 4.7 GB  | Lighter code-completion option for machines with less RAM/VRAM | Untested |

**Bottom line for this scope:** use `devstral:24b` for coding tasks that need MCP tools (filesystem
access, etc.) — it's both code-focused and verified to actually execute tool calls, solving the gap
`qwen2.5-coder:14b` couldn't. Use `qwen3:14b` or `gpt-oss:20b` for general (non-code-specific)
tool-using chat. Reach for `qwen2.5-coder:14b` or `deepseek-coder-v2:16b` only for plain coding chat
where no tool calls are needed — verified across two separate coding models now that Ollama's own
"tools capable" tag doesn't predict actual tool-calling behavior; purpose-built agentic models
(`devstral`, `gpt-oss`) work reliably, repurposed code-completion models don't. `nomic-embed-text`
is required if you set up RAG/document search — it doesn't chat on its own.

> For machines with less than 16 GB RAM/VRAM, use the `7b` variants instead of `14b`/`20b`/`24b`.

### Register a new model in LiteLLM

After pulling, add an entry to `config/litellm.yaml` and restart:

```yaml
- model_name: my-model
  litellm_params:
    model: ollama_chat/model-name    # "ollama_chat/", not "ollama/" — needed for chat + tool calls
    api_base: http://host.docker.internal:11434
    num_ctx: 8192                    # avoids silently truncating tool definitions
  model_info:
    supports_function_calling: true  # only if you'll use this model with MCP tools in Open WebUI
```

```bash
docker compose restart litellm
```

> Skip `num_ctx` and `supports_function_calling` for embedding models (like `nomic-embed-text`) —
> those use the plain `ollama/` provider and don't do tool calls. See
> [docs/mcp.md](mcp.md#required-litellm-config-for-tool-calling-to-actually-work) for why these
> settings matter and how to verify a new model actually supports structured tool calls before
> relying on it.

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
