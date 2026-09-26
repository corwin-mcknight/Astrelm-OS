set(CMAKE_SYSTEM_NAME Generic)
set(CMAKE_SYSTEM_PROCESSOR riscv64)
set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY)

find_program(CMAKE_C_COMPILER NAMES "$ENV{CC}" clang
    HINTS /opt/homebrew/opt/llvm/bin /usr/local/opt/llvm/bin REQUIRED)
find_program(CMAKE_CXX_COMPILER NAMES "$ENV{CXX}" clang++
    HINTS /opt/homebrew/opt/llvm/bin /usr/local/opt/llvm/bin REQUIRED)
find_program(ASTRELM_LINKER NAMES "$ENV{LD_LLD}" ld.lld
    HINTS /opt/homebrew/opt/lld/bin /usr/local/opt/lld/bin REQUIRED)

set(CMAKE_C_COMPILER_TARGET riscv64-unknown-elf)
set(CMAKE_CXX_COMPILER_TARGET riscv64-unknown-elf)
set(CMAKE_ASM_COMPILER_TARGET riscv64-unknown-elf)
set(CMAKE_C_FLAGS_INIT "-march=rv64imac -mabi=lp64 -mcmodel=medany")
set(CMAKE_CXX_FLAGS_INIT "-march=rv64imac -mabi=lp64 -mcmodel=medany")
set(CMAKE_ASM_FLAGS_INIT "-march=rv64imac -mabi=lp64 -mcmodel=medany")

set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)
list(APPEND CMAKE_TRY_COMPILE_PLATFORM_VARIABLES ASTRELM_LINKER)
