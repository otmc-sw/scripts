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
Write-Host "### 🌿 Building project..." -ForegroundColor Blue

if ($Frontend -or $All) {
    Set-Location $TOP/frontend
    Write-Host "### 🌿 Building Frontend..." -ForegroundColor Yellow
    npm run build
    if ($LASTEXITCODE -ne 0) {
        Write-Host ">>> ❌ Frontend build failed." -ForegroundColor Red
    } else {
        Write-Host ">>> ✅ Frontend built successfully." -ForegroundColor Green
    }
}

if ($Backend -or $All) {
    Set-Location $TOP/backend
    Write-Host "### 🌿 Building Backend..." -ForegroundColor Yellow
    go build -o ./data/authenticator
    if ($LASTEXITCODE -ne 0) {
        Write-Host ">>> ❌ Backend build failed." -ForegroundColor Red
    } else {
        Write-Host ">>> ✅ Backend built successfully." -ForegroundColor Green
    }
}
