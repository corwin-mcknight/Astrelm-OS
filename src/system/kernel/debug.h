#ifndef ASTRELM_KERNEL_DEBUG_H
#define ASTRELM_KERNEL_DEBUG_H

#include <stddef.h>
#include <stdint.h>

namespace debug {

// A failed sink drops the rest of the call. The board sink bounds each byte's wait.
bool write(const char *bytes, size_t length);

template <size_t N>
bool write(const char (&text)[N])
{
    size_t length = 0;
    while (length < N && text[length] != '\0') {
        ++length;
    }
    return write(text, length);
}

struct Text {
    const char *bytes;
    size_t length;
};

inline Text text(const char *bytes, size_t length)
{
    return {bytes, length};
}

struct Hex {
    uint64_t value;
};

inline Hex hex(uint64_t value)
{
    return {value};
}

namespace detail {

bool print_unsigned(uint64_t value);
bool print_signed(int64_t value);
bool print_one(char value);
bool print_one(bool value);
bool print_one(Text value);
bool print_one(Hex value);

template <size_t N>
bool print_one(const char (&value)[N])
{
    return write(value);
}

inline bool print_one(signed char value) { return print_signed(value); }
inline bool print_one(unsigned char value) { return print_unsigned(value); }
inline bool print_one(short value) { return print_signed(value); }
inline bool print_one(unsigned short value) { return print_unsigned(value); }
inline bool print_one(int value) { return print_signed(value); }
inline bool print_one(unsigned int value) { return print_unsigned(value); }
inline bool print_one(long value) { return print_signed(value); }
inline bool print_one(unsigned long value) { return print_unsigned(value); }
inline bool print_one(long long value) { return print_signed(value); }
inline bool print_one(unsigned long long value) { return print_unsigned(value); }

class Printer {
public:
    Printer() : successful_(true) {}

    template <typename Value>
    Printer &operator<<(const Value &value)
    {
        if (successful_) {
            successful_ = print_one(value);
        }
        return *this;
    }

    bool successful() const { return successful_; }

private:
    bool successful_;
};

} // namespace detail

template <typename... Values>
bool print(const Values &...values)
{
    if constexpr (sizeof...(Values) == 0U) {
        return true;
    } else {
        detail::Printer printer;
        (printer << ... << values);
        return printer.successful();
    }
}

template <typename... Values>
bool line(const Values &...values)
{
    if (!print(values...)) {
        return false;
    }
    return detail::print_one('\n');
}

} // namespace debug

#endif
