

function EnsureTopDirectory() {
    if (-not $env:TOP) {
        Write-Error "ERROR: Environment variable TOP is not defined."
        exit 1
    }

    Write-Host "🌿 Working directory: $env:TOP
    Set-Location $env:TOP
}

