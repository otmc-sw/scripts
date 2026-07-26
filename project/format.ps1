# ==============================================================================
# Script Tối Ưu Hóa & Xóa Comment Tự Động (Fix False Positives)
# Copyright (c) 2026 OTMC Softwares.
# ==============================================================================

. "$PSScriptRoot/utils.ps1"
EnsureTopDirectory
if ($TOP) { Set-Location -Path $TOP }

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
$SrcDirs = @(
    "frontend/src/"
    "backend/"
    "tests/"
)

$IgnoredList = @("sqlc", "node_modules", "test-results", "dist", "data")
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
    # Nếu file đã chứa comment ngay dòng đầu tiên (kể cả whitespace), bỏ qua việc chèn License
    if ($Content -match '^\s*(//|/\*)') {
        return $Content
    }
    return "$($LicenseHeaders[$LicenseType])`n$Content"
}

function Process-FileContent ([string]$Content, [string]$Extension) {
    # a. JSX/TSX Block Comment: {/* ... */}
    if ($Extension -in @("tsx", "jsx")) {
        $Content = [regex]::Replace($Content, '(?m)^[ \t]*\{\s*/\*[\s\S]*?\*/\s*\}[ \t]*(\r?\n)?', {
            param($m) if (Test-ShouldKeepComment $m.Value) { $m.Value } else { '' }
        })
    }

    # b. Multi-line Block Comment: /* ... */
    $Content = [regex]::Replace($Content, '(?m)^[ \t]*/\*[\s\S]*?\*/[ \t]*(\r?\n)?|/\*[\s\S]*?\*/', {
        param($m) if (Test-ShouldKeepComment $m.Value) { $m.Value } else { '' }
    })

    # c. Standalone Line Comment: // ... (Nằm riêng trên 1 dòng -> Xóa luôn cả ký tự xuống dòng)
    $Content = [regex]::Replace($Content, '(?m)^[ \t]*//.*(?:\r?\n|$)', {
        param($m) if (Test-ShouldKeepComment $m.Value) { $m.Value } else { '' }
    })

    # d. Inline Comment: code; // comment
    # Tránh bắt lầm:
    #   - URL: http://, https://, file:// (dùng negative lookbehind (?<!:|\w))
    #   - Template string chứa ${...} hoặc nằm trong chuỗi
    $Content = [regex]::Replace($Content, '(?m)(?<!:|\w)\s*//(?![/\w\d_]+\.\w+).*$', {
        param($m)
        $val = $m.Value
        # Bỏ qua nếu có chứa dấu backtick (thường trong template literal) hoặc trùng Whitelist
        if ($val -match '`' -or (Test-ShouldKeepComment $val)) { 
            return $val 
        }
        return ''
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

# --- 4. Main Processing Loop ---
foreach ($Dir in $SrcDirs) {
    if (-not (Test-Path $Dir)) {
        Write-Host "⚠️ Skipping missing directory: $Dir" -ForegroundColor Yellow
        continue
    }

    Write-Host "`n### 📁 Scanning: $Dir" -ForegroundColor Blue

    $Files = Get-ChildItem -Path $Dir -Recurse -File -Include *.css, *.js, *.ts, *.tsx, *.go |
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