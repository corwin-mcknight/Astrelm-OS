#include "debug.h"

extern "C" void astrelm_main(uintptr_t hart_id)
{
    (void)debug::line("Astrelm kernel booting; hart=", hart_id);
}
