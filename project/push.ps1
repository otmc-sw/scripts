#
# Apache License 2.0.
# Copyright (c) 2026 OTMC Softwares.
# Contributors: Nguyen Van Trung, OTMC Contributors.
#

. $PSScriptRoot/utils.ps1
EnsureTopDirectory

Write-Host "+++ 📚 Welcome to Source Pusher +++" -ForegroundColor Cyan
Write-Host "### 🌿 Pushing changes to remote repository..." -ForegroundColor Blue
git add .
git commit -m "Init: Update files"
git push
Write-Host ">>> 🚀 Changes pushed successfully." -ForegroundColor Green
