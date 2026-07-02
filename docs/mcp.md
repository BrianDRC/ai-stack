# Step 3 — MCP Servers

MCP (Model Context Protocol) servers extend Claude Code with direct access to external tools and services. Instead of copy-pasting context, Claude can interact with GitHub, Docker, databases, and browsers as part of the dev workflow.

> Claude Code already handles filesystem and terminal natively. MCP servers add integrations that go beyond what the CLI can do on its own.

---

## Priority Order

| Priority | Server       | What it enables                                          |
|----------|--------------|----------------------------------------------------------|
| 1        | GitHub       | Create branches, open PRs, manage issues, review code    |
| 2        | Docker       | Start/stop containers, read logs, inspect services       |
| 3        | Browser      | Automate browsers, test UIs, scrape docs                 |
| 4        | Database     | Query databases during development and debugging         |
| 5        | VS Code      | Editor state, open files, diagnostics                    |
| 6        | Google Drive | Read specs, upload reports, manage project docs          |

---

## Installation

MCP servers are configured in Claude Code's settings file.

**Location:**
- **Windows:** `%APPDATA%\Claude\claude_desktop_config.json` (Desktop app) or `~/.claude/settings.json` (CLI)
- **macOS:** `~/Library/Application Support/Claude/claude_desktop_config.json` (Desktop app) or `~/.claude/settings.json` (CLI)

Each server is added as an entry under `mcpServers`.

---

## 1. GitHub MCP

Lets Claude create branches, open and review PRs, manage issues, and search repos.

**Requires:** GitHub Personal Access Token with `repo` scope.
Get one at: https://github.com/settings/tokens

```json
{
  "mcpServers": {
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "ghp_your_token_here"
      }
    }
  }
}
```

**What you can do:**
- "Create a branch `feature/auth` and open a draft PR"
- "Review the open PRs on repo X and summarize what needs attention"
- "Close issue #42 and reference it in the commit"

---

## 2. Docker MCP

Lets Claude inspect running containers, view logs, and manage services without leaving the dev context.

**Requires:** Docker Desktop running. The MCP server connects to the Docker socket.

```json
{
  "mcpServers": {
    "docker": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-docker"]
    }
  }
}
```

**What you can do:**
- "Check the logs of the litellm container for errors"
- "Restart the open-webui service"
- "List all running containers and their port mappings"

---

## 3. Browser (Playwright) MCP

Lets Claude open a real browser, navigate pages, fill forms, take screenshots, and test UIs.

**Requires:** Node.js installed.

```json
{
  "mcpServers": {
    "playwright": {
      "command": "npx",
      "args": ["-y", "@playwright/mcp@latest"]
    }
  }
}
```

**What you can do:**
- "Open localhost:3000 and take a screenshot of the model selector"
- "Run through the login flow and check for console errors"
- "Scrape the API docs at this URL and summarize the endpoints"

---

## 4. Database MCP

Lets Claude query databases directly during development and debugging.

**Requires:** Connection string to your database.

```json
{
  "mcpServers": {
    "postgres": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-postgres", "postgresql://user:pass@localhost/dbname"]
    }
  }
}
```

---

## Applying the Config

After editing the config file, restart Claude Code (or the Claude Desktop app).

Verify servers are loaded:
```bash
claude mcp list
```

---

## Notes

- MCP servers run as local processes on your machine — they are not containerized
- Each server only has access to what you configure (token scopes, DB connection strings, etc.)
- You can enable/disable individual servers without removing them from config
