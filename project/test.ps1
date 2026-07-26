#
# Apache License 2.0
# Copyright (c) 2026 OTMC Softwares.
# Contributors: Nguyen Van Trung, Nguyen Thi Hoai, OTMC Contributors.
#

$TOP = $PSScriptRoot + "/.."
$PLAYWRIGHT_DIR = "$TOP/tests/playwright"

Write-Host '╔══════════════════════════════════════════════════╗' -ForegroundColor Cyan
Write-Host '║              Test Manager v1.0                   ║' -ForegroundColor Cyan
Write-Host '╚══════════════════════════════════════════════════╝' -ForegroundColor Cyan

if ($args.Count -gt 0) {
    $option = $args[0]
} else {
    Write-Host ""
    Write-Host "  Select Playwright test type:" -ForegroundColor Yellow
    Write-Host "  1. Run API tests" -ForegroundColor Green
    Write-Host "  2. Run UI tests" -ForegroundColor Green
    Write-Host "  3. Run all tests" -ForegroundColor Green
    Write-Host "  4. Run UI tests in headed mode" -ForegroundColor Green
    Write-Host "  5. Run in debug mode" -ForegroundColor Green
    Write-Host "  6. View test report" -ForegroundColor Green
    $option = Read-Host ">> Select option (1-6)"
}

switch ($option) {
    "1" {
        Write-Host "`nRunning Playwright API tests..." -ForegroundColor Cyan
        Set-Location $PLAYWRIGHT_DIR
        npm run test:api
    }
    "2" {
        Write-Host "`nRunning Playwright UI tests..." -ForegroundColor Cyan
        Set-Location $PLAYWRIGHT_DIR
        npm run test:ui
    }
    "3" {
        Write-Host "`nRunning all Playwright tests..." -ForegroundColor Cyan
        Set-Location $PLAYWRIGHT_DIR
        npm run test:all
    }
    "4" {
        Write-Host "`nRunning Playwright UI tests in headed mode..." -ForegroundColor Cyan
        Set-Location $PLAYWRIGHT_DIR
        npm run test:headed
    }
    "5" {
        Write-Host "`nRunning Playwright in debug mode..." -ForegroundColor Cyan
        Set-Location $PLAYWRIGHT_DIR
        npm run test:debug
    }
    "6" {
        Write-Host "`nOpening Playwright report..." -ForegroundColor Cyan
        Set-Location $PLAYWRIGHT_DIR
        npm run report
    }
    default {
        Write-Host "`nInvalid option: $option" -ForegroundColor Red
        Write-Host "Please select a number between 1-6" -ForegroundColor Yellow
    }
}
