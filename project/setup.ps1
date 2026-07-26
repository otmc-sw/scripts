#
# Apache License 2.0.
# Copyright (c) 2026 OTMC Softwares.
# Contributors: Nguyen Van Trung, OTMC Contributors.
#

. $PSScriptRoot/utils.ps1
EnsureTopDirectory

try {
    Write-Host "### 💻 Setting up Frontend ..." -ForegroundColor Green
    Set-Location $TOP/frontend
    npm install
    npm audit fix

    Write-Host "### 🧪 Setting up Playwright ..." -ForegroundColor Green
    Set-Location $TOP/tests/playwright
    npm install
    npm audit fix
} finally {
    Set-Location $TOP
}