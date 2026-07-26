#
# Apache License 2.0.
# Copyright (c) 2026 OTMC Softwares.
# Contributors: Nguyen Van Trung, OTMC Contributors.
#

Param(
    [Parameter(Mandatory = $true, Position = 0, HelpMessage = "Action: 'b' (build tag) or 'r' (reset branch to tag)")]
    [ValidateSet("b", "r")]
    [string]$Action,

    [Parameter(Mandatory = $true, Position = 1, HelpMessage = "Tag name is required")]
    [ValidateNotNullOrEmpty()]
    [string]$TagName,

    [Parameter(Position = 2)]
    [string]$Commit = "HEAD"
)

. $PSScriptRoot/utils.ps1
EnsureTopDirectory

function Info([string]$msg)    { Write-Host $msg -ForegroundColor Blue }
function Success([string]$msg) { Write-Host $msg -ForegroundColor Green }
function ErrorMsg([string]$msg) { Write-Host $msg -ForegroundColor Red }

function Assert-GitSuccess([string]$errorMessage) {
    if ($LASTEXITCODE -ne 0) {
        ErrorMsg "❌ $errorMessage"
        exit $LASTEXITCODE
    }
}

Write-Host "+++ 📚 Welcome to Source Tagger +++" -ForegroundColor Cyan

switch ($Action) {
    "b" {
        Info "💡 Force creating tag '$TagName' at commit '$Commit'..."
        git tag -f $TagName $Commit
        Assert-GitSuccess "Failed to create tag '$TagName'."

        Info "⬆️  Force pushing tag to origin..."
        git push origin $TagName --force
        Assert-GitSuccess "Failed to push tag '$TagName' to origin."

        Success "✅ Tag '$TagName' created and pushed successfully!"
    }

    "r" {
        $CurrentBranch = (git rev-parse --abbrev-ref HEAD).Trim()
        Assert-GitSuccess "Failed to get current branch."

        if ($CurrentBranch -notmatch "^(main|master)$") {
            ErrorMsg "Can only restore 'main' or 'master' branch. Current branch is '$CurrentBranch'."
            exit 1
        }

        Info "🔄 Resetting branch '$CurrentBranch' to tag '$TagName'..."
        git reset --hard $TagName
        Assert-GitSuccess "Failed to reset branch '$CurrentBranch' to '$TagName'."

        Info "⬆️  Force pushing branch '$CurrentBranch'..."
        git push origin $CurrentBranch --force
        Assert-GitSuccess "Failed to force push branch '$CurrentBranch'."

        Success "✅ Branch '$CurrentBranch' reset and pushed to '$TagName'!"
    }
}

exit 0