# ==============================================================================
# Script Tối Ưu Hóa & Xóa Comment Tự Động (Tốc Độ Cao)
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

# --- 2. Cấu hình Đường dẫn, Whitelist & Bỏ qua Thư mục ---
$SrcDirs       = @("$TOP")
$IgnoredNames  = @("sqlc", "node_modules", "test-results", "dist", "data", ".git")
$Extensions    = @(".css", ".js", ".ts", ".tsx", ".go")

$WhitelistTerms = @(
    "Apache License 2.0", "2026 OTMC Softwares", "OTMC License",
    "OTMC Contributors", "Copyright", "Nguyen Van Trung",
    "TODO:", "go:embed", "eslint-disable", "@ts-ignore", "@jsxImportSource"
)

# Biên dịch Regex với tùy chọn Compiled để tối ưu performance
$RegexOpts      = [System.Text.RegularExpressions.RegexOptions]::Compiled
$WhitelistPattern = ($WhitelistTerms | ForEach-Object { [regex]::Escape($_) }) -join '|'
$WhitelistRegex = [regex]::new($WhitelistPattern, $RegexOpts)

$Utf8Encoding   = New-Object System.Text.UTF8Encoding($false)

# --- 3. Helper Functions ---
function Test-ShouldKeepComment ([string]$CommentText) {
    return $WhitelistRegex.IsMatch($CommentText)
}

function Add-LicenseHeaderIfNeeded ([string]$Content, [string]$LicenseType) {
    if ($Content -match '^\s*(//|/\*)') { return $Content }
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
    $Original = [System.IO.File]::ReadAllText($FilePath)
    $Content  = Add-LicenseHeaderIfNeeded -Content $Original -LicenseType $DetectedLicense
    $Content  = Process-FileContent -Content $Content -Extension $Extension

    if ($Content -ne $Original) {
        [System.IO.File]::WriteAllText($FilePath, $Content, $Utf8Encoding)
    }
}

# Hàm lấy danh sách file thông minh (Bỏ qua triệt để thư mục bị Ignore ngay khi duyệt)
function Get-TargetFiles ([string]$RootPath) {
    $ResultFiles = [System.Collections.Generic.List[System.IO.FileInfo]]::new()
    
    # Sử dụng Get-ChildItem kết hợp -Directory và -Exclude/Bỏ qua từ đầu
    $DirectoryQueue = [System.Collections.Generic.Queue[string]]::new()
    $DirectoryQueue.Enqueue($RootPath)

    while ($DirectoryQueue.Count -gt 0) {
        $CurrentDir = $DirectoryQueue.Dequeue()

        try {
            # 1. Lấy các file thỏa mãn đuôi mở rộng trong thư mục hiện tại
            $Files = Get-ChildItem -Path $CurrentDir -File -ErrorAction SilentlyContinue | 
                Where-Object { $_.Extension -in $Extensions }
            if ($Files) { $ResultFiles.AddRange($Files) }

            # 2. Lấy các thư mục con và LỌC NGAY TỪ ĐẦU các thư mục trong $IgnoredNames
            $SubDirs = Get-ChildItem -Path $CurrentDir -Directory -ErrorAction SilentlyContinue | 
                Where-Object { $_.Name -notin $IgnoredNames }

            foreach ($SubDir in $SubDirs) {
                $DirectoryQueue.Enqueue($SubDir.FullName)
            }
        } catch {
            # Bỏ qua thư mục không có quyền truy cập
        }
    }

    return $ResultFiles
}

# --- 4. Main Loop ---
$TotalProcessedFiles = 0

foreach ($Dir in $SrcDirs) {
    if (-not (Test-Path $Dir)) {
        Write-Host "⚠️ Skipping missing directory: $Dir" -ForegroundColor Yellow
        continue
    }

    Write-Host "`n### 📁 Scanning: $Dir" -ForegroundColor Blue

    # Lấy danh sách file với thuật toán bỏ qua thư mục Ignored ngay từ đầu
    $Files    = Get-TargetFiles -RootPath $Dir
    $dirTotal = $Files.Count
    $count    = 0

    foreach ($File in $Files) {
        $count++
        $TotalProcessedFiles++
        Write-Host ("    → [{0,3}/{1,3}] 🌿 Processing: {2}" -f $count, $dirTotal, $File.Name)
        
        $ext = $File.Extension.TrimStart('.')
        Remove-FileComments -FilePath $File.FullName -Extension $ext
    }

    Write-Host "🚀 Completed processing $Dir with $dirTotal files" -ForegroundColor Green
}

# --- Dừng đồng hồ & hiển thị kết quả ---
$Stopwatch.Stop()
$ElapsedTime = [math]::Round($Stopwatch.Elapsed.TotalSeconds, 2)

Write-Host "`n>>> ✨ Comment removal complete." -ForegroundColor Green
Write-Host "    - Elapsed:   ${ElapsedTime}s" -ForegroundColor Cyan
Write-Host "    - Processed: $TotalProcessedFiles files" -ForegroundColor Cyan