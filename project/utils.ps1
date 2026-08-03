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
    Write-Host ">>> 🎉 $Message`n" -ForegroundColor DarkGreen
}

function Log-Error {
    param (
        [string]$Message
    )
    Write-Host ">>> ❌ $Message" -ForegroundColor Red
}

function Log-Warning {
    param (
        [string]$Message
    )
    Write-Host ">>> ⚠️ $Message" -ForegroundColor Yellow
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
    Log-Warning $Message
}

function Run {
    param(
        [scriptblock]$Command
    )

    Write-Host "`n>> $Command" -ForegroundColor Blue
    & $Command
    Error-Handler $LASTEXITCODE
}

function EnsureTopDirectory() {
    if (-not $TOP) {
        Log-Error "Variable TOP is not defined."
        exit 1
    }

    Log-Step "🌿 Working directory: $TOP"
    Set-Location $TOP
}




