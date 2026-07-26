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

$COLOR_BACKEND  = 'DarkBlue'
$COLOR_FRONTEND = 'DarkGreen'
$COLOR_SUB      = 'DarkGray'
$DO_FRONTEND    = $Frontend -or $All
$DO_BACKEND     = $Backend -or $All

if (-not $DO_FRONTEND -and -not $DO_BACKEND) {
    $DO_BACKEND = $true
}

Clear-Host
$ErrorActionPreference = "Stop"

function Write-Step($text) {
    Write-Host ""
    Write-Host "====================================================================" -ForegroundColor DarkGray
    Write-Host "   $text" -ForegroundColor Cyan
    Write-Host "====================================================================" -ForegroundColor DarkGray
}

function Run($command) {
    Write-Host ""
    Write-Host ">> $command" -ForegroundColor Blue
    Invoke-Expression $command
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: Run failed with exit code $LASTEXITCODE" -ForegroundColor Red
        exit $LASTEXITCODE
    }
}

try {
    if ($DO_FRONTEND) {
        Set-Location frontend
        Write-Step "Step 1/5 : Remove ESLint"
        Run "npm uninstall eslint @eslint/js typescript-eslint eslint-plugin-react-hooks eslint-plugin-react-refresh"

        Write-Step "Step 2/5 : Check Available Updates"
        Run "npx npm-check-updates"
        Write-Host ""
        Write-Host "Review the upgrade list above." -ForegroundColor Yellow
        $answer = Read-Host "Continue? (Y/N)"
        if ($answer -notin @("Y","y")) {
            Write-Host ""
            Write-Host "Cancelled." -ForegroundColor Yellow
            exit
        }

        Write-Step "Step 3/5 : Upgrade package.json"
        Run "npx npm-check-updates -u"

        Write-Step "Step 4/5 : Install Packages"
        Run "npm install"

        Write-Step "Step 5/5 : Build"
        Run "npm run build"
    }

    if ($DO_BACKEND) {
        Set-Location backend

        Write-Step "Step 1/4 : Check Available Updates"
        Write-Host ""
        Write-Host "Checking for Go module updates..." -ForegroundColor Yellow
        $updatesOutput = Run "go list -u -m all 2>&1"
        Write-Host ""
        Write-Host "Review the upgrade list above." -ForegroundColor Yellow
        Write-Host "Modules with '[' indicate available updates." -ForegroundColor Yellow
        Write-Host ""
        $answer = Read-Host "Continue? (Y/N)"

        if ($answer -notin @("Y","y")) {
            Write-Host ""
            Write-Host "Cancelled." -ForegroundColor Yellow
            exit
        }

        Write-Step "Step 2/4 : Upgrade go.mod"
        Run "go get -u ./..."

        Write-Step "Step 3/4 : Tidy Modules"
        Run "go mod tidy"


        Write-Step "Step 4/4 : Build"
        Run "go build -o bin/server.exe ."
    }
}
finally {
    Set-Location $TOP
}