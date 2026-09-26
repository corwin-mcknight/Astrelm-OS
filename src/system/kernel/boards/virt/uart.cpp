#include <stdint.h>

namespace {
constexpr uintptr_t uart_base = 0x10000000;
constexpr uint8_t transmit_ready = 0x20;
constexpr unsigned int transmit_poll_limit = 100000;

bool write_byte(volatile uint8_t *uart, uint8_t value)
{
    for (unsigned int attempt = 0; attempt < transmit_poll_limit; ++attempt) {
        const uint32_t status = static_cast<uint32_t>(uart[5]);
        const uint32_t ready = static_cast<uint32_t>(transmit_ready);
        if ((status & ready) != 0U) {
            uart[0] = value;
            return true;
        }
    }
    return false;
}
}

extern "C" bool astrelm_debug_putc(char value)
{
    // Board exception: virt UART0 has a fixed MMIO address. Keep this conversion here.
    // NOLINTNEXTLINE(cppcoreguidelines-pro-type-reinterpret-cast)
    volatile uint8_t *const uart = reinterpret_cast<volatile uint8_t *>(uart_base);
    if (value == '\n') {
        if (!write_byte(uart, '\r')) {
            return false;
        }
    }
    return write_byte(uart, static_cast<uint8_t>(value));
}
