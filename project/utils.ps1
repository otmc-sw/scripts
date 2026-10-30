#
# Apache License 2.0
# Copyright (c) 2026 OTMC Softwares.
# Contributors: Nguyen Van Trung, Nguyen Thi Hoai, OTMC Contributors.
#

# Logging functions
# Format: HH:MM:SS Message
function Log-Step    { param([string]$Message) Write-Host "`n### $Message" -ForegroundColor DarkBlue }
function Log-Success { param([string]$Message) Write-Host ">>> 🎉 $Message`n" -ForegroundColor DarkGreen }
function Log-Info    { param([string]$Message) Write-Host ">>> 🌿 $Message" -ForegroundColor Cyan }
function Log-Error   { param([string]$Message) Write-Host ">>> ❌ $Message" -ForegroundColor Red }
function Log-Warning { param([string]$Message) Write-Host ">>> 📝 $Message" -ForegroundColor Yellow }

function Log {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message
    )

    $timestamp = Get-Date -Format "HH:mm:ss"
    Write-Host "$timestamp $Message"
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
    param ([string]$Message)
    Log-Warning $Message
}

function Run {
    param(
        [Parameter(Mandatory = $true)]
        [scriptblock]$Command
    )

    Write-Host "`n>> $Command" -ForegroundColor Blue
    & $Command
    Error-Handler $LASTEXITCODE "Command failed: $Command"
}

function EnsureTopDirectory {
    if (-not $TOP) {
        Log-Error "Variable TOP is not defined."
        exit 1
    }

    Log-Step "🌿 Working directory: $TOP"
    Set-Location -Path $TOP
}

function Get-GoDirectDependencies {
    $json = & go mod edit -json 2>&1
    Error-Handler $LASTEXITCODE "Failed to execute 'go mod edit -json': $json"

    $mod = $json | ConvertFrom-Json

    $directPackages = @{}
    foreach ($req in $mod.Require) {
        if (-not $req.Indirect) {
            $directPackages[$req.Path] = $req.Version
        }
    }

    return $directPackages
}

function Get-GoModuleUpdates {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$DirectDependencies
    )

    Log-Info "Checking updates for all dependencies..."
    
    $allModules = & go list -u -m all 2>&1
    Error-Handler $LASTEXITCODE "Failed to check module updates: `n$allModules"

    $updates = [System.Collections.Generic.List[PSCustomObject]]::new()

    foreach ($line in $allModules) {
        if ($line -match '^(?<pkg>\S+)\s+(?<old>v\S+)\s+\[(?<new>[^\]]+)\]$') {
            $pkg = $Matches.pkg
            if ($DirectDependencies.ContainsKey($pkg)) {
                $updates.Add([PSCustomObject]@{
                    Package        = $pkg
                    CurrentVersion = $Matches.old
                    LatestVersion  = $Matches.new
                })
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

    $pkgWidth    = [Math]::Max(7, ($Updates | ForEach-Object { $_.Package.Length } | Measure-Object -Maximum).Maximum)
    $curWidth    = [Math]::Max(7, ($Updates | ForEach-Object { $_.CurrentVersion.Length } | Measure-Object -Maximum).Maximum)
    $latestWidth = [Math]::Max(6, ($Updates | ForEach-Object { $_.LatestVersion.Length } | Measure-Object -Maximum).Maximum)

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
        & go get "$($u.Package)@latest"
        Error-Handler $LASTEXITCODE "Failed to update $($u.Package)"
    }
}

function Add-EnvAutoSource {
    param(
        [string]$ProfilePath = $PROFILE
    )

    $marker = '# Auto-source env.ps1 in the current directory'
    $profileDir = Split-Path -Parent $ProfilePath

    if (!(Test-Path $profileDir)) {
        New-Item -ItemType Directory -Path $profileDir -Force |
            Out-Null
    }

    if (!(Test-Path $ProfilePath)) {
        New-Item -ItemType File -Path $ProfilePath -Force |
            Out-Null
    }

    $content = Get-Content $ProfilePath -Raw

    if ($content -and $content.Contains($marker)) {
        Write-Host 'Auto-source configuration already exists.' -ForegroundColor Yellow
        return
    }

    $script = @'

# Auto-source env.ps1 in the current directory
$envScript = Join-Path (Get-Location) 'env.ps1'

if (Test-Path $envScript -PathType Leaf) {
    Write-Host "🌿 Auto-sourcing env.ps1 from: $envScript" -ForegroundColor Cyan
    . $envScript
}
'@

    Add-Content -Path $ProfilePath -Value $script
    Write-Host "📝 NOTE: Auto-source configuration added to: $ProfilePath" -ForegroundColor Green
}

