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

function Show-GoModuleUpdates {

    $modules = & go list -u -m all 2>&1

    Error-Handler $LASTEXITCODE

    $updates = foreach ($line in $modules) {
        if ($line -match '^(?<pkg>\S+)\s+(?<old>v\S+)\s+\[(?<new>[^\]]+)\]$') {
            [PSCustomObject]@{
                Package = $Matches.pkg
                Current = ($Matches.old -replace '^(v\d+\.\d+\.\d+).*$', '$1')
                New     = ($Matches.new -replace '^(v\d+\.\d+\.\d+).*$', '$1')
            }
        }
    }

    if (-not $updates) {
        Log-Success "All Go modules are up to date."
        return
    }

    $pkgWidth = [Math]::Max(
        7,
        ($updates | ForEach-Object { $_.Package.Length } | Measure-Object -Maximum).Maximum
    )

    Write-Host ""
    Write-Host ("{0,-$pkgWidth}  {1,-18}  {2}" -f "Package", "Current", "Latest")
    Write-Host ("-" * ($pkgWidth + 32))

    foreach ($u in $updates) {

        Write-Host ("{0,-$pkgWidth}  " -f $u.Package) -ForegroundColor Blue -NoNewline
        Write-Host ("{0,-18}  " -f $u.Current)        -ForegroundColor Red -NoNewline
        Write-Host $u.New                            -ForegroundColor Green
    }

    Write-Host ""
    Write-Host "$($updates.Count) module(s) can be upgraded." -ForegroundColor Yellow
}


