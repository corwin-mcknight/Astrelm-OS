add_executable(astrelm_system
    "kernel/arch/${ASTRELM_ARCH}/boot.S"
    ${ASTRELM_BOARD_KERNEL_SOURCES}
    kernel/debug.cpp
    kernel/main.cpp
)
set_target_properties(astrelm_system PROPERTIES OUTPUT_NAME astrelm SUFFIX .elf)
target_link_libraries(astrelm_system PRIVATE astrelm_build_options)
target_compile_options(astrelm_system PRIVATE
    -nostdinc++
    -Wpedantic -Wconversion -Wsign-conversion -Wshadow
    -Wcast-align -Wcast-qual -Wold-style-cast -Wzero-as-null-pointer-constant
    -Wswitch-enum -Wimplicit-fallthrough -Wundef -Wvla
    -Wformat=2 -Wnull-dereference -Wdouble-promotion
    -Wnon-virtual-dtor -Woverloaded-virtual
    -Wglobal-constructors -Wexit-time-destructors
    -Wreserved-identifier -Wextra-semi -Wcomma
)
target_link_options(astrelm_system PRIVATE "-T${ASTRELM_KERNEL_LINKER_SCRIPT}")
set_property(TARGET astrelm_system APPEND PROPERTY
    LINK_DEPENDS "${ASTRELM_KERNEL_LINKER_SCRIPT}")
install(TARGETS astrelm_system RUNTIME DESTINATION system/boot)
