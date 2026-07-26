#
# Apache License 2.0.
# Copyright (c) 2026 OTMC Softwares.
# Contributors: Nguyen Van Trung, OTMC Contributors.
#

. $PSScriptRoot/utils.ps1
EnsureTopDirectory

Param(
    [Parameter(Mandatory=$true)]
    [string]$Action,

    [string]$TagName,

    [string]$Commit
)

function Info($msg)     { Write-Host $msg -ForegroundColor Blue }
function Success($msg)  { Write-Host $msg -ForegroundColor Green }
function ErrorMsg($msg) { Write-Host $msg -ForegroundColor Red }

Write-Host "+++ 📚 Welcome to Source Tagger +++" -ForegroundColor Cyan

if ($Action -eq "b") {

    if (-not $TagName) {
        ErrorMsg "Tag name is required."
        exit 1
    }

    if (-not $Commit) { $Commit = "HEAD" }

    Info "💡 Force creating tag '$TagName' at commit '$Commit'..."
    git tag -f $TagName $Commit

    Info "⬆️  Force pushing tag..."
    git push origin $TagName --force

    Success "✅ Tag '$TagName' created/updated!"
    exit 0
}

if ($Action -eq "r") {

    if (-not $TagName) {
        ErrorMsg "Tag name is required."
        exit 1
    }

    $CurrentBranch = git rev-parse --abbrev-ref HEAD

    if ($CurrentBranch -ne "main" -and $CurrentBranch -ne "master") {
        ErrorMsg "Can only restore 'main' or 'master' branch, current branch is '$CurrentBranch'"
        exit 1
    }

    Info "🔄 Resetting branch '$CurrentBranch' to tag '$TagName'..."
    git reset --hard $TagName

    Info "⬆️  Force pushing branch..."
    git push origin $CurrentBranch --force

    Success "✅ Branch '$CurrentBranch' reset to '$TagName'!"
    exit 0
}

ErrorMsg "Unknown action '$Action'"
Write-Host "  git-tag.ps1 <b|r> <tag> [commit]"
Write-Host "Example: "
Write-Host "  git-tag.ps1 b v0.1.5"
Write-Host "  git-tag.ps1 r v0.1.5"
exit 1
