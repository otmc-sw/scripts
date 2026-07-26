#
# Apache License 2.0.
# Copyright (c) 2026 OTMC Softwares.
# Contributors: Nguyen Van Trung, OTMC Contributors.
#

. $PSScriptRoot/utils.ps1
EnsureTopDirectory

try {
    Log-Step "### 💻 Setting up Frontend ..."
    Set-Location $TOP/frontend
    npm install
    npm audit fix

    Log-Step "### 🧪 Setting up Playwright ..."
    Set-Location $TOP/tests/playwright
    npm install
    npm audit fix
} finally {
    Set-Location $TOP
}