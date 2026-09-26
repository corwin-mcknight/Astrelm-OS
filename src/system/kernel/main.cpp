extern "C" void astrelm_console_putc(char c);

extern "C" void astrelm_main(void)
{
    for (const char *c = "Hello, world!\r\n"; *c != '\0'; ++c) {
        astrelm_console_putc(*c);
    }
}
