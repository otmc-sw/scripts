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

    [Alias('t')]
    [switch]$Test,

    [Alias('a')]
    [switch]$All
)

. $PSScriptRoot/utils.ps1
EnsureTopDirectory

$DO_FRONTEND    = $Frontend -or $All
$DO_BACKEND     = $Backend -or $All
$DO_TEST        = $Test -or $All

if (-not $DO_FRONTEND -and -not $DO_BACKEND -and -not $DO_TEST) {
    $DO_BACKEND = $true
}

$ErrorActionPreference = "Stop"

try {
    if ($DO_FRONTEND) {
        Set-Location frontend
        Log-Step "🧹 Step 1/5 : Remove ESLint"
        Run { npm uninstall eslint @eslint/js typescript-eslint eslint-plugin-react-hooks eslint-plugin-react-refresh }
        Run { Remove-Item eslint.config.js -Force -ErrorAction SilentlyContinue }

        Log-Step "🔍 Step 2/5 : Check Available Updates"
        Run { npx npm-check-updates }
        Write-Host ""
        Write-Host "Review the upgrade list above." -ForegroundColor Yellow
        $answer = Read-Host "Continue? (Y/N)"
        if ($answer -notin @("Y","y")) {
            Log-Warning "Cancelled."
            exit
        }

        Log-Step "🚀 Step 3/5 : Upgrade package.json"
        Run { npx npm-check-updates -u }

        Log-Step "📦 Step 4/5 : Install Packages"
        Run { Remove-Item package-lock.json -Force -ErrorAction SilentlyContinue }
        Run { npm install }

        Log-Step "🌿 Step 5/5 : Build"
        Run { npm run build }
    }

    if ($DO_BACKEND) {
        Set-Location backend

        Log-Step "📚 Step 1/5 : Get Direct Dependencies"
        $direct = Get-GoDirectDependencies
        Write-Host "Found $($direct.Count) direct dependencies." -ForegroundColor Cyan

        Log-Step "🔍 Step 2/5 : Check Available Updates"
        $updates = Get-GoModuleUpdates -DirectDependencies $direct
        Show-GoModuleUpdates -Updates $updates

        if (-not $updates -or $updates.Count -eq 0) {
            Write-Host "Nothing to upgrade." -ForegroundColor Yellow
            exit
        }

        $answer = Read-Host "Upgrade these packages? (Y/N)"
        if ($answer -notmatch '^[Yy]$') {
            Log-Warning "Cancelled."
            exit
        }

        Log-Step "📦 Step 3/5 : Upgrade Direct Dependencies"
        Update-GoModules -Updates $updates

        Log-Step "🧩 Step 4/5 : Tidy Modules"
        Run { go mod tidy }

        Log-Step "🌿 Step 5/5 : Build"
        Run { go build ./... }

        Log-Success "Backend dependencies upgraded successfully."
    }
    
    if ($Test) {
        Set-Location tests/playwright
        
        Log-Step "🔍 Step 1/4 : Check Available Updates"
        Run { npx npm-check-updates }
        Write-Host ""
        Write-Host "Review the upgrade list above." -ForegroundColor Yellow
        $answer = Read-Host "Continue? (Y/N)"
        if ($answer -notin @("Y","y")) {
            Log-Warning "Cancelled."
            exit
        }

        Log-Step "🚀 Step 2/4 : Upgrade package.json"
        Run { npx npm-check-updates -u }

        Log-Step "📦 Step 3/4 : Install Packages"
        Run { Remove-Item package-lock.json -Force -ErrorAction SilentlyContinue }
        Run { npm install }

        Log-Success "Playwright dependencies upgraded successfully."
    }
}
finally {
    Set-Location $TOP
}