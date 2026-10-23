#
# Apache License 2.0.
# Copyright (c) 2026 OTMC Softwares.
# Contributors: Nguyen Van Trung, OTMC Contributors.
#

Param(
    [Parameter(Position = 0, HelpMessage = "Action: 'b' (build tag) or 'r' (reset branch to tag). Defaults to 'b' if not specified.")]
    [ValidateSet("b", "r")]
    [string]$Action = "b",

    [Parameter(Mandatory = $false, Position = 1, HelpMessage = "Tag name (Optional, auto-increments if empty)")]
    [string]$TagName = "",

    [Parameter(Position = 2)]
    [string]$Commit = "HEAD"
)

. $PSScriptRoot/utils.ps1
EnsureTopDirectory

Write-Host "+++ 📚 Welcome to Source Tagger +++" -ForegroundColor Cyan

if ([string]::IsNullOrWhiteSpace($TagName)) {
    Log-Step "🔍 Fetching tags from origin..."
    git fetch --tags origin | Out-Null

    $LatestTag = git tag --sort=-v:refname | Select-Object -First 1

    if ([string]::IsNullOrWhiteSpace($LatestTag)) {
        $TagName = "v0.0.1"
        Log-Warn "No tags found in repository. Defaulting to '$TagName'."
    } else {

        if ($LatestTag -match '^(.*?)(?<number>\d+)([^0-9]*)$') {
            $Prefix = $Matches[1]
            $Number = [int]$Matches['number'] + 1
            $Suffix = $Matches[3]

            $PaddingLength = $Matches['number'].Length
            $FormattedNumber = $Number.ToString("D$PaddingLength")

            $TagName = "${Prefix}${FormattedNumber}${Suffix}"
        } else {
            $TagName = "${LatestTag}.1"
        }
        Write-Host "📌 Latest remote tag detected: '$LatestTag' -> Suggested new tag: '$TagName'" -ForegroundColor Yellow
    }

    $Confirmation = Read-Host "❓ Confirm to use auto-generated tag '$TagName'? (y/n)"
    if ($Confirmation -notmatch '^(y|yes)$') {
        Log-Error "Operation cancelled by user."
        exit 1
    }
}

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