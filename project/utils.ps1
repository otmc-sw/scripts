

function EnsureTopDirectory() {
    if (-not $TOP) {
        Write-Error "ERROR: Variable TOP is not defined."
        exit 1
    }

    Write-Host "### 🌿 Working directory: $TOP" -ForegroundColor Blue
    Set-Location $TOP
}

