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


Write-Host "+++ 📚 Welcome to Source Tagger +++" -ForegroundColor Cyan

switch ($Action) {
    "b" {
        Log-Step "🧩 Creating tag '$TagName' at commit '$Commit'..."
        git tag -f $TagName $Commit
        Error-Handler $LASTEXITCODE

        Log-Step "⬆️  Force pushing tag to origin..."
        git push origin $TagName --force
        Error-Handler $LASTEXITCODE

        Log-Success "Tag '$TagName' created and pushed successfully!"
    }

    "r" {
        $CurrentBranch = (git rev-parse --abbrev-ref HEAD).Trim()
        Error-Handler $LASTEXITCODE

        if ($CurrentBranch -notmatch "^(main|master)$") {
            Log-Error "Can only restore 'main' or 'master' branch. Current branch is '$CurrentBranch'."
            exit 1
        }

        Log-Step "🔄 Resetting branch '$CurrentBranch' to tag '$TagName'..."
        git reset --hard $TagName
        Error-Handler $LASTEXITCODE

        Log-Step "⬆️  Force pushing branch '$CurrentBranch'..."
        git push origin $CurrentBranch --force
        Error-Handler $LASTEXITCODE

        Log-Success "Branch '$CurrentBranch' reset and pushed to '$TagName'."
    }
}

exit 0