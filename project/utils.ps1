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
        [int]$LastExitCode,
        [string]$Message = ""
    )

    if ($LastExitCode -ne 0) {
        $errorMessage = "Exit code $LastExitCode"

        if (-not [string]::IsNullOrWhiteSpace($Message)) {
            $errorMessage += ": $Message"
        }

        Log-Error $errorMessage
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
    Error-Handler $LASTEXITCODE "Command failed: $Command"
}

function EnsureTopDirectory() {
    if (-not $TOP) {
        Log-Error "Variable TOP is not defined."
        exit 1
    }

    Log-Step "🌿 Working directory: $TOP"
    Set-Location $TOP
}

function Get-GoDirectDependencies {
    $json = & go mod edit -json 2>&1
    Error-Handler $LASTEXITCODE "Failed to get go mod edit -json: $json"

    $mod = $json | ConvertFrom-Json

    $direct = @()
    foreach ($req in $mod.Require) {
        if (-not $req.Indirect) {
            $direct += [PSCustomObject]@{
                Package = $req.Path
                Version = $req.Version
            }
        }
    }

    return $direct
}

function Get-GoModuleUpdates {
    param(
        [Parameter(Mandatory = $true)]
        [object[]]$Dependencies
    )

    $updates = @()

    foreach ($dep in $Dependencies) {
        $output = & go list -u -m $dep.Package 2>&1
        Error-Handler $LASTEXITCODE "Failed to check updates for $dep.Package: `n$output"

        if ($output -match '^(?<pkg>\S+)\s+(?<old>v\S+)\s+\[(?<new>[^\]]+)\]$') {
            $updates += [PSCustomObject]@{
                Package         = $Matches.pkg
                CurrentVersion  = $Matches.old
                LatestVersion   = $Matches.new
            }
        }
    }

    return $updates
}

function Show-GoModuleUpdates {
    param(
        [object[]]$Updates
    )

    if (-not $Updates -or $Updates.Count -eq 0) {
        Log-Success "All direct dependencies are up to date."
        return
    }

    $pkgWidth = [Math]::Max(
        7,
        ($Updates | ForEach-Object { $_.Package.Length } | Measure-Object -Maximum).Maximum
    )

    $curWidth = [Math]::Max(
        7,
        ($Updates | ForEach-Object { $_.CurrentVersion.Length } | Measure-Object -Maximum).Maximum
    )

    $latestWidth = [Math]::Max(
        6,
        ($Updates | ForEach-Object { $_.LatestVersion.Length } | Measure-Object -Maximum).Maximum
    )

    Write-Host ""
    Write-Host ("{0,-$pkgWidth}  {1,-$curWidth}  {2,-$latestWidth}" -f "Package", "Current", "Latest")
    Write-Host ("-" * ($pkgWidth + $curWidth + $latestWidth + 4))

    foreach ($u in $Updates) {
        Write-Host ("{0,-$pkgWidth}  " -f $u.Package)        -ForegroundColor Blue -NoNewline
        Write-Host ("{0,-$curWidth}  " -f $u.CurrentVersion) -ForegroundColor Red -NoNewline
        Write-Host ("{0,-$latestWidth}" -f $u.LatestVersion) -ForegroundColor Green
    }

    Write-Host ""
}

function Update-GoModules {
    param(
        [Parameter(Mandatory = $true)]
        [object[]]$Updates
    )

    foreach ($u in $Updates) {
        $cmd = "go get $($u.Package)@latest"
        Write-Host "`n>> $cmd" -ForegroundColor Blue
        & go get "$($u.Package)@latest"
        Error-Handler $LASTEXITCODE "Failed to update $u.Package"
    }
}


