# ==============================================================================
# Script Tối Ưu Hóa & Xóa Comment Tự Động (Kèm Đo Thời Gian Chạy)
# Copyright (c) 2026 OTMC Softwares.
# ==============================================================================

. "$PSScriptRoot/utils.ps1"
EnsureTopDirectory
if ($TOP) { Set-Location -Path $TOP }

# --- Bắt đầu đo thời gian ---
$Stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

# --- 1. Nhận diện License ---
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

# --- 2. Cấu hình Đường dẫn & Whitelist ---
$SrcDirs = @("$TOP")

$IgnoredList  = @("sqlc", "node_modules", "test-results", "dist", "data")
$IgnoredRegex = [regex] "(?i)[\\/]($(($IgnoredList | ForEach-Object { [regex]::Escape($_) }) -join '|'))[\\/]"

$WhitelistTerms = @(
    "Apache License 2.0", "2026 OTMC Softwares", "OTMC License",
    "OTMC Contributors", "Copyright", "Nguyen Van Trung",
    "TODO:", "go:embed", "eslint-disable", "@ts-ignore", "@jsxImportSource"
)
$WhitelistRegex = [regex] (($WhitelistTerms | ForEach-Object { [regex]::Escape($_) }) -join '|')

$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)

# --- 3. Helper Functions ---
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
    if ($Extension -in @("tsx", "jsx")) {
        $Content = [regex]::Replace($Content, '(?m)^[ \t]*\{\s*/\*[\s\S]*?\*/\s*\}[ \t]*(\r?\n)?', {
            param($m) if (Test-ShouldKeepComment $m.Value) { $m.Value } else { '' }
        })
    }

    # Multi-line Block Comment: /* ... */
    $Content = [regex]::Replace($Content, '(?m)^[ \t]*/\*[\s\S]*?\*/[ \t]*(\r?\n)?|/\*[\s\S]*?\*/', {
        param($m) if (Test-ShouldKeepComment $m.Value) { $m.Value } else { '' }
    })

    # Standalone Line Comment: // ...
    $Content = [regex]::Replace($Content, '(?m)^[ \t]*//.*(?:\r?\n|$)', {
        param($m) if (Test-ShouldKeepComment $m.Value) { $m.Value } else { '' }
    })

    # Inline Comment: code; // comment (Tránh URL & Template literals)
    $Content = [regex]::Replace($Content, '(?m)(?<!:|\w)\s*//(?![/\w\d_]+\.\w+).*$', {
        param($m)
        $val = $m.Value
        if ($val -match '`' -or (Test-ShouldKeepComment $val)) { return $val }
        return ''
    })

    return $Content
}

function Remove-FileComments ([string]$FilePath, [string]$Extension) {
    if ($IgnoredRegex.IsMatch($FilePath)) { return }

    $Original = [System.IO.File]::ReadAllText($FilePath)
    $Content  = Add-LicenseHeaderIfNeeded -Content $Original -LicenseType $DetectedLicense
    $Content  = Process-FileContent -Content $Content -Extension $Extension

    if ($Content -ne $Original) {
        [System.IO.File]::WriteAllText($FilePath, $Content, $Utf8NoBom)
    }
}

# --- 4. Main Loop ---
$TotalProcessedFiles = 0

foreach ($Dir in $SrcDirs) {
    if (-not (Test-Path $Dir)) {
        Write-Host "⚠️ Skipping missing directory: $Dir" -ForegroundColor Yellow
        continue
    }

    Write-Host "`n### 📁 Scanning: $Dir" -ForegroundColor Blue

    $Files = Get-ChildItem -Path $Dir -Recurse -File -Include *.css, *.js, *.ts, *.tsx, *.go |
        Where-Object { -not $IgnoredRegex.IsMatch($_.FullName) }

    $dirTotal = $Files.Count
    $count    = 0

    foreach ($File in $Files) {
        $count++
        $TotalProcessedFiles++
        Write-Host ("     → [{0,3}/{1,3}] 🌿 Processing: {2}" -f $count, $dirTotal, $File.Name)
        Remove-FileComments -FilePath $File.FullName -Extension $File.Extension.TrimStart('.')
    }

    Write-Host "🚀 Completed processing $Dir with $dirTotal files" -ForegroundColor Green
}

# --- Dừng đồng hồ & hiển thị kết quả ---
$Stopwatch.Stop()
$ElapsedTime = [math]::Round($Stopwatch.Elapsed.TotalSeconds, 2)

Write-Host "`n>>> ✨ Comment removal complete." -ForegroundColor Green
Write-Host "    - Elapsed:   ${ElapsedTime}s" -ForegroundColor Cyan
Write-Host "    - Processed: $TotalProcessedFiles files" -ForegroundColor Cyan