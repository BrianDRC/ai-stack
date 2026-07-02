# setup.ps1 - Windows (PowerShell)
# Run once per machine to verify prerequisites and start the stack.
# Run as Administrator if Docker commands require elevated permissions.
$ErrorActionPreference = "Stop"

Write-Host "=== AI Stack Setup ===" -ForegroundColor Cyan
Write-Host ""

# -- Check prerequisites --------------------------------------------
# Auto-installs via winget where possible so a fresh machine only needs
# this script run once. Falls back to a manual-install message if winget
# is unavailable or the install fails.
$fail = $false
$hasWinget = [bool](Get-Command winget -ErrorAction SilentlyContinue)

function Install-Prereq {
    param($Name, $Command, $WingetId, $ManualUrl)

    if (Get-Command $Command -ErrorAction SilentlyContinue) {
        Write-Host "v ${Name}: $(& $Command --version)" -ForegroundColor Green
        return $true
    }

    if ($hasWinget) {
        Write-Host "... ${Name} not found. Installing via winget ($WingetId)..." -ForegroundColor Yellow
        winget install --id $WingetId --source winget --accept-source-agreements --accept-package-agreements -e | Out-Null
        # Refresh PATH for the current session so newly installed CLIs are visible.
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
    }

    if (Get-Command $Command -ErrorAction SilentlyContinue) {
        Write-Host "v ${Name} installed: $(& $Command --version)" -ForegroundColor Green
        return $true
    }

    Write-Host "x ${Name} not found and could not be auto-installed. Install manually from $ManualUrl" -ForegroundColor Red
    return $false
}

if (-not (Install-Prereq -Name "Docker" -Command "docker" -WingetId "Docker.DockerDesktop" -ManualUrl "https://docs.docker.com/desktop/install/windows-install/")) { $fail = $true }
if (-not (Install-Prereq -Name "Ollama" -Command "ollama" -WingetId "Ollama.Ollama" -ManualUrl "https://ollama.com/download")) { $fail = $true }
if (-not (Install-Prereq -Name "Node.js" -Command "node" -WingetId "OpenJS.NodeJS.LTS" -ManualUrl "https://nodejs.org/en/download")) { $fail = $true }

if ($fail) {
    Write-Host ""
    Write-Host "Fix the above issues (may require restarting the terminal after install) and re-run this script." -ForegroundColor Red
    exit 1
}

Write-Host ""

# -- PowerShell execution policy ---------------------------------------
# npm/npx ship as .ps1 wrapper scripts on Windows. The default "Restricted"
# policy blocks them, which breaks any npx-based MCP server. RemoteSigned
# only affects the current user and still requires downloaded scripts to
# be signed, so it's safe to set unattended.
$currentPolicy = Get-ExecutionPolicy -Scope CurrentUser
if ($currentPolicy -eq "Restricted" -or $currentPolicy -eq "Undefined") {
    Write-Host "... CurrentUser execution policy is '$currentPolicy'. Setting to RemoteSigned so npm/npx work..." -ForegroundColor Yellow
    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force
    Write-Host "v Execution policy set to RemoteSigned (CurrentUser)" -ForegroundColor Green
} else {
    Write-Host "v Execution policy: $currentPolicy" -ForegroundColor Green
}

Write-Host ""

# -- Environment file -------------------------------------------------
$rootDir = Split-Path -Parent $PSScriptRoot

Set-Location $rootDir

if (-not (Test-Path ".env")) {
    Copy-Item ".env.example" ".env"
    Write-Host "Created .env from .env.example - set a strong WEBUI_SECRET_KEY before use." -ForegroundColor Yellow
} else {
    Write-Host "v .env exists" -ForegroundColor Green
}

Write-Host ""

# -- Start stack --------------------------------------------------------
Write-Host "Starting Docker services..."
docker compose up -d

Write-Host ""
Write-Host "=== Stack is running ===" -ForegroundColor Green
Write-Host ""
Write-Host "  Open WebUI:  http://localhost:3000"
Write-Host ""
Write-Host "Next steps:"
Write-Host "  - Add models:      see docs/models.md"
Write-Host "  - Add LiteLLM:     see docs/litellm.md"
Write-Host "  - Add MCP servers: see docs/mcp.md"
