#include <stdint.h>

namespace {
constexpr uintptr_t uart_base = 0x10000000;
constexpr uint8_t transmit_ready = 0x20;
}

extern "C" void astrelm_console_putc(char c)
{
    volatile uint8_t *const uart = reinterpret_cast<volatile uint8_t *>(uart_base);
    while ((uart[5] & transmit_ready) == 0) {
    }
    uart[0] = static_cast<uint8_t>(c);
}
