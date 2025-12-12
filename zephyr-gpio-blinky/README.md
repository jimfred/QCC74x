# Zephyr RTOS Dual-Thread GPIO Blinky

A demonstration of Zephyr RTOS multithreading on the **EVK-QCC748M-2-01-0-AA** board. This example creates two independent threads, each toggling a GPIO pin at different frequencies, perfect for observing with a logic analyzer.

## Features

- **Two Independent Threads** running concurrently under Zephyr RTOS
- **Thread 0**: Toggles GPIO14 at 1Hz (500ms period)
- **Thread 1**: Toggles GPIO15 at 2Hz (250ms period)
- **Logic Analyzer Ready**: Clean square waves for timing verification
- **Device Tree Configuration**: Proper Zephyr GPIO setup
- **Minimal Design**: Simple example demonstrating RTOS threading fundamentals

## Hardware Setup

### GPIO Pin Connections

Connect your logic analyzer to the following pins on the EVK-QCC748M-2-01-0-AA:

| Signal | GPIO Pin | Frequency | Logic Analyzer Channel | Notes |
|--------|----------|-----------|------------------------|-------|
| LED0 | **GPIO14** | 1Hz | Channel 1 | 500ms high, 500ms low |
| LED1 | **GPIO15** | 2Hz | Channel 2 | 250ms high, 250ms low |
| GND | GND | - | Ground | Common ground required |

**Pin Locations:** Refer to your EVK-QCC748M board schematic for GPIO14 and GPIO15 physical locations.

### Customizing GPIO Pins

To use different GPIO pins, edit `boards/qcc748m.overlay`:

```dts
gpio_led0: gpio_led_0 {
    gpios = <&gpio0 14 GPIO_ACTIVE_HIGH>;  // Change 14 to your desired pin
    label = "GPIO LED 0 - 1Hz";
};

gpio_led1: gpio_led_1 {
    gpios = <&gpio0 15 GPIO_ACTIVE_HIGH>;  // Change 15 to your desired pin
    label = "GPIO LED 1 - 2Hz";
};
```

Available GPIO pins: Typically GPIO0-GPIO34 (check your board documentation).

## Prerequisites

### Software Requirements

1. **Zephyr RTOS SDK** installed and configured
   - Follow the [Zephyr Getting Started Guide](https://docs.zephyrproject.org/latest/getting_started/index.html)
   - Install Zephyr SDK and dependencies

2. **West Build Tool** (Zephyr's meta-tool)
   ```bash
   pip install west
   ```

3. **Toolchain for RISC-V** (if QCC748M uses RISC-V) or appropriate architecture
   - Included with Zephyr SDK

4. **Python 3.8+** for build scripts and flashing

### Verify Zephyr Installation

```bash
# Check Zephyr environment
echo $ZEPHYR_BASE

# Verify west is installed
west --version
```

## Building the Project

### Method 1: Using West (Recommended)

```bash
cd zephyr-gpio-blinky

# Build for QCC748M board
west build -b qcc748m -p auto

# The binary will be generated at:
# build/zephyr/zephyr.bin
# build/zephyr/zephyr.elf
```

### Method 2: Using CMake Directly

```bash
cd zephyr-gpio-blinky

# Configure
cmake -B build -GNinja -DBOARD=qcc748m

# Build
ninja -C build

# Output in build/zephyr/
```

### Build Configuration Options

To change thread timing, edit `src/main.c`:

```c
/* Thread 0 timing */
k_msleep(500);  // Change to adjust LED0 frequency

/* Thread 1 timing */
k_msleep(250);  // Change to adjust LED1 frequency
```

To change thread priorities, edit:

```c
#define THREAD0_PRIORITY 7  // Lower number = higher priority
#define THREAD1_PRIORITY 7  // Same priority = time-sliced
```

## Flashing and Running

### Flash to QCC748M EVK

The exact flashing method depends on your QCC748M board setup. Common methods:

#### Option 1: Using West Flash

```bash
west flash
```

#### Option 2: Using QCC Flash Tool

```bash
# Assuming you have the QCC flash programmer
make flash CHIP=qcc748m COMX=COM5  # Adjust COM port
```

#### Option 3: Manual Flash

Refer to your QCC748M board documentation for the specific flash programming tool and method.

### Monitor Serial Output

Connect to the serial console to see application output:

```bash
# Using minicom (Linux/macOS)
minicom -D /dev/ttyUSB0 -b 115200

# Using screen
screen /dev/ttyUSB0 115200

# Using Python serial tools (cross-platform)
python -m serial.tools.miniterm COM5 115200  # Windows
python -m serial.tools.miniterm /dev/ttyUSB0 115200  # Linux
```

**Note:** Baud rate may vary based on your board configuration. Check `prj.conf` or board defaults.

### Expected Output

```
╔════════════════════════════════════════╗
║  Zephyr RTOS Dual-Thread GPIO Blinky  ║
║  EVK-QCC748M-2-01-0-AA                 ║
╚════════════════════════════════════════╝

GPIO devices ready
LED0: GPIO 14 - 1Hz (500ms period)
LED1: GPIO 15 - 2Hz (250ms period)

Connect logic analyzer to observe:
  Channel 1: GPIO 14 (1Hz square wave)
  Channel 2: GPIO 15 (2Hz square wave)

Thread 0 started - GPIO 14 (LED0) toggling at 1Hz
Thread 1 started - GPIO 15 (LED1) toggling at 2Hz
Threads started. Press Ctrl+] to exit monitor.
```

## Logic Analyzer Verification

### Expected Waveforms

When you connect a logic analyzer (such as Saleae Logic, DSLogic, or similar):

- **Channel 1 (GPIO14)**: Square wave with 1 second period
  - High: 500ms
  - Low: 500ms
  - Frequency: 1Hz

- **Channel 2 (GPIO15)**: Square wave with 0.5 second period
  - High: 250ms
  - Low: 250ms
  - Frequency: 2Hz

### Logic Analyzer Settings

- **Sample Rate**: 1 MHz (minimum)
- **Capture Time**: 5+ seconds
- **Trigger**: Rising edge on either channel
- **Voltage**: 3.3V logic levels (QCC748M is typically 3.3V IO)

### What You Should Observe

- Thread 0 and Thread 1 run independently
- GPIO15 toggles exactly twice for each GPIO14 toggle
- Clean square waves with stable timing
- No jitter or timing drift (Zephyr's scheduler maintains precise timing)

## Project Structure

```
zephyr-gpio-blinky/
├── CMakeLists.txt              # Zephyr build configuration
├── prj.conf                    # Zephyr project settings
├── README.md                   # This file
├── boards/
│   └── qcc748m.overlay         # Device tree overlay for GPIO config
└── src/
    └── main.c                  # Application code with two threads
```

## Understanding the Code

### Thread Creation

Threads are created using Zephyr's `K_THREAD_DEFINE` macro:

```c
K_THREAD_DEFINE(thread0_id, STACKSIZE, thread0_entry, NULL, NULL, NULL,
                THREAD0_PRIORITY, 0, 0);
```

- **STACKSIZE**: 1024 bytes per thread
- **Priority**: 7 (cooperative scheduling with same priority)
- **Auto-start**: Threads begin execution automatically

### GPIO Control

Uses Zephyr's devicetree-based GPIO API:

```c
static const struct gpio_dt_spec led0 = GPIO_DT_SPEC_GET(LED0_NODE, gpios);
gpio_pin_configure_dt(&led0, GPIO_OUTPUT_ACTIVE);
gpio_pin_toggle_dt(&led0);
```

### Timing

Zephyr's `k_msleep()` provides millisecond-precision delays:

```c
k_msleep(500);  // Sleep for 500 milliseconds
```

The Zephyr scheduler handles context switching and ensures accurate timing.

## Troubleshooting

### Build Errors

**Error: "ZEPHYR_BASE not set"**
```bash
# Set Zephyr environment
export ZEPHYR_BASE=/path/to/zephyr
source zephyr-env.sh
```

**Error: "Board qcc748m not found"**
- Ensure QCC748M board support is available in your Zephyr installation
- Check `$ZEPHYR_BASE/boards/` for qcc748m board definition
- You may need to add custom board files for QCC748M

**Error: "gpio0 not defined"**
- Check device tree overlay syntax
- Verify GPIO controller name matches your board's DTS files

### Runtime Issues

**No Serial Output**
- Verify correct COM port / TTY device
- Check baud rate (try 115200, 2000000, or board default)
- Ensure UART is enabled in `prj.conf`

**GPIOs Not Toggling**
- Verify GPIO pins are not used by other peripherals
- Check board schematic for pin conflicts
- Ensure GPIO power domain is enabled
- Try different GPIO pins

**Irregular Timing**
- Check if interrupts are affecting scheduling
- Verify thread priorities are set correctly
- Use logic analyzer to measure actual timing

### Logic Analyzer Shows No Signal

- Verify GPIO pin numbers in device tree overlay
- Check ground connection between board and logic analyzer
- Ensure GPIO voltage (3.3V) is within logic analyzer range
- Confirm application is running (check serial console)

## Advanced Customization

### Adding More Threads

To add a third thread:

1. Define thread entry function:
```c
void thread2_entry(void *p1, void *p2, void *p3) {
    /* Thread logic */
}
```

2. Create thread:
```c
K_THREAD_DEFINE(thread2_id, STACKSIZE, thread2_entry, NULL, NULL, NULL,
                THREAD2_PRIORITY, 0, 0);
```

3. Add GPIO in `qcc748m.overlay`:
```dts
gpio_led2: gpio_led_2 {
    gpios = <&gpio0 16 GPIO_ACTIVE_HIGH>;
    label = "GPIO LED 2";
};
```

### Changing Thread Priorities

Edit priority defines to test preemptive scheduling:

```c
#define THREAD0_PRIORITY 5  // Higher priority (lower number)
#define THREAD1_PRIORITY 7  // Lower priority (higher number)
```

Thread 0 will preempt Thread 1 when runnable.

### Using Hardware Timers

For more precise timing, consider using Zephyr's timer API:

```c
#include <zephyr/kernel.h>

static void timer_expiry_fn(struct k_timer *timer_id) {
    gpio_pin_toggle_dt(&led0);
}

K_TIMER_DEFINE(my_timer, timer_expiry_fn, NULL);
k_timer_start(&my_timer, K_MSEC(500), K_MSEC(500));
```

## Technical Details

### Zephyr RTOS Threading Model

- **Cooperative Scheduling**: Threads with same priority yield voluntarily
- **Preemptive Scheduling**: Higher priority threads preempt lower priority
- **Time Slicing**: Optional round-robin for same-priority threads
- **Minimal Latency**: Zephyr is designed for real-time embedded systems

### Memory Usage

- **Thread Stack**: 1024 bytes per thread (configurable)
- **System Stack**: 2048 bytes (see `CONFIG_MAIN_STACK_SIZE`)
- **Code Size**: ~20-40 KB depending on configuration

### Performance Characteristics

- **Context Switch Time**: Microseconds (depends on architecture)
- **Timer Resolution**: 1ms (configurable with `CONFIG_SYS_CLOCK_TICKS_PER_SEC`)
- **Thread Overhead**: Minimal - suitable for resource-constrained devices

## References

- [Zephyr RTOS Documentation](https://docs.zephyrproject.org/)
- [Zephyr Threading Guide](https://docs.zephyrproject.org/latest/kernel/services/threads/index.html)
- [Zephyr GPIO API](https://docs.zephyrproject.org/latest/hardware/peripherals/gpio.html)
- [Device Tree Guide](https://docs.zephyrproject.org/latest/build/dts/index.html)
- [QCC748M EVK Documentation](https://www.qualcomm.com/)

## License

This example follows Zephyr's Apache 2.0 license.

## Support

For issues specific to:
- **Zephyr RTOS**: Check [Zephyr Project GitHub](https://github.com/zephyrproject-rtos/zephyr)
- **QCC748M Board**: Refer to Qualcomm QCC748M documentation
- **This Example**: Open an issue in this repository

## Next Steps

Once you've verified this basic example:
1. Experiment with different thread priorities
2. Add more threads with varying frequencies
3. Implement inter-thread communication (message queues, semaphores)
4. Explore Zephyr's power management features
5. Add UART communication between threads
6. Implement a simple state machine

Happy coding with Zephyr RTOS!
