#
# Apache License 2.0.
# Copyright (c) 2026 OTMC Softwares.
# Contributors: Nguyen Van Trung, OTMC Contributors.
#

. $PSScriptRoot/utils.ps1
EnsureTopDirectory
$ErrorActionPreference = "Stop"

git rev-parse --is-inside-work-tree *> $null
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Not inside a Git repository." -ForegroundColor Red
    exit 1
}

$updated = @()

Get-ChildItem -Recurse -File -Filter *.sh | ForEach-Object {

    $relative = Resolve-Path -Relative $_.FullName
    $relative = $relative -replace '^[.][\\/]', ''
    $relative = $relative.Replace('\', '/')

    $stage = git ls-files --stage -- "$relative"

    if (-not $stage) {
        Write-Host "Skip (not tracked): $relative" -ForegroundColor DarkGray
        return
    }

    if ($stage.StartsWith("100755")) {
        Write-Host "OK   $relative" -ForegroundColor Green
    }
    else {
        git update-index --chmod=+x -- "$relative"

        if ($LASTEXITCODE -eq 0) {
            Write-Host "FIX  $relative" -ForegroundColor Yellow
            $updated += $relative
        }
    }
}

Write-Host ""

if ($updated.Count -eq 0) {
    Write-Host "✅ No files needed updating." -ForegroundColor Green
    exit 0
}

Write-Host "Updated files:" -ForegroundColor Cyan
$updated | ForEach-Object {
    Write-Host "  - $_"
}

Write-Host ""
git status --short

Write-Host ""
$answer = Read-Host "Commit these changes? (y/N)"

if ($answer -match '^(y|yes)$') {

    $message = Read-Host "Commit message"

    if ([string]::IsNullOrWhiteSpace($message)) {
        $message = "chore: make shell scripts executable"
    }

    git add .

    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ git add failed." -ForegroundColor Red
        exit 1
    }

    git commit -m $message

    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "✅ Commit completed." -ForegroundColor Green
    }
}
else {
    Write-Host "Commit cancelled."
}