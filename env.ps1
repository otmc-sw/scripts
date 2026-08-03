#
# Apache License 2.0.
# Copyright (c) 2026 OTMC Softwares.
# Contributors: Nguyen Van Trung, OTMC Contributors.
#


$global:TOP = Get-Location

function e   { Set-Location $TOP; & "$TOP\env.ps1" @args }
function s   { Set-Location $TOP; & "$TOP\project\setup.ps1" @args }
function run { Set-Location $TOP; & "$TOP\project\run.ps1" @args }
function t   { Set-Location $TOP; & "$TOP\project\test.ps1" @args }
function p   { Set-Location $TOP; & "$TOP\project\push.ps1" @args }
function f   { Set-Location $TOP; & "$TOP\project\format.ps1" @args }
function b   { Set-Location $TOP; & "$TOP\project\build.ps1" @args }
function tag { Set-Location $TOP; & "$TOP\project\tag.ps1" @args }
function u   { Set-Location $TOP; & "$TOP\project\upgrade.ps1" @args }

Write-Host ""
Write-Host "   >>> Environment Loaded on Windows!" -ForegroundColor Blue
Write-Host "   >>> Source directory: '$TOP'" -ForegroundColor Blue
Write-Host ""

