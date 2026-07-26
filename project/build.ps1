#
# Apache License 2.0.
# Copyright (c) 2026 OTMC Softwares.
# Contributors: Nguyen Van Trung, OTMC Contributors.
#

. $PSScriptRoot/utils.ps1
EnsureTopDirectory

param(
    [Alias('f')]
    [switch]$Frontend,

    [Alias('b')]
    [switch]$Backend,

    [Alias('a')]
    [switch]$All
)

Write-Host "+++ 📚 Welcome to Project Builder +++" -ForegroundColor Cyan
if ($Frontend -or $All) {
    Set-Location $TOP/frontend
    Log-Step "🌿 Building Frontend..."
    npm run build
    Error-Handler $LASTEXITCODE
    Log-Success "Frontend built successfully."
}

if ($Backend -or $All) {
    Set-Location $TOP/backend
    Log-Step "🌿 Building Backend..."
    go build -o ./data/main.exe
    Error-Handler $LASTEXITCODE
    Log-Success "Backend built successfully."
}

