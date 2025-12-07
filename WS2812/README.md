# WS2812 LED Strip Driver for QCC748M EVK

A high-performance WS2812/WS2812B addressable RGB LED strip driver for the Qualcomm QCC748M EVK using the QCCSDK. This implementation uses **SPI with DMA** for reliable, CPU-efficient LED control.

## Features

- **SPI-based WS2812 protocol** (not bit-banging) for reliable timing
- **DMA transfers** for CPU efficiency - no blocking or timing-critical code
- **Continuous SPI mode** eliminates inter-byte gaps
- **4-bit encoding** for perfect byte alignment
- **8 LEDs** (configurable via `NUM_LEDS`)
- **C++ implementation** with simple RGB API
- **Demo animation** - Color shifting and cycling effects
- **Full brightness support** across all LEDs

## Technical Implementation

### SPI Encoding Details

The WS2812 protocol is implemented using SPI at 2.4 MHz with a 4-bit encoding scheme:

- **WS2812 '0' bit** → SPI pattern `1000` (0.4µs high + 0.85µs low)
- **WS2812 '1' bit** → SPI pattern `1100` (0.8µs high + 0.45µs low)
- **LSB bit order** required for proper operation
- **Continuous SPI mode** enabled to eliminate inter-byte gaps
- Each WS2812 byte (8 bits) → 32 SPI bits (4 bytes)
- Total buffer: 96 bytes for 8 LEDs (12 bytes per LED)

### Why 4-bit Encoding?

The 4-bit encoding ensures perfect byte alignment at SPI boundaries:
- Eliminates bit-shift corruption that occurs with 3-bit encoding
- No timing drift across multiple LEDs
- Works reliably at full brightness (255) on all channels
- Compatible with continuous SPI mode

### Color Format

WS2812 LEDs use **GRB order** (Green, Red, Blue), not RGB. The encoding functions handle this automatically.

## Hardware Setup

### WS2812 LED Strip Connections

| WS2812 Wire | QCC748M Pin | Notes |
|-------------|-------------|-------|
| Data (DI) | **GPIO27 (SPI MOSI)** | Fixed - SPI MOSI pin |
| GND | GND | Common ground required |
| VCC (5V) | 5V | Use external power supply (see below) |

**Note:** GPIO27 is the hardware SPI MOSI pin and cannot be changed without modifying the SPI peripheral configuration.

### Power Requirements

**Important:** WS2812 LEDs can draw significant current:
- Each LED: ~60mA at full white brightness
- 8 LEDs at full brightness: ~480mA

**Recommendations:**
- For testing: Small LED counts may work on EVK power
- For production: Use external 5V power supply rated for total LED current
- Always connect GND between EVK and external power supply
- This implementation supports full brightness (255) on all channels

## Building the Project

### Prerequisites

- QCCSDK-QCC74x installed
- PowerShell environment configured
- Toolchain in PATH (set via `set-env.ps1`)

### Build Steps

```powershell
cd .\WS2812
.\build.ps1
```

The build script will:
1. Clean previous builds
2. Configure CMake
3. Build with Ninja
4. Generate `build\build_out\ws2812_qcc743.bin`

## Flashing and Running

1. **Flash the firmware** to your QCC748M EVK
   ```powershell 
   make flash CHIP=qcc743 COMX=COM5
   ```
3. **Connect your serial terminal:**
   ```powershell
   python -m serial.tools.miniterm COM5 2000000 --filter colorize
   ```

   Press `Ctrl+]` to exit miniterm

4. **Expected Output:**
   ```
   ╔════════════════════════════════════════╗
   ║  WS2812 LED Strip Driver Demo         ║
   ║  QCC748M EVK                           ║
   ╚════════════════════════════════════════╝

   [I][WS2812] WS2812 initialized on GPIO_PIN_2
   [TEST] Testing RGB colors...
   [DEMO] Rainbow cycle...
   ```

## Configuration

### Change Number of LEDs

Edit `main.cpp`:
```cpp
#define NUM_LEDS        8           // Change to your LED count
```

### Change Data Pin

Edit `main.cpp`:
```cpp
#define WS2812_PIN      GPIO_PIN_2  // Change to your desired pin
```

Available GPIO pins on QCC748M EVK: GPIO_PIN_0 through GPIO_PIN_34 (check your board schematic for availability)

### Adjust Timing

If LEDs don't respond correctly or colors are wrong, adjust timing constants in `main.cpp`:

```cpp
// Timing in CPU cycles (for 320MHz CPU)
#define T0H_CYCLES  128   // 0 bit HIGH time
#define T0L_CYCLES  272   // 0 bit LOW time
#define T1H_CYCLES  256   // 1 bit HIGH time
#define T1L_CYCLES  144   // 1 bit LOW time
```

The `/4` divisor in the delay functions may need tuning based on actual CPU frequency.

## API Reference

### Core Functions

```cpp
// Initialize WS2812 (call once in setup)
void ws2812_init();

// Set individual LED color (0-indexed)
void ws2812_set_led(uint8_t index, const RGB& color);

// Update LED strip (displays buffered colors)
void ws2812_show();

// Clear all LEDs (black)
void ws2812_clear();

// Set all LEDs to same color
void ws2812_fill(const RGB& color);
```

### RGB Color Class

```cpp
// Create colors
RGB red(255, 0, 0);
RGB green(0, 255, 0);
RGB blue(0, 0, 255);
RGB white(255, 255, 255);
RGB custom(128, 64, 32);

// Set LED
ws2812_set_led(0, red);
ws2812_show();
```

### Example: Custom Animation

```cpp
void my_animation() {
    // Fade red across strip
    for (uint8_t i = 0; i < NUM_LEDS; i++) {
        uint8_t brightness = (i * 255) / NUM_LEDS;
        ws2812_set_led(i, RGB(brightness, 0, 0));
    }
    ws2812_show();
    qcc74x_mtimer_delay_ms(100);
}
```

## Demo Animations

### Rainbow Cycle
Creates a moving rainbow effect using HSV to RGB conversion. Colors smoothly transition across the LED strip.

### Knight Rider
Simulates the iconic KITT scanner from Knight Rider with a red LED bouncing back and forth with trailing fade.

### Color Wipe
Sequentially fills the strip with red, then green, then blue, creating a "wiping" effect.

## Troubleshooting

### LEDs Don't Light Up
- ✅ Check power connections (5V and GND)
- ✅ Verify data wire connected to GPIO_PIN_2
- ✅ Ensure common ground between EVK and LED strip power
- ✅ Try lowering `NUM_LEDS` to test with fewer LEDs
- ✅ Check if your strip is WS2812B (most common, compatible)

### Wrong Colors / Flickering
- ⚙️ Adjust timing constants (T0H, T0L, T1H, T1L)
- ⚙️ Check CPU frequency matches timing calibration (320MHz expected)
- ⚙️ Verify your strip uses GRB format (most WS2812 do)
- ⚙️ Add a small resistor (220-470Ω) on data line if signal integrity is poor
- ⚙️ Keep data wire short (<1m for best results)

### Build Errors
- 📋 Ensure `CMakeLists.txt` and `proj.conf` exist
- 📋 Check SDK path in `Makefile`: `QCC74x_SDK_BASE`
- 📋 Verify environment loaded: `. ..\..\QCCSDK-QCC74x\set-env.ps1`

### Serial Output Shows Escape Codes
Use the `--filter colorize` option:
```powershell
python -m serial.tools.miniterm COM5 2000000 --filter colorize
```

## Technical Details

### WS2812 Protocol
- **Data Format:** GRB (Green-Red-Blue) per LED
- **Bit Encoding:** PWM (Pulse Width Modulation)
  - 0 bit: 0.4µs HIGH, 0.85µs LOW
  - 1 bit: 0.8µs HIGH, 0.45µs LOW
- **Reset:** >50µs LOW
- **Data Rate:** 800kHz

### Timing Precision
The driver uses inline assembly delays for precise timing. Interrupts are not disabled in the current implementation, relying on WS2812's timing tolerance (±150ns typical).

For critical applications requiring perfect timing:
- Consider disabling interrupts during transmission
- Use DMA + SPI/I2S for hardware-based timing
- Add buffering for interrupt-safe updates

## Project Structure

```
WS2812/
├── main.cpp          # Main application and WS2812 driver
├── CMakeLists.txt    # CMake configuration
├── proj.conf         # Project settings
├── Makefile          # Build configuration
├── build.ps1         # Build script
├── README.md         # This file
└── build/
    └── build_out/
        ├── ws2812_qcc743.elf   # Firmware (ELF)
        ├── ws2812_qcc743.bin   # Firmware (binary)
        └── ws2812_qcc743.asm   # Disassembly
```

## License

This project uses the QCCSDK which has its own licensing terms. Check the SDK documentation for details.

## References

- [WS2812B Datasheet](https://cdn-shop.adafruit.com/datasheets/WS2812B.pdf)
- [QCC74x SDK Documentation](../../QCCSDK-QCC74x/)
- [FastLED Library](https://github.com/FastLED/FastLED) - For inspiration

## Credits

Created for the Qualcomm QCC748M EVK using the QCCSDK-QCC74x SDK.
