#
# Apache License 2.0.
# Copyright (c) 2026 OTMC Softwares.
# Contributors: Nguyen Van Trung, OTMC Contributors.
#

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
param(
    [switch]$Silent
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$packages = @(
    [pscustomobject]@{
        Name = 'PowerShell'
        Id   = 'Microsoft.PowerShell'
    },
    [pscustomobject]@{
        Name = 'Git'
        Id   = 'Git.Git'
    }
)

# ---------- Prerequisites ----------
Write-Host 'Starting developer tools maintenance.'

$wingetCommand = Get-Command winget.exe -ErrorAction SilentlyContinue

if (-not $wingetCommand) {
    Write-Host 'winget.exe was not found. Install or repair App Installer first.' -ForegroundColor Red
    exit 2
}

try {
    $wingetVersion = & $wingetCommand.Source --version 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw 'winget failed to report its version.'
    }
    Write-Host "Detected winget version: $wingetVersion"
}
catch {
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 2
}

# ---------- Get installed versions ----------
function Get-InstalledVersion {
    param([string]$Id)

    $listOutput = @(
        & $wingetCommand.Source list --id $Id --exact --source winget --accept-source-agreements 2>&1
    )
    $version = $null

    foreach ($line in $listOutput) {
        $fields = @(($line -split '\s+') | Where-Object { $_ -ne '' })
        if (
            $fields.Count -ge 3 -and
            $fields[0] -ne 'Name' -and
            $line -notmatch '^-+$'
        ) {
            $version = $fields[2]
        }
    }

    return $version
}

# ---------- Update packages ----------
$results = [System.Collections.Generic.List[object]]::new()

foreach ($package in $packages) {
    Write-Host ''
    Write-Host "Checking/updating $($package.Name) [$($package.Id)]"

    $arguments = @(
        'upgrade'
        '--id', $package.Id
        '--exact'
        '--source', 'winget'
        '--accept-source-agreements'
        '--accept-package-agreements'
    )

    if ($Silent) {
        $arguments += @('--silent', '--disable-interactivity')
    }

    if ($PSCmdlet.ShouldProcess(
        $package.Name,
        'Check for and install an available update via winget'
    )) {
        try {
            $output = @(& $wingetCommand.Source @arguments 2>&1)
            $exitCode = $LASTEXITCODE

            foreach ($line in $output) {
                Write-Host "  $line"
            }

            # winget returns a non-zero code when "No available upgrade found"
            # (package is already up to date) — treat that as success.
            $noUpdate = ($output -join "`n") -match 'No available upgrade found'
            $success = ($exitCode -eq 0) -or $noUpdate

            if ($success) {
                $results.Add([pscustomobject]@{
                    Package = $package.Name
                    Status  = 'Completed'
                    Details = if ($noUpdate) { 'Already up to date.' } else { 'winget exited successfully; review output above.' }
                })
                Write-Host "$($package.Name): winget completed successfully." -ForegroundColor Green
            }
            else {
                $results.Add([pscustomobject]@{
                    Package = $package.Name
                    Status  = 'Failed'
                    Details = "winget exit code: $exitCode"
                })
                Write-Host "$($package.Name): winget exited with code $exitCode." -ForegroundColor Red
            }
        }
        catch {
            $results.Add([pscustomobject]@{
                Package = $package.Name
                Status  = 'Failed'
                Details = $_.Exception.Message
            })
            Write-Host "$($package.Name): $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    else {
        $results.Add([pscustomobject]@{
            Package = $package.Name
            Status  = 'Skipped'
            Details = 'Previewed or declined by ShouldProcess.'
        })
    }
}

# ---------- Summary ----------
Write-Host "`n========== SUMMARY ==========" -ForegroundColor Cyan

foreach ($package in $packages) {
    $version = Get-InstalledVersion -Id $package.Id
    $versionText = if ($version) { $version } else { 'N/A' }
    Write-Host ("{0,-12} Current version: {1}" -f $package.Name, $versionText)
}

$results | Format-Table -AutoSize

$failed = @($results | Where-Object { $_.Status -eq 'Failed' })
if ($failed.Count -gt 0) {
    exit 1
}

exit 0
