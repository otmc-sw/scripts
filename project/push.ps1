#
# Apache License 2.0.
# Copyright (c) 2026 OTMC Softwares.
# Contributors: Nguyen Van Trung, OTMC Contributors.
#

. $PSScriptRoot/utils.ps1
EnsureTopDirectory

function Update-ShellExecutable {
    $updated = git ls-files '*.sh' | ForEach-Object {
        if ((git ls-files --stage -- $_) -match '^100644') {
            git update-index --chmod=+x -- $_
            $_
        }
    }

    if ($updated) {
        Log-Step "♻️ Updated executable bit ..."
        $updated | ForEach-Object { Write-Host "  $_" }
    }
    else {
        Log-Success "All shell scripts are already executable."
    }
}

function Push-Changes {
    Log-Step "🌿 Pushing changes to remote repository..."
    git add .
    Error-Handler $LASTEXITCODE
    git commit -m "Init: Update files"
    Error-Handler $LASTEXITCODE
    git push
    Error-Handler $LASTEXITCODE
    Log-Success "Changes pushed successfully."
}

Write-Host "+++ 📚 Welcome to Source Pusher +++" -ForegroundColor Cyan
Update-ShellExecutable
Push-Changes
