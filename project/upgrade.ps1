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

$DO_FRONTEND    = $Frontend -or $All
$DO_BACKEND     = $Backend -or $All

if (-not $DO_FRONTEND -and -not $DO_BACKEND) {
    $DO_BACKEND = $true
}

Clear-Host
$ErrorActionPreference = "Stop"

try {
    if ($DO_FRONTEND) {
        Set-Location frontend
        Log-Step "Step 1/5 : Remove ESLint"
        Run { npm uninstall eslint @eslint/js typescript-eslint eslint-plugin-react-hooks eslint-plugin-react-refresh }

        Log-Step "Step 2/5 : Check Available Updates"
        Run { npx npm-check-updates }
        Write-Host ""
        Write-Host "Review the upgrade list above." -ForegroundColor Yellow
        $answer = Read-Host "Continue? (Y/N)"
        if ($answer -notin @("Y","y")) {
            Write-Host ""
            Write-Host "Cancelled." -ForegroundColor Yellow
            exit
        }

        Log-Step "Step 3/5 : Upgrade package.json"
        Run { npx npm-check-updates -u }

        Log-Step "Step 4/5 : Install Packages"
        Run { npm install }

        Log-Step "Step 5/5 : Build"
        Run { npm run build }
    }

    if ($DO_BACKEND) {
        Set-Location backend

        Log-Step "Step 1/7 : Get Direct Dependencies"
        $direct = Get-GoDirectDependencies
        Write-Host "Found $($direct.Count) direct dependencies." -ForegroundColor Cyan

        Log-Step "Step 2/7 : Check Available Updates"
        $updates = Get-GoModuleUpdates -Dependencies $direct
        Show-GoModuleUpdates -Updates $updates

        if (-not $updates -or $updates.Count -eq 0) {
            Write-Host ""
            Write-Host "Nothing to upgrade." -ForegroundColor Yellow
            exit
        }

        Write-Host ""
        $answer = Read-Host "Upgrade these packages? (Y/N)"
        if ($answer -notmatch '^[Yy]$') {
            Write-Host ""
            Write-Host "Cancelled." -ForegroundColor Yellow
            exit
        }

        Log-Step "Step 3/7 : Upgrade Direct Dependencies"
        Update-GoModules -Updates $updates

        Log-Step "Step 4/7 : Tidy Modules"
        Run { go mod tidy }

        Log-Step "Step 5/7 : Build"
        Run { go build ./... }

        Log-Step "Step 6/7 : Test"
        $testFiles = Get-ChildItem -Filter "*_test.go" -Recurse
        if ($testFiles) {
            Run { go test ./... }
        } else {
            Log-Warning "No test files found. Skipping tests."
        }

        Log-Step "Step 7/7 : Done"
        Log-Success "Backend dependencies upgraded successfully."
    }
}
finally {
    Set-Location $TOP
}