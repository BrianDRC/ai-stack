# setup.ps1 — Windows (PowerShell)
# Run once per machine to verify prerequisites and start the stack.
# Run as Administrator if Docker commands require elevated permissions.
$ErrorActionPreference = "Stop"

Write-Host "=== AI Stack Setup ===" -ForegroundColor Cyan
Write-Host ""

# ── Check prerequisites ────────────────────────────────────────
$fail = $false

if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Host "x Docker not found. Install from https://docs.docker.com/desktop/install/windows-install/" -ForegroundColor Red
    $fail = $true
} else {
    Write-Host "v Docker: $(docker --version)" -ForegroundColor Green
}

if (-not (Get-Command ollama -ErrorAction SilentlyContinue)) {
    Write-Host "x Ollama not found. Install from https://ollama.com/download" -ForegroundColor Red
    $fail = $true
} else {
    Write-Host "v Ollama: $(ollama --version)" -ForegroundColor Green
}

if ($fail) {
    Write-Host ""
    Write-Host "Fix the above issues and re-run this script." -ForegroundColor Red
    exit 1
}

Write-Host ""

# ── Environment file ──────────────────────────────────────────
$rootDir = Split-Path -Parent $PSScriptRoot

Set-Location $rootDir

if (-not (Test-Path ".env")) {
    Copy-Item ".env.example" ".env"
    Write-Host "Created .env from .env.example — set a strong WEBUI_SECRET_KEY before use." -ForegroundColor Yellow
} else {
    Write-Host "v .env exists" -ForegroundColor Green
}

Write-Host ""

# ── Start stack ───────────────────────────────────────────────
Write-Host "Starting Docker services..."
docker compose up -d

Write-Host ""
Write-Host "=== Stack is running ===" -ForegroundColor Green
Write-Host ""
Write-Host "  Open WebUI:  http://localhost:3000"
Write-Host ""
Write-Host "Next steps:"
Write-Host "  - Add models:   see docs/models.md"
Write-Host "  - Add LiteLLM:  see docs/litellm.md"
