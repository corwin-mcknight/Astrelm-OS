#include "debug.h"

extern "C" bool astrelm_debug_putc(char value);

namespace debug {

bool write(const char *bytes, size_t length)
{
    if (bytes == nullptr && length != 0) {
        return false;
    }
    for (size_t index = 0; index < length; ++index) {
        if (!astrelm_debug_putc(bytes[index])) {
            return false;
        }
    }
    return true;
}

namespace detail {

bool print_unsigned(uint64_t value)
{
    constexpr char alphabet[] = "0123456789";
    char buffer[20];
    size_t count = 0;
    do {
        const size_t digit = static_cast<size_t>(value % uint64_t{10});
        buffer[count] = alphabet[digit];
        ++count;
        value /= uint64_t{10};
    } while (value != 0);

    while (count != 0) {
        --count;
        if (!astrelm_debug_putc(buffer[count])) {
            return false;
        }
    }
    return true;
}

bool print_signed(int64_t value)
{
    if (value >= 0) {
        return print_unsigned(static_cast<uint64_t>(value));
    }
    if (!astrelm_debug_putc('-')) {
        return false;
    }
    const uint64_t magnitude = static_cast<uint64_t>(-(value + 1)) + 1;
    return print_unsigned(magnitude);
}

bool print_one(char value)
{
    return astrelm_debug_putc(value);
}

bool print_one(bool value)
{
    if (value) {
        return write("true");
    }
    return write("false");
}

bool print_one(Text value)
{
    return write(value.bytes, value.length);
}

bool print_one(Hex value)
{
    constexpr char digits[] = "0123456789abcdef";
    if (!write("0x")) {
        return false;
    }
    bool started = false;
    for (uint32_t index = 16U; index > 0U; --index) {
        const uint32_t shift = (index - 1U) * 4U;
        const uint64_t nibble = (value.value >> shift) & uint64_t{0xFU};
        const size_t digit = static_cast<size_t>(nibble);
        if (digit != 0U || started || index == 1U) {
            started = true;
            if (!astrelm_debug_putc(digits[digit])) {
                return false;
            }
        }
    }
    return true;
}

} // namespace detail
} // namespace debug
