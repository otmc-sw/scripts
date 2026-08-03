#
# Apache License 2.0.
# Copyright (c) 2026 OTMC Softwares.
# Contributors: Nguyen Van Trung, OTMC Contributors.
#

. $PSScriptRoot/utils.ps1
EnsureTopDirectory

try {
    Log-Step "💻 Setting up Frontend ..."
    Set-Location $TOP/frontend
    npm install
    Error-Handler $LASTEXITCODE
    Log-Success "Frontend setup completed."

    Log-Step "🧪 Setting up Playwright ..."
    Set-Location $TOP/tests/playwright
    npm install
    Error-Handler $LASTEXITCODE
    Log-Success "Playwright setup completed."
} finally {
    Set-Location $TOP
}