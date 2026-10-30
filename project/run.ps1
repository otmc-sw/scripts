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
)

. $PSScriptRoot/utils.ps1
EnsureTopDirectory

$RUN_BIN = "data/main.exe"

$COLOR_BACKEND  = 'DarkBlue'
$COLOR_FRONTEND = 'DarkGreen'
$COLOR_SUB      = 'DarkGray'
$VERSION        = '0.1.7'

Set-Location $TOP

function Get-ConsoleWidth {
    return 160
}

function Center-Text {
    param(
        [string]$Text
    )

    $width = Get-ConsoleWidth
    $padding = [Math]::Max(0, ($width - $Text.Length) / 2)
    return (' ' * [int]$padding) + $Text
}

function Show-Banner {
    param(
        [string]$Mode
    )

    $width = Get-ConsoleWidth
    $line  = '=' * ($width - 1)

    if ($Mode -eq 'frontend') {
        $color = $COLOR_FRONTEND
        $title = "Project Runner $VERSION > DEV Frontend"
    } else {
        $color = $COLOR_BACKEND
        $title = "Project Runner $VERSION > DEV Backend"
    }

    Write-Host $line -ForegroundColor $color
    Write-Host (Center-Text $title) -ForegroundColor $color
    Write-Host (Center-Text "OTMC Softwares © 2026") -ForegroundColor $COLOR_SUB
    Write-Host $line -ForegroundColor $color
}

function Run-Frontend {
    Show-Banner -Mode 'frontend'
    Set-Location $TOP/frontend
    Log "🚀 Starting frontend development server..."
    npm run dev
}

function Run-Backend {
    Show-Banner -Mode 'backend'
    Set-Location $TOP/backend
    Log "🌿 Generating SQLC bindings..."
    sqlc generate

    Log "✨ Tidying Go modules..."
    go mod tidy

    Log "📚 Building Go application..."
    go build -o $RUN_BIN
    if ($LASTEXITCODE -ne 0) {
        Log-Error "Go build failed"
        exit 1
    }

    Log "🚀 Starting Go application..."
    & $RUN_BIN -d
}

try {
    if ($Frontend) {
        Run-Frontend
    }
    else {
        Run-Backend
    }
}
finally {
    Set-Location $TOP
}

