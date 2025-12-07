/**
 * @file main.cpp
 * @brief WS2812/WS2812B LED Strip Controller for QCC748M EVK
 * 
 * This implementation uses SPI with DMA to drive WS2812 addressable RGB LEDs.
 * The WS2812 protocol is encoded using 4 SPI bits per WS2812 bit at 2.4 MHz.
 * 
 * Key Features:
 * - SPI-based encoding (not bit-banging) for reliable timing
 * - DMA transfers for CPU efficiency
 * - Continuous SPI mode eliminates inter-byte gaps
 * - 4-bit encoding: WS2812 '0' = 1000, WS2812 '1' = 1100
 * - LSB bit order required for proper operation
 * - Supports 8 LEDs (configurable via NUM_LEDS)
 * 
 * Hardware Connections (QCC748M EVK):
 * - GPIO27 (SPI MOSI) -> WS2812 Data In
 * - GND -> WS2812 GND
 * - 5V (external supply recommended) -> WS2812 VCC
 * 
 * Technical Details:
 * - SPI frequency: 2.4 MHz (~417ns per bit)
 * - WS2812 timing: '0' = 0.4µs high + 0.85µs low
 *                   '1' = 0.8µs high + 0.45µs low
 * - Encoding: Each WS2812 byte (8 bits) -> 32 SPI bits (4 bytes)
 * - Color format: GRB order (Green, Red, Blue)
 * - Buffer size: 96 bytes for 8 LEDs (12 bytes per LED)
 * 
 * @date December 2025
 */

extern "C" {
    #include "qcc74x_gpio.h"
    #include "qcc74x_spi.h"
    #include "qcc74x_dma.h"
    #include "qcc74x_mtimer.h"
    #include "board.h"
    #define DBG_TAG "WS2812"
    #include "log.h"
}

// SPI Configuration
#define SPI_PIN_MOSI    GPIO_PIN_27
#define SPI_PIN_CLK     GPIO_PIN_29
#define SPI_FREQUENCY   2400000  // 2.4 MHz

// WS2812 Configuration
#define NUM_LEDS        8        // Number of WS2812 LEDs
#define BYTES_PER_LED   12       // 24 bits * 4 SPI bits per WS2812 bit / 8 = 12 bytes
#define SPI_BUFFER_SIZE (NUM_LEDS * BYTES_PER_LED)

// WS2812 encoding patterns (4 SPI bits per WS2812 bit - required for continuous SPI mode)
// At 2.4 MHz SPI: each bit is ~417ns
// WS2812 '0': 0.4µs HIGH + 0.85µs LOW  → SPI pattern: 1000 (1 bit high, 3 bits low)
// WS2812 '1': 0.8µs HIGH + 0.45µs LOW  → SPI pattern: 1100 (2 bits high, 2 bits low)
#define WS2812_0  0b1000
#define WS2812_1  0b1100

// Color structure (RGB format)
typedef struct {
    uint8_t r;
    uint8_t g;
    uint8_t b;
} ws2812_color_t;

// LED color array
static ws2812_color_t led_colors[NUM_LEDS];

// SPI transmit buffer with DMA-safe memory attribute
static ATTR_NOCACHE_NOINIT_RAM_SECTION uint8_t spi_buffer[SPI_BUFFER_SIZE];

struct qcc74x_device_s *spi0;
struct qcc74x_device_s *dma0_ch0;
struct qcc74x_dma_channel_lli_pool_s tx_llipool[1];

// Initialize SPI
void spi_init() {
    // Initialize GPIO for SPI
    struct qcc74x_device_s *gpio = qcc74x_device_get_by_name("gpio");
    
    // SPI CLK
    qcc74x_gpio_init(gpio, SPI_PIN_CLK, GPIO_FUNC_SPI0 | GPIO_ALTERNATE | GPIO_FLOAT | GPIO_SMT_EN | GPIO_DRV_1);
    // SPI MOSI (data out)
    qcc74x_gpio_init(gpio, SPI_PIN_MOSI, GPIO_FUNC_SPI0 | GPIO_ALTERNATE | GPIO_FLOAT | GPIO_SMT_EN | GPIO_DRV_1);
    
    // Get SPI device
    spi0 = qcc74x_device_get_by_name("spi0");
    
    // Configure SPI
    struct qcc74x_spi_config_s spi_cfg = {
        .freq = SPI_FREQUENCY,
        .role = SPI_ROLE_MASTER,
        .mode = SPI_MODE0,                  // CPOL=0, CPHA=0
        .data_width = SPI_DATA_WIDTH_8BIT,
        .bit_order = SPI_BIT_LSB,           // Try LSB first
        .byte_order = SPI_BYTE_LSB,
        .tx_fifo_threshold = 0,
        .rx_fifo_threshold = 0,
    };
    
    qcc74x_spi_init(spi0, &spi_cfg);
    qcc74x_spi_link_txdma(spi0, true);
    
    // Enable continuous mode to eliminate inter-byte gaps
    qcc74x_spi_feature_control(spi0, SPI_CMD_SET_CS_INTERVAL, 1);
    
    LOG_I("SPI initialized at %d Hz (continuous mode)\r\n", SPI_FREQUENCY);
    LOG_I("MOSI: GPIO%d, CLK: GPIO%d\r\n", SPI_PIN_MOSI, SPI_PIN_CLK);
}

// Initialize DMA
void dma_init() {
    // Get DMA device
    dma0_ch0 = qcc74x_device_get_by_name("dma0_ch0");
    
    // Configure DMA
    struct qcc74x_dma_channel_config_s dma_cfg = {
        .direction = DMA_MEMORY_TO_PERIPH,
        .src_req = DMA_REQUEST_NONE,
        .dst_req = DMA_REQUEST_SPI0_TX,
        .src_addr_inc = DMA_ADDR_INCREMENT_ENABLE,
        .dst_addr_inc = DMA_ADDR_INCREMENT_DISABLE,
        .src_burst_count = DMA_BURST_INCR1,
        .dst_burst_count = DMA_BURST_INCR1,
        .src_width = DMA_DATA_WIDTH_8BIT,
        .dst_width = DMA_DATA_WIDTH_8BIT,
    };
    
    qcc74x_dma_channel_init(dma0_ch0, &dma_cfg);
    
    LOG_I("DMA initialized for SPI TX (polling mode)\r\n");
}

// Encode a single byte into WS2812 SPI format (4 bytes output)
// Each bit becomes 4 SPI bits: 0→1000, 1→1100
void encode_byte_to_ws2812(uint8_t byte, uint8_t *out) {
    uint32_t encoded = 0;
    
    // Process each bit (MSB first)
    for (int i = 0; i < 8; i++) {
        encoded <<= 4;  // Make room for 4 SPI bits
        if (byte & 0x80) {
            encoded |= WS2812_1;  // 1100
        } else {
            encoded |= WS2812_0;  // 1000
        }
        byte <<= 1;
    }
    
    // Write 32 bits (4 bytes) in big-endian order
    out[0] = (encoded >> 24) & 0xFF;
    out[1] = (encoded >> 16) & 0xFF;
    out[2] = (encoded >> 8) & 0xFF;
    out[3] = encoded & 0xFF;
}

// Encode all LED colors into SPI buffer
// WS2812 format: GRB order (Green, Red, Blue)
void encode_leds_to_spi() {
    uint8_t *ptr = spi_buffer;
    
    for (int i = 0; i < NUM_LEDS; i++) {
        // WS2812 uses GRB order, not RGB
        encode_byte_to_ws2812(led_colors[i].g, ptr);
        ptr += 4;
        encode_byte_to_ws2812(led_colors[i].r, ptr);
        ptr += 4;
        encode_byte_to_ws2812(led_colors[i].b, ptr);
        ptr += 4;
    }
}

// Set a single LED color
void set_led_color(uint8_t index, uint8_t r, uint8_t g, uint8_t b) {
    if (index < NUM_LEDS) {
        led_colors[index].r = r;
        led_colors[index].g = g;
        led_colors[index].b = b;
    }
}

// Set all LEDs to the same color
void set_all_leds(uint8_t r, uint8_t g, uint8_t b) {
    for (int i = 0; i < NUM_LEDS; i++) {
        set_led_color(i, r, g, b);
    }
}

// Update and send LED data
void ws2812_show() {
    struct qcc74x_dma_channel_lli_transfer_s transfer;
    
    // Ensure line is LOW before starting (reset condition)
    qcc74x_mtimer_delay_us(100);
    
    // Encode LED colors to SPI format
    encode_leds_to_spi();
    
    transfer.src_addr = (uint32_t)spi_buffer;
    transfer.dst_addr = (uint32_t)DMA_ADDR_SPI0_TDR;
    transfer.nbytes = SPI_BUFFER_SIZE;
    
    qcc74x_dma_channel_lli_reload(dma0_ch0, tx_llipool, 1, &transfer, 1);
    qcc74x_dma_channel_start(dma0_ch0);
    
    // Wait for transfer complete (poll DMA busy status)
    while (qcc74x_dma_channel_isbusy(dma0_ch0)) {
        // Busy-wait
    }
    
    // WS2812 needs >50µs reset time after data
    qcc74x_mtimer_delay_us(100);
}

int main(void) {
    board_init();

    printf("\r\n");
    printf("╔════════════════════════════════════════╗\r\n");
    printf("║  \033[36mWS2812 LED Controller\033[0m             ║\r\n");
    printf("║  \033[32mQCC748M EVK\033[0m                       ║\r\n");
    printf("╚════════════════════════════════════════╝\r\n");
    printf("\r\n");

    // Initialize
    spi_init();
    dma_init();

    LOG_I("WS2812 Controller initialized\r\n");
    LOG_I("Number of LEDs: %d\r\n", NUM_LEDS);
    LOG_I("SPI buffer size: %d bytes\r\n", SPI_BUFFER_SIZE);
    printf("\r\n");
    printf("Cycling: OFF -> RED -> GREEN -> BLUE\r\n");

    while (1) {
        // Phase 1: RED shifting down each LED
        printf("Phase 1: RED shift\r\n");
        for (int i = 0; i < NUM_LEDS; i++) {
            set_all_leds(0, 0, 0);
            set_led_color(i, 255, 0, 0);
            ws2812_show();
            qcc74x_mtimer_delay_ms(200);
        }
        
        // Phase 2: GREEN shifting down each LED
        printf("Phase 2: GREEN shift\r\n");
        for (int i = 0; i < NUM_LEDS; i++) {
            set_all_leds(0, 0, 0);
            set_led_color(i, 0, 255, 0);
            ws2812_show();
            qcc74x_mtimer_delay_ms(200);
        }
        
        // Phase 3: BLUE shifting down each LED
        printf("Phase 3: BLUE shift\r\n");
        for (int i = 0; i < NUM_LEDS; i++) {
            set_all_leds(0, 0, 0);
            set_led_color(i, 0, 0, 255);
            ws2812_show();
            qcc74x_mtimer_delay_ms(200);
        }
        
        // Phase 4: WHITE shifting down each LED
        printf("Phase 4: WHITE shift\r\n");
        for (int i = 0; i < NUM_LEDS; i++) {
            set_all_leds(0, 0, 0);
            set_led_color(i, 255, 255, 255);
            ws2812_show();
            qcc74x_mtimer_delay_ms(200);
        }
        
        // Phase 5: All LEDs cycling through colors
        printf("Phase 5: All LEDs color cycle\r\n");
        
        // RED
        set_all_leds(255, 0, 0);
        ws2812_show();
        qcc74x_mtimer_delay_ms(500);
        
        // GREEN
        set_all_leds(0, 255, 0);
        ws2812_show();
        qcc74x_mtimer_delay_ms(500);
        
        // BLUE
        set_all_leds(0, 0, 255);
        ws2812_show();
        qcc74x_mtimer_delay_ms(500);
        
        // WHITE
        set_all_leds(255, 255, 255);
        ws2812_show();
        qcc74x_mtimer_delay_ms(500);
        
        // BLACK/OFF
        set_all_leds(0, 0, 0);
        ws2812_show();
        qcc74x_mtimer_delay_ms(500);
    }

    return 0;
}
