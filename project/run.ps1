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


$RUN_BIN = "data/main.exe"

$COLOR_BACKEND  = 'DarkBlue'
$COLOR_FRONTEND = 'DarkGreen'
$COLOR_SUB      = 'DarkGray'
$VERSION        = '0.1.5'

Set-Location $PSScriptRoot/..

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

try {
    if ($Frontend) {
        Show-Banner -Mode 'frontend'
        Set-Location frontend
        npm run dev
    }
    elseif ($All) {
        Set-Location frontend
        npm run build
        Set-Location ..
        Show-Banner -Mode 'backend'
        Set-Location backend
        sqlc generate
        go mod tidy
        go build -o $RUN_BIN
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Go build failed" -ForegroundColor Red
            exit 1
        }
        & $RUN_BIN -p 5006 -d
    }
    else {
        Show-Banner -Mode 'backend'
        Set-Location backend
        sqlc generate
        go mod tidy
        go build -o $RUN_BIN
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Go build failed" -ForegroundColor Red
            exit 1
        }
        & $RUN_BIN -p 5001 -d
    }
}
finally {
    Set-Location $PSScriptRoot/..
}
