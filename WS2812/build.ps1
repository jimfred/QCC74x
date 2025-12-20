# QCC748M WS2812 LED Strip Driver Build Script
# This script builds the WS2812 example

param(
    [switch]$Clean,
    [switch]$Flash,
    [switch]$Mon,
    [switch]$Help,
    [string]$ComPort = "COM5"
)

# Display help if requested
if ($Help) {
    Write-Host "QCC748M WS2812 LED Strip Driver Build Script" -ForegroundColor Cyan
    Write-Host "============================================="
    Write-Host ""
    Write-Host "Usage:" -ForegroundColor Yellow
    Write-Host "  .\build.ps1 [options]"
    Write-Host ""
    Write-Host "Options:" -ForegroundColor Yellow
    Write-Host "  -Clean          Clean build directory only (no build)"
    Write-Host "  -Flash          Flash/download firmware after build"
    Write-Host "  -Mon            Start serial monitor after build/flash"
    Write-Host "  -ComPort <port> Serial port (default: COM5)"
    Write-Host "  -Help           Display this help message"
    Write-Host ""
    Write-Host "Examples:" -ForegroundColor Yellow
    Write-Host "  .\build.ps1                    Build only"
    Write-Host "  .\build.ps1 -Clean             Clean only"
    Write-Host "  .\build.ps1 -Flash             Build and flash"
    Write-Host "  .\build.ps1 -Flash -Mon        Build, flash, and monitor"
    Write-Host "  .\build.ps1 -Mon -ComPort COM3 Build and monitor on COM3"
    Write-Host ""
    exit 0
}

# SDK path
$SDK_BASE = "$PSScriptRoot\..\..\QCCSDK-QCC74x"

# Load common environment setup
$SetEnvScript = "$SDK_BASE\set-env.ps1"
if (-not (Test-Path $SetEnvScript)) {
    Write-Host "ERROR: SDK not found at $SDK_BASE" -ForegroundColor Red
    Write-Host "Please verify the SDK location." -ForegroundColor Red
    exit 1
}

# Use 'dot sourcing' to load environment setup (this sets PATH with toolchain)
. $SetEnvScript

# Verify make is available
if (-not $MAKE_EXE -or -not (Test-Path $MAKE_EXE)) {
    Write-Host "ERROR: Make executable not found." -ForegroundColor Red
    Write-Host "Expected at: $MAKE_EXE" -ForegroundColor Red
    Write-Host "Please verify the SDK installation." -ForegroundColor Red
    exit 1
}

# Set current directory to this script's location.
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

# Clean if requested
if ($Clean) {
    Write-Host "`nCleaning build directory..." -ForegroundColor Yellow
    & $MAKE_EXE clean
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Clean complete." -ForegroundColor Green
    }
    exit $LASTEXITCODE
}

# Build with Ninja
Write-Host "`nBuilding with Ninja..." -ForegroundColor Yellow
& $MAKE_EXE ninja CHIP=$CHIP BOARD=$BOARD

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n======================================" -ForegroundColor Green
    Write-Host "Build SUCCESS!" -ForegroundColor Green
    Write-Host "======================================" -ForegroundColor Green
    Write-Host "`nBuild artifacts location:" -ForegroundColor Cyan
    Write-Host "  .\build\build_out\" -ForegroundColor White
    
    # Flash if requested
    if ($Flash) {
        Write-Host "`nFlashing to device on $ComPort..." -ForegroundColor Yellow
        & $MAKE_EXE flash COMX=$ComPort CHIP=$CHIP BOARD=$BOARD
        if ($LASTEXITCODE -eq 0) {
            Write-Host "`n======================================" -ForegroundColor Green
            Write-Host "Flash SUCCESS!" -ForegroundColor Green
            Write-Host "======================================" -ForegroundColor Green
        } else {
            Write-Host "`n======================================" -ForegroundColor Red
            Write-Host "Flash FAILED!" -ForegroundColor Red
            Write-Host "======================================" -ForegroundColor Red
            exit $LASTEXITCODE
        }
    }
    
    # Monitor serial output if requested
    if ($Mon) {
        Write-Host "\nStarting serial monitor on $ComPort..." -ForegroundColor Yellow
        Write-Host "Press Ctrl+] to exit\n" -ForegroundColor Yellow
        python -m serial.tools.miniterm $ComPort 2000000 --filter colorize
    } else {
        Write-Host "\nTo monitor serial output:" -ForegroundColor Cyan
        Write-Host "  python -m serial.tools.miniterm $ComPort 2000000 --filter colorize" -ForegroundColor White
        Write-Host "\nWS2812 Configuration:" -ForegroundColor Cyan
        Write-Host "  Data Pin: GPIO_PIN_2" -ForegroundColor White
        Write-Host "  LED Count: 8" -ForegroundColor White
        Write-Host "  Format: GRB (WS2812)" -ForegroundColor White
    }
} else {
    Write-Host "`n======================================" -ForegroundColor Red
    Write-Host "Build FAILED!" -ForegroundColor Red
    Write-Host "======================================" -ForegroundColor Red
    exit $LASTEXITCODE
}
