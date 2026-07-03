# Step 3 — MCP Servers

MCP (Model Context Protocol) servers give an AI model direct access to outside tools and services
— files, GitHub, databases, browsers — instead of you copying information back and forth by hand.
Once set up, you can just ask in plain English ("list the files in this folder", "open a PR for
this") and it does it for you.

> You do **not** need to know how to code to follow this guide. Every step is copy-paste or
> click-through. If a step fails, see [Troubleshooting](#troubleshooting) at the bottom.

This doc covers **two separate setups** — they use different mechanisms and don't share config:

- **[Part A — Open WebUI](#part-a--mcp-for-open-webui)**: gives models used in Open WebUI chat
  (e.g. local Ollama models) access to tools like reading local files. This was the main reason
  MCP servers were needed for this project.
- **[Part B — Claude Desktop](#part-b--mcp-for-claude-desktop)**: gives Claude Code / Claude
  Desktop access to GitHub, browser automation, etc.

---

## Part A — MCP for Open WebUI

### Why this needs its own bridge

Open WebUI has *native* MCP support, but only for remote HTTP-based MCP servers (Admin Panel →
Settings → External Tools). A **local** MCP server — like one that reads files on your own
machine — talks over stdio (stdin/stdout as a local process), which native MCP support doesn't
cover. To bridge that, Open WebUI's own team built **`mcpo`**, a small proxy that wraps a local
MCP server and exposes it as a normal HTTP/OpenAPI service, which Open WebUI *can* connect to as
a "Tool Server."

### What's set up

- **`mcpo`** runs as a Docker service (see `docker-compose.yml`), wrapping the official
  **filesystem MCP server** (`@modelcontextprotocol/server-filesystem`).
- It's scoped to the `ai-stack` folder only — mounted **read-only** at the OS level
  (`volumes: - .:/projects:ro`), so even if a model tries to write or delete a file, the
  underlying mount blocks it regardless of what the model or MCP server attempts. This was a
  deliberate choice: Open WebUI does not reliably ask for confirmation before a model executes a
  tool call, unlike Claude Code.
- Protected by an API key (`MCPO_API_KEY` in `.env`).

### Setup steps

1. Run `docker compose up -d` from the `ai-stack` folder (or re-run `scripts/setup.ps1` /
   `scripts/setup.sh`, which calls this for you). Confirm it started:
   ```bash
   docker compose logs mcpo --tail 20
   ```
   You should see `Secure MCP Filesystem Server running on stdio` and
   `Uvicorn running on http://0.0.0.0:8000`.
2. Open Open WebUI (http://localhost:3000) → **Admin Panel → Settings → Connections** (labels
   may vary slightly by version — look for "Tools" or "External Tools" if "Connections" isn't
   there) → **Añadir Conexión / Add Connection**:
   - **Tipo/Type:** OpenAPI
   - **Nombre/Name:** FileSystem MCP
   - **URL:** `http://mcpo:8000` (the two containers share a Docker network, so the service name
     works — no need for `host.docker.internal` here)
   - **Autorización/Authorization:** Bearer, paste the `MCPO_API_KEY` value from `.env`
   - Save.
3. Fully quit and restart the Claude/Open WebUI stack isn't needed here — but do start a **new
   chat** in Open WebUI (existing chats may not pick up a newly added tool).
4. In the new chat: pick a model, enable the FileSystem MCP tool (wrench/tools icon near the
   message box), and ask something like *"list the files in this folder."*

### Required LiteLLM config for tool-calling to actually work

Getting a model to correctly *execute* a tool call (not just describe one in text) took several
fixes, all already applied in `config/litellm.yaml.example` — if you're setting this up on a new
machine, copy that file fresh rather than an old `litellm.yaml` to get these automatically:

1. **Use `ollama_chat/<model>`, not `ollama/<model>`.** The plain `ollama/` provider uses a
   simpler completion-style endpoint that doesn't return structured tool calls — the model ends up
   just printing a tool-call-shaped JSON blob as regular chat text instead of it actually being
   executed.
2. **Set `num_ctx: 8192`** (or higher) in `litellm_params`. Tool definitions take real context
   space — a realistic Open WebUI tool list (built-in tools like notes/calendar/automations, plus
   whatever MCP tools you've added) can easily run 2,000–6,000+ tokens. Ollama's small default
   context window **silently truncates** the prompt to fit, dropping tool definitions with no
   error message. The symptom looks exactly like "the model doesn't know about the tool," which
   is misleading — it never even saw it.
3. **Set `model_info: { supports_function_calling: true }`.** Ollama models aren't in LiteLLM's
   built-in capability database. Combined with `drop_params: true` (already set, needed for other
   reasons), LiteLLM can otherwise silently strip the `tools` parameter before it ever reaches
   Ollama.
4. **In Open WebUI, set Function Calling mode to "Native"** for the model/chat (Controls →
   Parámetros Avanzados → Modo de Llamada a Funciones → Nativo). The default "prompt-based" mode
   is not reliable for tool servers registered this way.
5. **Only one active connection per model.** Open WebUI can have both an "API OpenAI" connection
   (pointing at LiteLLM) and a separate "API Ollama" connection (pointing directly at Ollama)
   enabled at the same time. If both are on, models with the same name from each source collide,
   and Open WebUI may silently route straight to Ollama — bypassing LiteLLM (and all of the fixes
   above) entirely, with no error. Check **Admin Panel → Settings → Connections** and disable
   "API Ollama" if you only want traffic going through LiteLLM.

### Model choice matters — not every "tools capable" model works

Ollama tags both `qwen3:14b` and `qwen2.5-coder:14b` as supporting `tools` (`ollama show
<model>` → `capabilities`). In practice, only one of them reliably returns a structured
`tool_calls` response:

- **`qwen3:14b` — verified working.** Calling `POST /api/chat` on Ollama directly with a `tools`
  array returns a proper `message.tool_calls` array.
- **`qwen2.5-coder:14b` — verified NOT working.** The same direct test returns the tool call as
  plain text inside `message.content` (e.g. `{"name": "list_directory", "arguments": {...}}` as a
  string), with no `tool_calls` field at all — even though Ollama's own capability tag says it
  should work.

If tool-calling misbehaves with a model you add later, test it directly against Ollama first
(bypassing LiteLLM and Open WebUI) to isolate whether it's a model limitation:
```bash
curl -s http://localhost:11434/api/chat -d '{
  "model": "<model>",
  "messages": [{"role": "user", "content": "list files in /projects"}],
  "tools": [{"type":"function","function":{"name":"list_directory","description":"","parameters":{"type":"object","properties":{"path":{"type":"string"}},"required":["path"]}}}],
  "stream": false
}'
```
Look for a `tool_calls` array in the response. If it's missing and the JSON is inside `content`
as text instead, that model's Ollama template doesn't support structured tool calls — pick a
different model for tool-calling tasks.

---

## Part B — MCP for Claude Desktop

### Before you start: run the setup script

Everything below needs Node.js, and on Windows it also needs a small permission change. Both are
handled automatically — you don't need to install anything by hand.

1. Open a terminal in the `ai-stack` folder.
2. Run:
   - **Windows (PowerShell):** `.\scripts\setup.ps1`
   - **macOS / Linux:** `./scripts/setup.sh`
3. Watch the output. You should see green checkmarks (`v`) for Docker, Ollama, and Node.js. If
   something was missing, the script installs it for you automatically.

What this script does behind the scenes, in plain terms:
- Checks whether Docker, Ollama, and Node.js are installed. If any is missing, it downloads and
  installs it for you (using `winget` on Windows, `Homebrew` on macOS).
- **Windows only:** Node.js tools (`npm`, `npx`) are small helper scripts that Windows blocks by
  default for security reasons (this is called the "execution policy"). The script turns on the
  safe setting (`RemoteSigned`) that allows these specific tools to run, without lowering your
  overall security — scripts you download from the internet still need to be verified.

You only need to do this once per computer.

---

### Priority Order

We're setting these up one at a time, most useful first.

| Priority | Server       | What it enables                                          |
|----------|--------------|----------------------------------------------------------|
| 1        | GitHub       | Create branches, open PRs, manage issues, review code    |
| ~~2~~    | ~~Docker~~   | Skipped — see [Docker MCP](#2-docker-mcp-skipped) below  |
| 3        | Browser      | Automate browsers, test UIs, scrape docs                 |
| 4        | Database     | Query databases during development and debugging         |
| 5        | VS Code      | Editor state, open files, diagnostics                    |
| 6        | Google Drive | Read specs, upload reports, manage project docs          |

---

### Where MCP servers are configured

Every MCP server you add goes into one file, called `claude_desktop_config.json`. Think of it as
a settings list: each entry tells Claude "here's a tool you can use, and here's how to reach it."

**File location:**
- **Windows:** `%APPDATA%\Claude\claude_desktop_config.json`
  (paste that path into the Windows Explorer address bar to jump straight there)
- **macOS:** `~/Library/Application Support/Claude/claude_desktop_config.json`

Open it with any plain text editor (Notepad works fine). If the file doesn't exist yet, create it
with `{}` as the only content, then add servers as shown below.

**Important — after any change to this file:** fully quit the Claude desktop app (not just close
the window — right-click the icon in your taskbar/menu bar and choose Quit) and reopen it. Claude
only reads this file when it starts up.

Closing the window is **not** the same as quitting — like many desktop apps, Claude keeps running
in the system tray (Windows: the small arrow near the clock) / menu bar (macOS) after the window
closes. If you edit the config and reopen the window without quitting from the tray/menu bar icon
first, your changes won't take effect, and it'll look like the new server "isn't working" when
really it was never restarted.

---

### 1. GitHub MCP

Lets Claude create branches, open and review PRs, manage issues, and search your repos on your
behalf.

#### Step 1 — Create a GitHub access token

This is like a special password that only allows the specific things you approve (e.g. "read and
write to this one repo"), rather than your full GitHub login.

1. Go to https://github.com/settings/personal-access-tokens/new (you'll need to log into GitHub
   first if you aren't already).
2. **Token name:** anything you'll recognize later, e.g. `ai-stack-mcp`.
3. **Expiration:** pick something like 90 days rather than "No expiration" — you'll want to
   regenerate it periodically for security, the same way you'd change a password.
4. **Repository access:** choose "Only select repositories" and pick the repo(s) you want Claude
   to work with (e.g. `ai-stack`). You can add more repos later by editing the token.
5. Under **Permissions → Repository permissions**, set:
   - **Contents:** Read and write
   - **Issues:** Read and write
   - **Pull requests:** Read and write
   - **Metadata:** Read-only (this one is required and gets selected automatically)
6. Click **Generate token** at the bottom.
7. **Copy the token immediately** — it starts with `github_pat_...` and GitHub will only show it
   to you this one time. If you lose it, you'll need to generate a new one.

Treat this token like a password: don't share it, don't post it publicly, don't commit it to a
git repository.

#### Step 2 — Add it to the config file

Open `claude_desktop_config.json` (see [location above](#where-mcp-servers-are-configured)) and
add a `github` entry under `mcpServers`. If the file already has other content, merge this in
rather than replacing the whole file.

**Windows:**
```json
{
  "mcpServers": {
    "github": {
      "command": "cmd",
      "args": ["/c", "npx", "-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "github_pat_your_token_here",
        "NODE_OPTIONS": "--use-system-ca"
      }
    }
  }
}
```

> `NODE_OPTIONS: --use-system-ca` tells Node to trust the certificates Windows already trusts.
> Without it, antivirus or corporate software that inspects HTTPS traffic (common on Windows —
> Windows Defender, Kaspersky, corporate proxies, etc.) can make `npx` fail to download the
> package with an `UNABLE_TO_VERIFY_LEAF_SIGNATURE` error. Safe to include even if you don't hit
> the error.

**macOS / Linux:**
```json
{
  "mcpServers": {
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "github_pat_your_token_here"
      }
    }
  }
}
```

> **Why Windows uses `cmd /c npx` instead of just `npx`:** on Windows, `npx` is itself a small
> script, and depending on how the Claude app launches it, it can hit the same permission block
> mentioned above. Routing through `cmd /c` avoids that entirely, so it's the more reliable option
> on Windows.

Replace `github_pat_your_token_here` with the token you copied in Step 1.

#### Step 3 — Restart and verify

1. Fully quit and reopen the Claude desktop app (see note above).
2. Ask Claude something like: *"List the open pull requests on my ai-stack repo"* or *"What repos
   can you see?"*
3. If Claude responds with real data from GitHub, it's working. If not, see
   [Troubleshooting](#troubleshooting).

**What you can do once it's working:**
- "Create a branch `feature/auth` and open a draft PR"
- "Review the open PRs on repo X and summarize what needs attention"
- "Close issue #42 and reference it in the commit"

---

### 2. Docker MCP (skipped)

We looked into this and decided **not** to set up a dedicated Docker MCP server. Here's why, in
case this gets revisited later:

- There is **no** official `@modelcontextprotocol/server-docker` npm package (an earlier version
  of this doc listed one — it doesn't exist, so if you see a `404` for that package, that's why).
- Docker Desktop's own built-in **MCP Toolkit** (Sidebar → MCP Toolkit → Catalog) doesn't have a
  "manage my local containers" entry either — searching its 300+ server catalog for "container"
  only turns up unrelated things (e.g. a Cloudflare sandbox environment). Its catalog is for
  running *other* tools as sandboxed containers, not for exposing your own Docker Engine.
- The remaining option — a community npm package with access to your Docker socket (effectively
  root-equivalent access to your machine) from an unverified author — isn't worth the risk here.
- Most importantly: **it's redundant.** Claude Code already has direct terminal access on this
  machine, so `docker compose ps`, `docker compose logs`, `docker compose restart <service>`, etc.
  all just work today, no MCP server required. The whole point of MCP servers (see the top of this
  doc) is to reach things *beyond* what Claude's terminal access already covers — Docker container
  management doesn't clear that bar for a Claude Code–primary setup like this one.

If you ever run ai-stack through a Claude interface *without* terminal access (e.g. a hosted chat
UI), this reasoning wouldn't apply and it'd be worth revisiting.

---

### 3. Browser (Playwright) MCP

Lets Claude open a real browser, navigate pages, fill forms, take screenshots, and test UIs.

**Windows:**
```json
"playwright": {
  "command": "cmd",
  "args": ["/c", "npx", "-y", "@playwright/mcp@latest"],
  "env": { "NODE_OPTIONS": "--use-system-ca" }
}
```

**macOS / Linux:**
```json
"playwright": {
  "command": "npx",
  "args": ["-y", "@playwright/mcp@latest"]
}
```

**What you can do:**
- "Open localhost:3000 and take a screenshot of the model selector"
- "Run through the login flow and check for console errors"
- "Scrape the API docs at this URL and summarize the endpoints"

---

### 4. Database MCP

Lets Claude query databases directly during development and debugging.

**Requires:** a connection string to your database (ask whoever manages the database if you don't
have one — it looks like `postgresql://user:pass@localhost/dbname`).

**Windows:**
```json
"postgres": {
  "command": "cmd",
  "args": ["/c", "npx", "-y", "@modelcontextprotocol/server-postgres", "postgresql://user:pass@localhost/dbname"],
  "env": { "NODE_OPTIONS": "--use-system-ca" }
}
```

**macOS / Linux:**
```json
"postgres": {
  "command": "npx",
  "args": ["-y", "@modelcontextprotocol/server-postgres", "postgresql://user:pass@localhost/dbname"]
}
```

---

### Putting it all together

A `claude_desktop_config.json` with GitHub and Browser configured (Windows) looks like this — the
key thing to notice is that all servers live inside the one `mcpServers` object, as separate
entries (Docker MCP is intentionally omitted — see above):

```json
{
  "mcpServers": {
    "github": {
      "command": "cmd",
      "args": ["/c", "npx", "-y", "@modelcontextprotocol/server-github"],
      "env": { "GITHUB_PERSONAL_ACCESS_TOKEN": "github_pat_your_token_here", "NODE_OPTIONS": "--use-system-ca" }
    },
    "playwright": {
      "command": "cmd",
      "args": ["/c", "npx", "-y", "@playwright/mcp@latest"],
      "env": { "NODE_OPTIONS": "--use-system-ca" }
    }
  }
}
```

---

### Troubleshooting

**"npm/npx cannot be loaded because running scripts is disabled" (Windows):** the execution
policy fix didn't apply. Re-run `scripts/setup.ps1` — it sets this automatically. If it still
fails, open PowerShell and run:
```powershell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
```

**Claude doesn't seem to see the new tools after restarting:** double check you fully quit the
app (not just closed the window) before reopening it. Also check that your JSON is valid — a
missing comma or bracket will silently stop the whole file from loading. Paste the file contents
into a JSON validator (e.g. jsonlint.com) if you're not sure.

**GitHub commands fail with a permissions error:** your token likely doesn't have the right
repository selected, or is missing a permission (Contents / Issues / Pull requests). Go back to
https://github.com/settings/personal-access-tokens and edit the token, or generate a new one.

**"node/npm/npx not recognized" even after setup:** close and reopen your terminal window — a
newly installed program's location isn't picked up by terminals that were already open.

**MCP server log shows `UNABLE_TO_VERIFY_LEAF_SIGNATURE` (check `%APPDATA%\Claude\logs\mcp-server-<name>.log`
on Windows, `~/Library/Logs/Claude/mcp-server-<name>.log` on macOS):** `npx` couldn't verify the
certificate when downloading the package — usually caused by antivirus or corporate software that
inspects HTTPS traffic. Add `"NODE_OPTIONS": "--use-system-ca"` to that server's `env` block (see
the GitHub example above) so Node trusts the same certificates your OS does, then restart the app.

**MCP server log shows `404 Not Found` for `@modelcontextprotocol/server-docker`:** that package
doesn't exist — remove any `"docker"` entry using it from `claude_desktop_config.json` and follow
the [Docker MCP](#2-docker-mcp) steps above instead, which use Docker Desktop's built-in toolkit.

---

### Notes

- MCP servers run as local processes on your machine — they are not containerized.
- Each server only has access to what you configure (token scopes, DB connection strings, etc.).
- Tokens and connection strings live only in `claude_desktop_config.json` on your own machine —
  never commit this file or its contents to a git repository.
- You can remove a server at any time by deleting its entry from `mcpServers` and restarting the
  app.
