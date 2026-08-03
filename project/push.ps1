#
# Apache License 2.0.
# Copyright (c) 2026 OTMC Softwares.
# Contributors: Nguyen Van Trung, OTMC Contributors.
#

. $PSScriptRoot/utils.ps1
EnsureTopDirectory

function Update-ShellExecutable {
    $files = git ls-files '*.sh' | Where-Object {
        (git ls-files --stage -- $_) -match '^100644'
    }

    if (-not $files) {
        Log-Success "All shell scripts are already executable."
        return
    }

    Log-Step "🧩 The following shell scripts will be marked as executable:"
    $files | ForEach-Object { Write-Host "       → 📝 $_" -ForegroundColor DarkYellow }

    if ((Read-Host "`nSet +x for these files? (y/N)") -notmatch '^(?i:y|yes)$') {
        Log-Warning "Cancelled."
        return
    }

    $files | ForEach-Object {
        git update-index --chmod=+x -- $_
    }

    Log-Success "Updated executable bit for $($files.Count) file(s)."
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
