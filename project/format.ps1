# ==============================================================================
# Script Tối Ưu Hóa & Xóa Comment Tự Động
# Copyright (c) 2026 OTMC Softwares.
# ==============================================================================

. "$PSScriptRoot/utils.ps1"
EnsureTopDirectory
if ($TOP) { Set-Location -Path $TOP }

$DetectedLicense = "Apache License 2.0"
$LicenseFile     = Get-ChildItem -Path $TOP -File -ErrorAction SilentlyContinue | 
    Where-Object { $_.Name -match '^LICEN[CS]E(\.txt)?$' } | 
    Select-Object -First 1

if ($LicenseFile -and (Get-Content -Path $LicenseFile.FullName -Raw) -match "OTMC License") {
    $DetectedLicense = "OTMC License"
}

$LicenseHeaders = @{
    "Apache License 2.0" = @"
/**
 * @License Apache License 2.0
 * @Copyright (c) 2026 OTMC Softwares.
 * @Contributors Nguyen Van Trung, OTMC Contributors.
 **/
"@
    "OTMC License"       = @"
/**
 * @License OTMC License
 * @Copyright (c) 2026 OTMC Softwares. All rights reserved.
 * @Contributors Nguyen Van Trung, OTMC Contributors.
 **/
"@
}

Write-Host "### 📜 Detected license: $DetectedLicense" -ForegroundColor Cyan


$SrcDirs = @(
    "frontend/src/"
    "backend/"
    "tests/"
)

$IgnoredList = @(
    "sqlc"
    "node_modules"
    "test-results"
    "dist"
    "data"
)

$IgnoredRegex = [regex] [string]::Format('(?i)[\\/]({0})[\\/]', (($IgnoredList | ForEach-Object { [regex]::Escape($_) }) -join '|'))


$WhitelistTerms = @(
    "Apache License 2.0"
    "2026 OTMC Softwares"
    "OTMC License"
    "OTMC Contributors"
    "Copyright"
    "Nguyen Van Trung"
    "TODO:"
    "go:embed"
    "eslint-disable"
    "@ts-ignore"
    "@jsxImportSource"
)
$WhitelistRegex = [regex] (($WhitelistTerms | ForEach-Object { [regex]::Escape($_) }) -join '|')


$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)

function Test-ShouldKeepComment ([string]$CommentText) {
    return $WhitelistRegex.IsMatch($CommentText)
}

function Add-LicenseHeaderIfNeeded ([string]$Content, [string]$LicenseType) {
    if ($Content -match '^\s*(//|/\*)') {
        return $Content
    }
    return "$($LicenseHeaders[$LicenseType])`n$Content"
}

function Process-FileContent ([string]$Content, [string]$Extension) {
    if ($Extension -eq "tsx") {
        $Content = [regex]::Replace($Content, '(?m)^[ \t]*\{\s*/\*[\s\S]*?\*/\s*\}[ \t]*(\r?\n)?', {
            param($m) if (Test-ShouldKeepComment $m.Value) { $m.Value } else { '' }
        })
    }

    $Content = [regex]::Replace($Content, '(?m)^[ \t]*/\*[\s\S]*?\*/[ \t]*(\r?\n)?|/\*[\s\S]*?\*/', {
        param($m) if (Test-ShouldKeepComment $m.Value) { $m.Value } else { '' }
    })

    $Content = [regex]::Replace($Content, '(?m)^[ \t]*//.*(?:\r?\n|$)', {
        param($m) if (Test-ShouldKeepComment $m.Value) { $m.Value } else { '' }
    })

    $Content = [regex]::Replace($Content, '(?m)(?<!:)\s*//(?!/).*$', {
        param($m) if ($m.Value -match '`' -or (Test-ShouldKeepComment $m.Value)) { $m.Value } else { '' }
    })

    return $Content
}

function Remove-FileComments ([string]$FilePath, [string]$Extension) {
    if ($IgnoredRegex.IsMatch($FilePath)) { return }

    $Original = [System.IO.File]::ReadAllText($FilePath)
    
    $Content = Add-LicenseHeaderIfNeeded -Content $Original -LicenseType $DetectedLicense
    
    $Content = Process-FileContent -Content $Content -Extension $Extension

    if ($Content -ne $Original) {
        [System.IO.File]::WriteAllText($FilePath, $Content, $Utf8NoBom)
    }
}

foreach ($Dir in $SrcDirs) {
    if (-not (Test-Path $Dir)) {
        Write-Host "⚠️ Skipping missing directory: $Dir" -ForegroundColor Yellow
        continue
    }

    Write-Host "`n### 📁 Scanning: $Dir" -ForegroundColor Blue

    $Files = Get-ChildItem -Path $Dir -Recurse -File -Include *.css, *.ts, *.tsx, *.go |
        Where-Object { -not $IgnoredRegex.IsMatch($_.FullName) }

    $total = $Files.Count
    $count = 0

    foreach ($File in $Files) {
        $count++
        Write-Host ("     → [{0,3}/{1,3}] 🌿 Processing: {2}" -f $count, $total, $File.Name)
        Remove-FileComments -FilePath $File.FullName -Extension $File.Extension.TrimStart('.')
    }

    Write-Host "🚀 Completed processing $Dir with $total files" -ForegroundColor Green
}

Write-Host "`n>>> ✨ Comment removal complete." -ForegroundColor Green