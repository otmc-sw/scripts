#
# OTMC License.
# Copyright (c) 2026 OTMC Softwares. All rights reserved.
# Contributors: Trung Ng, OTMC Authors.
#

Write-Host "+++ 📚 Welcome to Source Pusher +++" -ForegroundColor Cyan

Set-Location $PSScriptRoot/..
Write-Host "### 🌿 Pushing changes to remote repository..." -ForegroundColor Blue
git add .
git commit -m "Init: Update files"
git push
Write-Host ">>> 🚀 Changes pushed successfully." -ForegroundColor Green
