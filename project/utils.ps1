
$STEP_COUNTER = 1

function Log-Step {
    param (
        [string]$Message
    )
    Write-Host "`n### $STEP_COUNTER. $Message" -ForegroundColor Blue
    $STEP_COUNTER++
}

function Log-Success {
    param (
        [string]$Message
    )
    Write-Host ">>> $Message." -ForegroundColor Green
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

function EnsureTopDirectory() {
    if (-not $TOP) {
        Write-Error "ERROR: Variable TOP is not defined."
        exit 1
    }

    Write-Host "### 🌿 Working directory: $TOP" -ForegroundColor Blue
    Set-Location $TOP
}




