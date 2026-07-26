#
# OTMC License.
# Copyright (c) 2026 OTMC Softwares. All rights reserved.
# Contributors: Trung Ng, OTMC Authors.
#

Set-Location -Path $PSScriptRoot/..

$LicenseHeader = @'
/**
 * @License OTMC License
 * @Copyright (c) 2026 OTMC Softwares. All rights reserved.
 * @Contributors Trung Ng, OTMC Authors.
**/
'@

$SrcDirs = @(
    "frontend/src/",
    "backend/",
    "tests/"
)

$IgnoredDirs = @(
    "\sqlc\",
    "\node_modules\",
    "\test-results\",
    "\dist\",
    "\data\"
)

$Whitelist = @(
    "OTMC License",
    "Copyright",
    "Trung Ng",
    "TODO: ",
    "go:embed",
    "Contributors:",
    "eslint-disable",
    "@ts-ignore",
    "@jsxImportSource"
)

function ShouldKeepComment {
    param ([string]$Text)

    foreach ($entry in $Whitelist) {
        if ($Text -match [regex]::Escape($entry)) {
            return $true
        }
    }
    return $false
}

function IsIgnoredPath {
    param ([string]$FullPath)

    foreach ($ignored in $IgnoredDirs) {
        if ($FullPath -like "*$ignored*") {
            return $true
        }
    }
    return $false
}

# Remove full-line JSX comments: { /* ... */ }
function Strip-JSXComments {
    param ([string]$Content)

    return [regex]::Replace(
        $Content,
        '^[ \t]*\{\s*/\*.*?\*/\s*\}[ \t]*(\r?\n|$)',
        '',
        'Singleline, Multiline'
    )
}

# Remove block comments (/* ... */) when standalone lines
function Strip-BlockComments {
    param ([string]$Content)

    return [regex]::Replace(
        $Content,
        '^[ \t]*/\*.*?\*/[ \t]*(\r?\n|$)',
        {
            param($m)
            if (ShouldKeepComment $m.Value) { $m.Value } else { "" }
        },
        'Singleline, Multiline'
    )
}

# Remove // comments (SAFE include-based)
function Strip-LineComments {
    param ([string]$Content)

    $lines = $Content -split "`n"
    $result = @()

    foreach ($line in $lines) {

        # 1. Full-line //
        if ($line -match '^[ \t]*//') {
            if (ShouldKeepComment $line) {
                $result += $line
            }
            continue
        }

        # 2. Skip lines containing quotes (string safety)
        if ($line -match '["'']') {
            $result += $line
            continue
        }

        # 3. Inline // ONLY after , ) }
        if ($line -match '([,)}][^/]*?)\s*//') {
            $clean = ($line -replace '\s*//.*$', '').TrimEnd()
            $result += $clean
            continue
        }

        # 4. Default
        $result += $line
    }

    return ($result -join "`n")
}

function Has-LicenseHeader {
    param ([string]$Content)

    return $Content -match '@License OTMC License'
}

function Add-LicenseHeader {
    param ([string]$Content)

    if (Has-LicenseHeader $Content) {
        return $Content
    }

    return "$LicenseHeader`n$Content"
}

function Remove-FileComments {
    param (
        [string]$FilePath,
        [string]$FileType
    )

    if (IsIgnoredPath $FilePath) {
        Write-Host " ⏭ Skipped (ignored dir): $FilePath"
        return
    }

    $Original = Get-Content -Path $FilePath -Raw
    $Content = $Original
    $Content = Add-LicenseHeader $Content

    switch ($FileType) {

        "ts" {
            $Content = Strip-BlockComments $Content
            $Content = Strip-LineComments  $Content
        }

        "tsx" {
            $Content = Strip-JSXComments   $Content
            $Content = Strip-BlockComments $Content
            $Content = Strip-LineComments  $Content
        }

        "css" {
            $Content = Strip-BlockComments $Content
        }

        "go" {
            $Content = Strip-BlockComments $Content
            $Content = Strip-LineComments  $Content
        }
    }

    if ($Content -ne $Original) {
        [System.IO.File]::WriteAllText(
            $FilePath,
            $Content,
            [System.Text.Encoding]::UTF8
        )
    }
}

foreach ($Dir in $SrcDirs) {

    if (-not (Test-Path $Dir)) {
        Write-Host "⚠️  Skipping missing directory: $Dir"
        continue
    }

    Write-Host "`n📁 Scanning: $Dir" -ForegroundColor Blue

    $Files = Get-ChildItem -Path $Dir -Recurse -Include *.css, *.ts, *.tsx, *.go |
        Where-Object { -not (IsIgnoredPath $_.FullName) }

    foreach ($File in $Files) {
        $index = $Files.IndexOf($File) + 1
        Write-Host ("    → {0,3}/{1,3} 🌿 Processing: {2}" -f $index, $Files.Count, $File.FullName)
        Remove-FileComments `
            -FilePath $File.FullName `
            -FileType $File.Extension.TrimStart('.')
    }
    Write-Host ("🚀 Completed processing {0} with {1} files" -f $Dir, $Files.Count) -ForegroundColor Green
    
}

Write-Host "`n✨ Comment removal complete." -ForegroundColor Green
