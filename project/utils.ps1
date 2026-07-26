#
# Apache License 2.0
# Copyright (c) 2026 OTMC Softwares.
# Contributors: Nguyen Van Trung, Nguyen Thi Hoai, OTMC Contributors.
#

function Log-Step {
    param (
        [string]$Message
    )
    Write-Host "`n### $Message" -ForegroundColor DarkBlue
}

function Log-Success {
    param (
        [string]$Message
    )
    Write-Host ">>> ✅ $Message." -ForegroundColor DarkGreen
}

function Log-Error {
    param (
        [string]$Message
    )
    Write-Host "❌ $Message" -ForegroundColor Red
}

function Error-Handler {
    param (
        [int]$LastExitCode
    )
    
    if ($LastExitCode -ne 0) {
        Log-Error "Command failed with exit code $LastExitCode"
        exit $LastExitCode
    }
}

function Warning-Handler {
    param (
        [string]$Message
    )
    Write-Host "⚠️ $Message" -ForegroundColor Yellow
}

function Run($command) {
    Write-Host "`n>> $command" -ForegroundColor Blue
    Invoke-Expression $command
    Error-Handler $LASTEXITCODE
}

function EnsureTopDirectory() {
    if (-not $TOP) {
        Write-Error "ERROR: Variable TOP is not defined."
        exit 1
    }

    Write-Host "### 🌿 Working directory: $TOP" -ForegroundColor Blue
    Set-Location $TOP
}




