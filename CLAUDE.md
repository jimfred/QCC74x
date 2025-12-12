# QCC74x Embedded Development Repository

## Project Overview

This repository contains embedded firmware projects for the **Qualcomm QCC748M EVK** (Evaluation Kit) using the **QCCSDK-QCC74x** SDK. The primary focus is on developing drivers and applications for the QCC743/QCC748M RISC-V microcontrollers.

### Current Projects

- **WS2812**: High-performance WS2812/WS2812B addressable RGB LED strip driver using SPI+DMA

## Hardware Platform

- **Target MCU**: Qualcomm QCC743/QCC748M (RISC-V architecture)
- **Development Board**: QCC743DK evaluation kit
- **Toolchain**: `riscv64-unknown-elf-gcc`
- **SDK**: QCCSDK-QCC74x (expected at `../../QCCSDK-QCC74x` relative to project root)

## Build System

### Prerequisites

**Note**: This repository is designed for local development with the QCCSDK installed. For cloud-based autonomous development:

1. The SDK is typically installed at `../../QCCSDK-QCC74x` relative to this repo
2. Cross-compilation toolchain: `riscv64-unknown-elf-gcc`
3. Build tools: CMake (≥3.15), Ninja, PowerShell (for build scripts)

### Build Commands

```bash
# Build a project (e.g., WS2812)
cd WS2812
make CHIP=qcc743

# Or use the PowerShell build script (if available)
./build.ps1

# Flash firmware to board (requires serial connection)
make flash CHIP=qcc743 COMX=COM5

# Monitor serial output
python -m serial.tools.miniterm COM5 2000000 --filter colorize
```

### Build Configuration

- **Makefile**: Sets up SDK path, chip selection, and includes SDK build system
- **CMakeLists.txt**: CMake configuration for each project
- **proj.conf**: Project-specific configuration (libc settings, logging, etc.)
- **build.ps1**: PowerShell build automation script

### Important Environment Variables

- `QCC74x_SDK_BASE`: Path to QCCSDK-QCC74x SDK (default: `../../QCCSDK-QCC74x`)
- `CHIP`: Target chip variant (default: `qcc743`)
- `BOARD`: Board variant (default: `qcc743dk`)
- `CROSS_COMPILE`: Toolchain prefix (default: `riscv64-unknown-elf-`)

## Project Structure

```
QCC74x/
├── CLAUDE.md                 # This file - project documentation for autonomous AI
├── .gitignore               # Git ignore rules
└── WS2812/                  # WS2812 LED driver project
    ├── main.cpp             # Main application code
    ├── Makefile             # Build configuration
    ├── CMakeLists.txt       # CMake project file
    ├── proj.conf            # Project settings
    ├── build.ps1            # PowerShell build script
    ├── flash_prog_cfg.ini   # Flash programmer configuration
    └── README.md            # Project-specific documentation
```

## Coding Conventions

### C/C++ Style

- **Language**: C++ with C SDK headers wrapped in `extern "C"`
- **Headers**: SDK headers from `qcc74x_*.h` (GPIO, SPI, DMA, timer, etc.)
- **Logging**: Use `log.h` with `DBG_TAG` macro for component-specific logging
- **Naming**:
  - Functions: `lowercase_with_underscores`
  - Macros/defines: `UPPERCASE_WITH_UNDERSCORES`
  - Types/classes: `PascalCase` or `lowercase_t`

### Hardware Abstraction

- GPIO pins use `GPIO_PIN_x` constants
- Peripheral initialization follows SDK patterns (e.g., `qcc74x_spi_init`)
- Use SDK delay functions: `qcc74x_mtimer_delay_ms()`, `qcc74x_mtimer_delay_us()`

## Development Workflow

### For Cloud-Based Autonomous Development

**Important**: Since this is an embedded project requiring physical hardware:

1. **Code Development**: Can be done autonomously in the cloud
2. **Building**: Requires QCCSDK toolchain (may need setup in cloud environment)
3. **Flashing/Testing**: Requires physical QCC748M EVK hardware (cannot be done in cloud)

### Typical Development Tasks

- **Adding new features**: Modify `main.cpp` or create new source files
- **Changing hardware config**: Update pin definitions and peripheral initialization
- **Adjusting project settings**: Edit `proj.conf` for SDK features
- **Build system changes**: Modify `Makefile` or `CMakeLists.txt`
- **Documentation**: Update project README.md files

## Common Issues & Solutions

### Build Issues

- **SDK not found**: Ensure `QCC74x_SDK_BASE` points to valid SDK installation
- **Toolchain errors**: Verify `riscv64-unknown-elf-gcc` is in PATH
- **CMake version**: Requires CMake ≥3.15

### Hardware Issues

- **LEDs not working**: Check power supply, GPIO pin connections, timing constants
- **Serial output**: Use correct baud rate (typically 2000000) and colorize filter

## Testing

Since this is embedded firmware:

- **Unit tests**: Not currently implemented (requires embedded testing framework)
- **Hardware testing**: Requires physical board and peripherals
- **Build verification**: Can be done by running `make` in project directories

## Git Workflow

- **Main branch**: Production-ready code
- **Feature branches**: Use `claude/*` prefix for autonomous development branches
- **Commit messages**: Clear, descriptive messages following conventional commits style

## Additional Resources

- **WS2812 Project**: See `WS2812/README.md` for detailed driver documentation
- **QCCSDK Documentation**: Refer to SDK installation at `../../QCCSDK-QCC74x/`
- **WS2812B Datasheet**: [Adafruit WS2812B Datasheet](https://cdn-shop.adafruit.com/datasheets/WS2812B.pdf)

## Notes for Autonomous Development

When working autonomously on this repository:

1. **Focus on code quality**: Follow existing patterns and conventions
2. **Document changes**: Update README files and code comments
3. **Build verification**: Attempt builds when possible (toolchain permitting)
4. **Hardware awareness**: Remember that final testing requires physical hardware
5. **SDK integration**: Respect SDK APIs and patterns from QCCSDK-QCC74x
6. **Cross-platform**: Build scripts are PowerShell-based (Windows-focused)

## Environment Setup for Cloud Development

If working in a cloud environment (e.g., Claude Code on the web):

```bash
# Install basic build tools
apt-get update && apt-get install -y cmake ninja-build python3 python3-pip

# Install serial terminal for monitoring (optional)
pip3 install pyserial

# Note: RISC-V toolchain and QCCSDK would need to be installed separately
# This may not be practical for cloud-only development environments
```

**Recommendation**: Use cloud development primarily for code editing, documentation, and architecture design. Physical hardware testing requires local environment.
