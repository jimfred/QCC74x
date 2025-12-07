# QCC748M WS2812 LED Strip Driver Build Script
# This script builds the WS2812 example

# Load common environment setup
. "$PSScriptRoot\..\..\QCCSDK-QCC74x\set-env.ps1"

# Set current directory
Set-Location -Path $PSScriptRoot

# Build configuration (uses defaults from set-env.ps1)
# Override if needed:
# $CHIP = "qcc744"
# $BOARD = "qcc744dk"

Write-Host "======================================" -ForegroundColor Cyan
Write-Host "Building WS2812 LED Strip Driver" -ForegroundColor Cyan
Write-Host "CHIP: $CHIP" -ForegroundColor Green
Write-Host "BOARD: $BOARD" -ForegroundColor Green
Write-Host "SDK: $env:QCC74x_SDK_BASE" -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Cyan

# Clean previous build
Write-Host "`nCleaning previous build..." -ForegroundColor Yellow
& $MAKE_EXE clean

# Build with Ninja
Write-Host "`nBuilding with Ninja..." -ForegroundColor Yellow
& $MAKE_EXE ninja CHIP=$CHIP BOARD=$BOARD

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n======================================" -ForegroundColor Green
    Write-Host "Build SUCCESS!" -ForegroundColor Green
    Write-Host "======================================" -ForegroundColor Green
    Write-Host "`nBuild artifacts location:" -ForegroundColor Cyan
    Write-Host "  .\build\build_out\" -ForegroundColor White
    Write-Host "`nTo monitor serial output:" -ForegroundColor Cyan
    Write-Host "  python -m serial.tools.miniterm COM5 2000000 --filter colorize" -ForegroundColor White
    Write-Host "`nWS2812 Configuration:" -ForegroundColor Cyan
    Write-Host "  Data Pin: GPIO_PIN_2" -ForegroundColor White
    Write-Host "  LED Count: 8" -ForegroundColor White
    Write-Host "  Format: GRB (WS2812)" -ForegroundColor White
} else {
    Write-Host "`n======================================" -ForegroundColor Red
    Write-Host "Build FAILED!" -ForegroundColor Red
    Write-Host "======================================" -ForegroundColor Red
    exit $LASTEXITCODE
}
