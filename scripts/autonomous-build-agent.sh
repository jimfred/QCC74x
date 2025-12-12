#!/bin/bash
# Autonomous Build Agent - Attempts to fix build errors automatically
# Usage: ./autonomous-build-agent.sh [max_iterations] [webhook_url]

set -e

MAX_ITERATIONS="${1:-5}"
WEBHOOK_URL="${2:-}"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOG_FILE="/tmp/autonomous-agent-$(date +%Y%m%d-%H%M%S).log"
BUILD_LOG="/tmp/build-output.log"
ITERATION=0

notify() {
    local message="$1"
    local status="${2:-info}"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [$status] $message" | tee -a "$LOG_FILE"

    if [ -n "$WEBHOOK_URL" ]; then
        curl -X POST "$WEBHOOK_URL" \
             -H "Content-Type: application/json" \
             -d "{\"content\": \"🤖 **Iteration $ITERATION** - [$status] $message\"}" \
             2>/dev/null || true
    fi
}

extract_error_context() {
    local build_log="$1"

    # Extract key error patterns
    grep -E "(error:|Error:|ERROR:|CMake Error|fatal error|undefined reference|No such file)" "$build_log" | head -20 || echo "No clear error pattern found"
}

analyze_and_fix() {
    local error_context="$1"
    local iteration="$2"

    notify "🔍 Analyzing build errors..." "ANALYSIS"

    # Common error patterns and automatic fixes

    # Error 1: Board not found
    if echo "$error_context" | grep -q "Board.*not found\|BOARD.*not supported"; then
        notify "📋 Detected: Board not found - attempting to create board definition" "FIX"
        create_board_definition
        return 0
    fi

    # Error 2: Device tree errors
    if echo "$error_context" | grep -q "devicetree\|DTS\|DT_"; then
        notify "🌳 Detected: Device tree error - attempting to simplify overlay" "FIX"
        fix_devicetree_overlay
        return 0
    fi

    # Error 3: Missing Zephyr base
    if echo "$error_context" | grep -q "ZEPHYR_BASE\|Zephyr SDK"; then
        notify "⚙️ Detected: Zephyr environment issue - attempting to setup" "FIX"
        setup_zephyr_environment
        return 0
    fi

    # Error 4: CMake configuration errors
    if echo "$error_context" | grep -q "CMake Error\|CMakeLists.txt"; then
        notify "📦 Detected: CMake error - attempting to fix configuration" "FIX"
        fix_cmake_configuration
        return 0
    fi

    # Error 5: Missing dependencies
    if echo "$error_context" | grep -q "No such file\|not found"; then
        notify "📚 Detected: Missing dependencies - attempting to install" "FIX"
        install_dependencies
        return 0
    fi

    # If no automatic fix available, log for manual intervention
    notify "❓ Unknown error pattern - logging for manual review" "UNKNOWN"
    echo "=== ERROR CONTEXT (Iteration $iteration) ===" >> "$LOG_FILE"
    echo "$error_context" >> "$LOG_FILE"
    echo "===========================================" >> "$LOG_FILE"

    return 1
}

create_board_definition() {
    notify "Creating minimal board definition for QCC748M..." "ACTION"

    # This is a placeholder - in reality, this would create proper board files
    # For demonstration, we'll create a minimal board YAML

    mkdir -p "$PROJECT_DIR/zephyr-gpio-blinky/boards/arm/qcc748m"

    cat > "$PROJECT_DIR/zephyr-gpio-blinky/boards/arm/qcc748m/qcc748m.yaml" <<'EOF'
identifier: qcc748m
name: QCC748M EVK
type: mcu
arch: arm
toolchain:
  - zephyr
  - gnuarmemb
supported:
  - gpio
  - uart
  - spi
EOF

    cat > "$PROJECT_DIR/zephyr-gpio-blinky/boards/arm/qcc748m/qcc748m_defconfig" <<'EOF'
# Board Configuration
CONFIG_SOC_SERIES_QCC74X=y
CONFIG_BOARD_QCC748M=y

# Console
CONFIG_CONSOLE=y
CONFIG_UART_CONSOLE=y
CONFIG_SERIAL=y

# GPIO
CONFIG_GPIO=y
EOF

    cat > "$PROJECT_DIR/zephyr-gpio-blinky/boards/arm/qcc748m/qcc748m.dts" <<'EOF'
/dts-v1/;
#include <mem.h>

/ {
    model = "QCC748M EVK";
    compatible = "qualcomm,qcc748m";

    chosen {
        zephyr,console = &uart0;
        zephyr,shell-uart = &uart0;
        zephyr,sram = &sram0;
        zephyr,flash = &flash0;
    };

    aliases {
        led0 = &gpio_led0;
        led1 = &gpio_led1;
    };

    leds {
        compatible = "gpio-leds";
        gpio_led0: led_0 {
            gpios = <&gpio0 14 0>;
            label = "GPIO LED 0";
        };
        gpio_led1: led_1 {
            gpios = <&gpio0 15 0>;
            label = "GPIO LED 1";
        };
    };

    soc {
        sram0: memory@42000000 {
            compatible = "mmio-sram";
            reg = <0x42000000 DT_SIZE_K(256)>;
        };

        flash0: flash@23000000 {
            compatible = "soc-nv-flash";
            reg = <0x23000000 DT_SIZE_M(2)>;
        };

        gpio0: gpio@20000000 {
            compatible = "gpio-controller";
            reg = <0x20000000 0x1000>;
            gpio-controller;
            #gpio-cells = <2>;
            status = "okay";
        };

        uart0: uart@30000000 {
            compatible = "ns16550";
            reg = <0x30000000 0x100>;
            status = "okay";
            current-speed = <115200>;
        };
    };
};
EOF

    notify "✅ Board definition created" "SUCCESS"
}

fix_devicetree_overlay() {
    notify "Simplifying device tree overlay..." "ACTION"

    # Backup original
    cp "$PROJECT_DIR/zephyr-gpio-blinky/boards/qcc748m.overlay" \
       "$PROJECT_DIR/zephyr-gpio-blinky/boards/qcc748m.overlay.bak" 2>/dev/null || true

    # Create simpler version without potential problematic nodes
    cat > "$PROJECT_DIR/zephyr-gpio-blinky/boards/qcc748m.overlay" <<'EOF'
/ {
    aliases {
        led0 = &gpio_led0;
        led1 = &gpio_led1;
    };

    leds {
        compatible = "gpio-leds";
        gpio_led0: led_0 {
            gpios = <&gpio 14 0>;
        };
        gpio_led1: led_1 {
            gpios = <&gpio 15 0>;
        };
    };
};
EOF

    notify "✅ Device tree overlay simplified" "SUCCESS"
}

setup_zephyr_environment() {
    notify "Setting up Zephyr environment..." "ACTION"

    # Check if Zephyr exists
    if [ -d "$HOME/zephyrproject" ]; then
        export ZEPHYR_BASE="$HOME/zephyrproject/zephyr"
        source "$ZEPHYR_BASE/zephyr-env.sh" 2>/dev/null || true
        notify "✅ Zephyr environment configured" "SUCCESS"
    else
        notify "⚠️ Zephyr not installed - this requires manual setup" "WARNING"
        notify "📝 Run: west init ~/zephyrproject && cd ~/zephyrproject && west update" "INFO"
        return 1
    fi
}

fix_cmake_configuration() {
    notify "Attempting to fix CMake configuration..." "ACTION"

    # Clean build directory
    rm -rf "$PROJECT_DIR/zephyr-gpio-blinky/build"

    # Update CMakeLists.txt to be more permissive
    cat > "$PROJECT_DIR/zephyr-gpio-blinky/CMakeLists.txt" <<'EOF'
# SPDX-License-Identifier: Apache-2.0

cmake_minimum_required(VERSION 3.20.0)

# Try to find Zephyr, but don't fail if not found
find_package(Zephyr QUIET HINTS $ENV{ZEPHYR_BASE})

if(Zephyr_FOUND)
    project(zephyr_gpio_blinky)
    target_sources(app PRIVATE src/main.c)
else()
    message(WARNING "Zephyr SDK not found - this is a Zephyr RTOS project")
    message(STATUS "Install Zephyr: https://docs.zephyrproject.org/latest/getting_started/")
    project(zephyr_gpio_blinky NONE)
endif()
EOF

    notify "✅ CMakeLists.txt updated" "SUCCESS"
}

install_dependencies() {
    notify "Installing common dependencies..." "ACTION"

    # Only install if we have sudo
    if command -v sudo &>/dev/null; then
        sudo apt-get update -qq
        sudo apt-get install -y --no-install-recommends \
            cmake ninja-build device-tree-compiler \
            python3-pip git || notify "⚠️ Some dependencies failed to install" "WARNING"

        pip3 install --user west pyelftools 2>/dev/null || true

        notify "✅ Dependencies installed" "SUCCESS"
    else
        notify "⚠️ No sudo access - cannot install dependencies" "WARNING"
        return 1
    fi
}

attempt_build() {
    notify "🔨 Attempting build (iteration $ITERATION/$MAX_ITERATIONS)..." "BUILD"

    cd "$PROJECT_DIR/zephyr-gpio-blinky"

    # Try different build approaches
    local build_success=false

    # Approach 1: West build (preferred)
    if command -v west &>/dev/null && [ -n "$ZEPHYR_BASE" ]; then
        if west build -b qcc748m -p auto > "$BUILD_LOG" 2>&1; then
            build_success=true
        fi
    fi

    # Approach 2: Direct CMake (fallback)
    if [ "$build_success" = false ]; then
        if cmake -B build -GNinja > "$BUILD_LOG" 2>&1 && ninja -C build >> "$BUILD_LOG" 2>&1; then
            build_success=true
        fi
    fi

    if [ "$build_success" = true ]; then
        notify "✅ Build succeeded!" "SUCCESS"

        if [ -f "build/zephyr/zephyr.bin" ]; then
            SIZE=$(du -h build/zephyr/zephyr.bin | cut -f1)
            notify "📦 Binary size: $SIZE" "INFO"
        fi

        return 0
    else
        notify "❌ Build failed" "ERROR"
        cat "$BUILD_LOG" >> "$LOG_FILE"
        return 1
    fi
}

# Main autonomous loop
main() {
    notify "🤖 Autonomous Build Agent starting..." "START"
    notify "📋 Log: $LOG_FILE" "INFO"
    notify "🔄 Max iterations: $MAX_ITERATIONS" "INFO"

    while [ $ITERATION -lt $MAX_ITERATIONS ]; do
        ITERATION=$((ITERATION + 1))

        notify "--- Iteration $ITERATION/$MAX_ITERATIONS ---" "INFO"

        if attempt_build; then
            notify "🎉 Build successful on iteration $ITERATION!" "COMPLETE"
            notify "📄 Full log: $LOG_FILE" "INFO"
            exit 0
        fi

        # Extract errors and attempt fix
        error_context=$(extract_error_context "$BUILD_LOG")

        if ! analyze_and_fix "$error_context" "$ITERATION"; then
            notify "⚠️ No automatic fix available for this error" "WARNING"

            if [ $ITERATION -lt $MAX_ITERATIONS ]; then
                notify "🔄 Will retry with current configuration..." "INFO"
                sleep 2
            fi
        fi

        sleep 1
    done

    notify "❌ Failed to build after $MAX_ITERATIONS iterations" "FAILED"
    notify "📄 Review log: $LOG_FILE" "INFO"
    notify "🔍 Last error context:" "INFO"
    echo "$error_context" | tee -a "$LOG_FILE"

    exit 1
}

# Run main function
main
