#
# Apache License 2.0.
# Copyright (c) 2026 OTMC Softwares.
# Contributors: Nguyen Van Trung, OTMC Contributors.
#

. $PSScriptRoot/utils.ps1
EnsureTopDirectory

Set-Location $PSScriptRoot/..

try {
    Write-Host ">>> 💻 Setting up Frontend ..." -ForegroundColor Green
    Set-Location frontend
    npm install
    npm audit fix

    Write-Host ">>> 🧪 Setting up Playwright ..." -ForegroundColor Green
    Set-Location $PSScriptRoot/../tests/playwright
    npm install
    npm audit fix
} finally {
    Set-Location $PSScriptRoot/..
}