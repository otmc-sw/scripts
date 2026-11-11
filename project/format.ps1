#
# Apache License 2.0.
# Copyright (c) 2026 OTMC Softwares.
# Contributors: Nguyen Van Trung, OTMC Contributors.
#

param(
    [switch]$Summary
)

. "$PSScriptRoot/utils.ps1"
EnsureTopDirectory
if ($TOP) { Set-Location -Path $TOP }

if ($TEST) {
    $TOP = "D:\SCM\GitHub\OTMC\Softwares\dns-provider"
}

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
$SrcDirs        = @("$TOP")
$IgnoredNames   = [System.Collections.Generic.HashSet[string]]::new(
    [string[]]@("sqlc", "node_modules", "test-results", "dist", "data", ".git", "build", ".next", "out"), 
    [System.StringComparer]::OrdinalIgnoreCase
)
$TargetExts     = [System.Collections.Generic.HashSet[string]]::new(
    [string[]]@(".css", ".js", ".ts", ".tsx", ".jsx", ".go"), 
    [System.StringComparer]::OrdinalIgnoreCase
)

$WhitelistTerms = @(
    "Apache License 2.0", "2026 OTMC Softwares", "OTMC License",
    "OTMC Contributors", "Copyright", "Nguyen Van Trung",
    "TODO:", "go:embed", "eslint-disable", "@ts-ignore", "@jsxImportSource"
)

$RegexOpts        = [System.Text.RegularExpressions.RegexOptions]::Compiled
$WhitelistPattern = ($WhitelistTerms | ForEach-Object { [regex]::Escape($_) }) -join '|'
$WhitelistRegex   = [regex]::new($WhitelistPattern, $RegexOpts)
$Utf8Encoding     = New-Object System.Text.UTF8Encoding($false)

# --- 3. Helper Functions ---
function Test-ShouldKeepComment ([string]$CommentText) {
    return $WhitelistRegex.IsMatch($CommentText)
}

function Add-LicenseHeaderIfNeeded ([string]$Content, [string]$LicenseType) {
    if ($Content -match '^\s*(//|/\*)') { return $Content }
    return "$($LicenseHeaders[$LicenseType])`n$Content"
}

function Process-FileContent ([string]$Content, [string]$Extension) {
    $ext = $Extension.ToLower()

    if ($ext -in @("tsx", "jsx")) {
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

    # Inline Comment: code; // comment
    $Content = [regex]::Replace($Content, '(?m)(?<!:|\w)\s*//(?![/\w\d_]+\.\w+).*$', {
        param($m)
        $val = $m.Value
        if ($val -match '`' -or (Test-ShouldKeepComment $val)) { return $val }
        return ''
    })

    return $Content
}

function Remove-FileComments ([string]$FilePath) {
    $ext      = [System.IO.Path]::GetExtension($FilePath).TrimStart('.')
    $Original = [System.IO.File]::ReadAllText($FilePath)
    $Content  = Add-LicenseHeaderIfNeeded -Content $Original -LicenseType $DetectedLicense
    $Content  = Process-FileContent -Content $Content -Extension $ext

    if ($Content -ne $Original) {
        [System.IO.File]::WriteAllText($FilePath, $Content, $Utf8Encoding)
    }
}

# Hàm lấy file siêu tốc qua .NET Directory (Bỏ qua thư mục Ignored ngay từ khâu duyệt)
function Fast-GetFiles ([string]$RootPath) {
    $FileList = [System.Collections.Generic.List[string]]::new()

    function Traverse ([string]$CurrentPath) {
        try {
            # 1. Thu thập các file thỏa mãn đuôi mở rộng
            foreach ($file in [System.IO.Directory]::EnumerateFiles($CurrentPath)) {
                $ext = [System.IO.Path]::GetExtension($file)
                if ($TargetExts.Contains($ext)) {
                    $FileList.Add($file)
                }
            }

            # 2. Thu thập thư mục con & Lọc ngay thư mục Ignored
            foreach ($dir in [System.IO.Directory]::EnumerateDirectories($CurrentPath)) {
                $dirName = [System.IO.Path]::GetFileName($dir)
                if (-not $IgnoredNames.Contains($dirName)) {
                    Traverse -CurrentPath $dir
                }
            }
        } catch {
            # Bỏ qua các thư mục không có quyền truy cập
        }
    }

    Traverse -CurrentPath $RootPath
    return $FileList
}

function Format-Size ([long]$Bytes) {
    if ($Bytes -ge 1MB) { return ("{0:N2} MB" -f ($Bytes / 1MB)) }
    if ($Bytes -ge 1KB) { return ("{0:N2} KB" -f ($Bytes / 1KB)) }
    return "${Bytes}B"
}

# --- 4. Summary Mode (-s): Thống kê theo loại file ---
if ($Summary) {
    $LanguageNames = @{
        ".go"  = "Golang"
        ".ts"  = "TypeScript"
        ".tsx" = "TSX"
        ".js"  = "JavaScript"
        ".jsx" = "JSX"
        ".css" = "CSS"
    }

    $Stats = [ordered]@{}

    foreach ($Dir in $SrcDirs) {
        if (-not (Test-Path $Dir)) { continue }
        foreach ($FilePath in (Fast-GetFiles -RootPath $Dir)) {
            $ext = [System.IO.Path]::GetExtension($FilePath)
            $lang = if ($LanguageNames.ContainsKey($ext)) { $LanguageNames[$ext] } else { $ext.TrimStart('.').ToUpper() }

            if (-not $Stats.Contains($lang)) {
                $Stats[$lang] = [pscustomobject]@{ Language = $lang; Files = 0; Bytes = 0L; Chars = 0L }
            }

            $Stats[$lang].Files++
            $Stats[$lang].Bytes += (Get-Item $FilePath).Length
            $Stats[$lang].Chars += [System.IO.File]::ReadAllText($FilePath).Length
        }
    }

    $SummaryRows = $Stats.Values | ForEach-Object {
        [pscustomobject]@{
            Language   = $_.Language
            Files      = $_.Files.ToString("N0")
            Size       = Format-Size $_.Bytes
            Characters = $_.Chars.ToString("N0")
        }
    }

    $TotalFiles = ($Stats.Values | Measure-Object Files -Sum).Sum
    $TotalBytes = ($Stats.Values | Measure-Object Bytes -Sum).Sum
    $TotalChars = ($Stats.Values | Measure-Object Chars -Sum).Sum

    Write-Table `
        -Title "📊 FILE SUMMARY" `
        -Columns @(
            @{ Name = "Language";   Align = "Left"  },
            @{ Name = "Files";      Align = "Right" },
            @{ Name = "Size";       Align = "Right" },
            @{ Name = "Characters"; Align = "Right" }
        ) `
        -Data $SummaryRows `
        -Totals ([pscustomobject]@{
            Language   = ""
            Files      = $TotalFiles.ToString("N0")
            Size       = Format-Size $TotalBytes
            Characters = $TotalChars.ToString("N0")
        })

    Write-Host ("  {0} files  |  {1}  |  {2:N0} characters" -f `
        $TotalFiles,
        (Format-Size $TotalBytes),
        $TotalChars) -ForegroundColor Green

    $Stopwatch.Stop()
    exit
}

# --- 5. Main Loop ---
$TotalProcessedFiles = 0

foreach ($Dir in $SrcDirs) {
    if (-not (Test-Path $Dir)) {
        Write-Host "⚠️ Skipping missing directory: $Dir" -ForegroundColor Yellow
        continue
    }

    Write-Host "`n### 📁 Scanning: $Dir" -ForegroundColor Blue

    $Files    = Fast-GetFiles -RootPath $Dir
    $dirTotal = $Files.Count
    $count    = 0

    foreach ($FilePath in $Files) {
        $count++
        $TotalProcessedFiles++
        $fileName = [System.IO.Path]::GetFileName($FilePath)
        
        Write-Host ("    → [{0,3}/{1,3}] 🌿 Processing: {2}" -f $count, $dirTotal, $fileName)
        Remove-FileComments -FilePath $FilePath
    }

    Write-Host "🚀 Completed processing $Dir with $dirTotal files" -ForegroundColor Green
}

$Stopwatch.Stop()
$ElapsedTime = [math]::Round($Stopwatch.Elapsed.TotalSeconds, 2)

Write-Host "`n>>> ✨ Comment removal complete." -ForegroundColor Green
Write-Host "    - Elapsed:   ${ElapsedTime}s" -ForegroundColor Cyan
Write-Host "    - Processed: $TotalProcessedFiles files" -ForegroundColor Cyan