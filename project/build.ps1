#
# Apache License 2.0.
# Copyright (c) 2026 OTMC Softwares.
# Contributors: Nguyen Van Trung, OTMC Contributors.
#

param(
    [Alias('f')]
    [switch]$Frontend,

    [Alias('b')]
    [switch]$Backend,

    [Alias('a')]
    [switch]$All
)

. $PSScriptRoot/utils.ps1
EnsureTopDirectory


$BUILD_FRONTEND    = $Frontend -or $All
$BUILD_BACKEND     = $Backend -or $All

if (-not $BUILD_FRONTEND -and -not $BUILD_BACKEND) {
    $BUILD_FRONTEND = $true
}

Write-Host "+++ 📚 Welcome to Project Builder +++" -ForegroundColor Cyan
if ($BUILD_FRONTEND) {
    Set-Location $TOP/frontend
    Log-Step "🌿 Building Frontend..."
    npm run build
    Error-Handler $LASTEXITCODE
    Log-Success "Frontend built successfully."
}

if ($BUILD_BACKEND) {
    Set-Location $TOP/backend
    Log-Step "🌿 Building Backend..."
    go build -o ./data/main.exe
    Error-Handler $LASTEXITCODE
    Log-Success "Backend built successfully."
}

