#
# Apache License 2.0.
# Copyright (c) 2026 OTMC Softwares.
# Contributors: Nguyen Van Trung, OTMC Contributors.
#

. $PSScriptRoot/utils.ps1
EnsureTopDirectory

Write-Host "+++ 📚 Welcome to Source Pusher +++" -ForegroundColor Cyan
Log-Step "🌿 Pushing changes to remote repository..."
git add .
Error-Handler $LASTEXITCODE
git commit -m "Init: Update files"
Error-Handler $LASTEXITCODE
git push
Error-Handler $LASTEXITCODE
Log-Success "Changes pushed successfully."
