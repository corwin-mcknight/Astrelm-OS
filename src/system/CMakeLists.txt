add_executable(astrelm_system
    "kernel/arch/${ASTRELM_ARCH}/boot.S"
    ${ASTRELM_BOARD_KERNEL_SOURCES}
    kernel/main.cpp
)
set_target_properties(astrelm_system PROPERTIES OUTPUT_NAME astrelm SUFFIX .elf)
target_link_libraries(astrelm_system PRIVATE astrelm_build_options)
target_link_options(astrelm_system PRIVATE "-T${ASTRELM_KERNEL_LINKER_SCRIPT}")
set_property(TARGET astrelm_system APPEND PROPERTY
    LINK_DEPENDS "${ASTRELM_KERNEL_LINKER_SCRIPT}")
install(TARGETS astrelm_system RUNTIME DESTINATION system/boot)
