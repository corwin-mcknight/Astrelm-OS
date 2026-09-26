add_subdirectory("${ASTRELM_PAYLOAD}")
if(NOT DEFINED ASTRELM_PAYLOAD_TARGETS)
    message(FATAL_ERROR "Payload ${ASTRELM_PAYLOAD} must declare ASTRELM_PAYLOAD_TARGETS")
endif()

# Apply common build and staging rules to the executables owned by the selected mission.
foreach(target IN LISTS ASTRELM_PAYLOAD_TARGETS)
    if(NOT TARGET "${target}")
        message(FATAL_ERROR "Payload ${ASTRELM_PAYLOAD} declares a missing target: ${target}")
    endif()
    get_target_property(target_type "${target}" TYPE)
    if(NOT target_type STREQUAL "EXECUTABLE")
        message(FATAL_ERROR "Payload target ${target} must be an executable")
    endif()
    set_target_properties("${target}" PROPERTIES SUFFIX .elf)
    target_link_libraries("${target}" PRIVATE astrelm_build_options)
    target_link_options("${target}" PRIVATE LINKER:-e,application_entry)
    install(TARGETS "${target}" RUNTIME DESTINATION payload/bin)
endforeach()

add_custom_target(astrelm_payload DEPENDS ${ASTRELM_PAYLOAD_TARGETS})
set(ASTRELM_PAYLOAD_TARGETS "${ASTRELM_PAYLOAD_TARGETS}" PARENT_SCOPE)
set(ASTRELM_PAYLOAD_INSTALL_SCRIPTS
    "${CMAKE_CURRENT_BINARY_DIR}/cmake_install.cmake"
    "${CMAKE_CURRENT_BINARY_DIR}/${ASTRELM_PAYLOAD}/cmake_install.cmake"
    PARENT_SCOPE
)
