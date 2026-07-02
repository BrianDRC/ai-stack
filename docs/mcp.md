# Step 3 — MCP Servers

MCP (Model Context Protocol) servers give Claude direct access to outside tools and services —
GitHub, Docker, databases, browsers — instead of you copying information back and forth by hand.
Once set up, you can just ask Claude in plain English ("open a PR for this", "check the container
logs") and it does it for you.

> You do **not** need to know how to code to follow this guide. Every step is copy-paste or
> click-through. If a step fails, see [Troubleshooting](#troubleshooting) at the bottom.

---

## Before you start: run the setup script

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

## Priority Order

We're setting these up one at a time, most useful first.

| Priority | Server       | What it enables                                          |
|----------|--------------|----------------------------------------------------------|
| 1        | GitHub       | Create branches, open PRs, manage issues, review code    |
| 2        | Docker       | Start/stop containers, read logs, inspect services       |
| 3        | Browser      | Automate browsers, test UIs, scrape docs                 |
| 4        | Database     | Query databases during development and debugging         |
| 5        | VS Code      | Editor state, open files, diagnostics                    |
| 6        | Google Drive | Read specs, upload reports, manage project docs          |

---

## Where MCP servers are configured

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

## 1. GitHub MCP

Lets Claude create branches, open and review PRs, manage issues, and search your repos on your
behalf.

### Step 1 — Create a GitHub access token

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

### Step 2 — Add it to the config file

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

### Step 3 — Restart and verify

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

## 2. Docker MCP

Lets Claude inspect running containers, view logs, and manage services without you having to run
`docker` commands yourself.

> There is **no** official `@modelcontextprotocol/server-docker` npm package (an earlier version of
> this doc listed one that doesn't exist — if you see a 404 for that package, that's why). Instead,
> Docker Desktop ships its own built-in **MCP Toolkit**, which is the official, verified way to do
> this — safer than trusting a random third-party npm package with access to your Docker socket
> (which is effectively root-equivalent access to your machine).

**Requires:** Docker Desktop 4.62 or later (the setup script confirms Docker is installed, but not
this specific version — check `Docker Desktop → About` if the steps below look different from what
you see).

This is a one-time, click-through setup in the Docker Desktop app itself — nothing to type into
`claude_desktop_config.json` by hand:

1. Open **Docker Desktop**.
2. Click **MCP Toolkit** in the left sidebar.
3. Go to the **Catalog** tab, browse the available servers, and add the one(s) you want (e.g. for
   container management) to your profile.
4. Go to the **Clients** tab and click **Connect** next to **Claude Desktop**. This automatically
   writes the correct entry into `claude_desktop_config.json` for you — no manual editing needed.
5. Fully quit and reopen Claude (see the [tray/menu bar note above](#where-mcp-servers-are-configured)).
6. Verify: ask Claude something like *"list running Docker containers"*.

**What you can do (depending on which catalog servers you enable):**
- "Check the logs of the litellm container for errors"
- "Restart the open-webui service"
- "List all running containers and their port mappings"

Source: [Docker's official MCP Toolkit docs](https://docs.docker.com/ai/mcp-catalog-and-toolkit/toolkit/).

---

## 3. Browser (Playwright) MCP

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

## 4. Database MCP

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

## Putting it all together

A `claude_desktop_config.json` with all four servers configured (Windows) looks like this — the
key thing to notice is that all servers live inside the one `mcpServers` object, as separate
entries. `MCP_DOCKER` here is added automatically by Docker Desktop's Connect button (step 2
above) — you don't type that one in yourself:

```json
{
  "mcpServers": {
    "github": {
      "command": "cmd",
      "args": ["/c", "npx", "-y", "@modelcontextprotocol/server-github"],
      "env": { "GITHUB_PERSONAL_ACCESS_TOKEN": "github_pat_your_token_here", "NODE_OPTIONS": "--use-system-ca" }
    },
    "MCP_DOCKER": {
      "command": "docker",
      "args": ["mcp", "gateway", "run"]
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

## Troubleshooting

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

## Notes

- MCP servers run as local processes on your machine — they are not containerized.
- Each server only has access to what you configure (token scopes, DB connection strings, etc.).
- Tokens and connection strings live only in `claude_desktop_config.json` on your own machine —
  never commit this file or its contents to a git repository.
- You can remove a server at any time by deleting its entry from `mcpServers` and restarting the
  app.
