# QCC74x Embedded Development Repository

## Project Overview

This repository contains embedded firmware projects for the **Qualcomm QCC748M EVK** (Evaluation Kit). It supports multiple embedded frameworks and RTOSes for the QCC743/QCC748M RISC-V microcontrollers.

### Supported Frameworks

- **QCCSDK-QCC74x**: Qualcomm's native SDK (bare metal and lightweight RTOS)
- **Zephyr RTOS**: Open-source, scalable RTOS (when applicable)
- **Custom bare-metal**: Direct hardware programming

### Current Projects

- **WS2812**: High-performance WS2812/WS2812B addressable RGB LED strip driver using SPI+DMA (QCCSDK)

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
├── WS2812/                  # WS2812 LED driver project (QCCSDK)
│   ├── main.cpp             # Main application code
│   ├── Makefile             # Build configuration
│   ├── CMakeLists.txt       # CMake project file
│   ├── proj.conf            # Project settings
│   ├── build.ps1            # PowerShell build script
│   ├── flash_prog_cfg.ini   # Flash programmer configuration
│   └── README.md            # Project-specific documentation
└── [NewProject]/            # Template for new projects
    ├── src/                 # Source files
    ├── include/             # Header files (optional)
    ├── CMakeLists.txt       # Build configuration
    ├── README.md            # Project documentation
    └── [Framework-specific files]
```

## Creating New Projects

### General Project Creation Guidelines

When creating a new project in this repository:

1. **Create a dedicated directory** at the repository root (e.g., `Zephyr_Blinky/`)
2. **Choose the appropriate framework**:
   - **QCCSDK**: Use for Qualcomm-specific features, bare-metal, or lightweight apps
   - **Zephyr RTOS**: Use for portable, RTOS-based applications with threading, networking, etc.
   - **Bare-metal**: Use for minimal, hardware-specific code
3. **Include essential files**:
   - Source code (`main.c`, `main.cpp`, or `src/` directory)
   - Build configuration (`CMakeLists.txt`, `Makefile`, or `prj.conf`)
   - Documentation (`README.md`)
4. **Follow naming conventions**: Use descriptive directory names (e.g., `UART_Shell`, `BLE_Beacon`, `Zephyr_Threading`)

### Creating a QCCSDK Project

Use the existing **WS2812** project as a template:

**Required files:**
- `main.cpp` or `main.c` - Main application
- `Makefile` - Links to QCCSDK build system
- `CMakeLists.txt` - CMake configuration
- `proj.conf` - SDK configuration options
- `README.md` - Project documentation

**Makefile template:**
```makefile
SDK_DEMO_PATH ?= .
QCC74x_SDK_BASE ?= $(SDK_DEMO_PATH)/../../QCCSDK-QCC74x

export QCC74x_SDK_BASE

CHIP ?= qcc743
BOARD ?= qcc743dk
CROSS_COMPILE ?= riscv64-unknown-elf-

include $(QCC74x_SDK_BASE)/project.build
```

**CMakeLists.txt template:**
```cmake
cmake_minimum_required(VERSION 3.15)

include(proj.conf)

find_package(qcc74x_sdk REQUIRED HINTS $ENV{QCC74x_SDK_BASE})

sdk_set_main_file(main.cpp)

project(your_project_name)
```

### Creating a Zephyr RTOS Project

**Prerequisites:**
- Zephyr SDK installed (see [Zephyr Getting Started](https://docs.zephyrproject.org/latest/develop/getting_started/index.html))
- West build tool (`pip install west`)
- Appropriate board configuration for QCC74x (may require custom board definition)

**Required files:**
- `src/main.c` - Application entry point
- `prj.conf` - Zephyr project configuration
- `CMakeLists.txt` - Zephyr CMake configuration
- `README.md` - Project documentation
- `boards/` (optional) - Custom board definitions if QCC74x not in mainline Zephyr

**CMakeLists.txt template (Zephyr):**
```cmake
cmake_minimum_required(VERSION 3.20.0)

find_package(Zephyr REQUIRED HINTS $ENV{ZEPHYR_BASE})
project(zephyr_example)

target_sources(app PRIVATE src/main.c)
```

**prj.conf template:**
```conf
# Zephyr configuration
CONFIG_CONSOLE=y
CONFIG_UART_CONSOLE=y
CONFIG_SERIAL=y
CONFIG_PRINTK=y

# Add your Zephyr features
# CONFIG_GPIO=y
# CONFIG_SPI=y
# CONFIG_I2C=y
```

**Build commands (Zephyr):**
```bash
# Initialize Zephyr environment (first time)
west init -l .
west update

# Build for custom board (may need board definition)
west build -b qcc743dk ./ProjectName

# Flash
west flash
```

**Note on Zephyr support**: The QCC743/QCC748M may not have official Zephyr board support. You may need to:
1. Create a custom board definition in `boards/riscv/qcc743dk/`
2. Define device tree, Kconfig, and board configuration
3. Or use a compatible RISC-V board as a starting point and adapt

### Project Templates

#### Bare-Metal Blinky (QCCSDK)
```
Blinky/
├── main.c
├── Makefile
├── CMakeLists.txt
├── proj.conf
└── README.md
```

#### Zephyr RTOS Example
```
Zephyr_Shell/
├── src/
│   └── main.c
├── boards/               # If custom board needed
│   └── riscv/
│       └── qcc743dk/
├── CMakeLists.txt
├── prj.conf
├── west.yml             # Optional: for dependencies
└── README.md
```

#### Multi-File Project (QCCSDK)
```
Advanced_Driver/
├── src/
│   ├── main.cpp
│   ├── driver.cpp
│   └── utils.cpp
├── include/
│   ├── driver.h
│   └── utils.h
├── Makefile
├── CMakeLists.txt
├── proj.conf
└── README.md
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
- **Creating new projects**: Follow the "Creating New Projects" guidelines above

### Autonomous Project Creation Workflow

When asked to create a new project (e.g., "Create a Zephyr RTOS example"):

1. **Understand requirements**: Clarify project type, framework, and features needed
2. **Choose framework**: Select QCCSDK, Zephyr, or bare-metal based on requirements
3. **Create project structure**:
   - Create new directory with descriptive name
   - Add required files based on framework templates (see "Creating New Projects")
   - Include comprehensive README.md
4. **Implement core functionality**: Write minimal working example
5. **Update CLAUDE.md**: Add new project to "Current Projects" list
6. **Test build configuration**: Ensure build files are syntactically correct
7. **Document**: Provide clear README with build instructions, hardware requirements, and usage

**Example autonomous workflow for "Create a Zephyr blinky example":**

```
1. Create Zephyr_Blinky/ directory
2. Add src/main.c with GPIO toggle code
3. Create prj.conf with CONFIG_GPIO=y
4. Create CMakeLists.txt for Zephyr build
5. Write README.md with setup and build instructions
6. Update CLAUDE.md to list new project
7. Commit all files with descriptive message
```

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
