cmake_minimum_required(VERSION 3.24)

foreach(selection ARCH BOARD PAYLOAD)
    if(NOT ASTRELM_${selection} MATCHES "^[a-z0-9][a-z0-9_-]*$")
        message(FATAL_ERROR "Select ASTRELM_${selection}, or use cmake -P src/build.cmake")
    endif()
endforeach()

set(ASTRELM_TRIPLET "${ASTRELM_ARCH}-${ASTRELM_BOARD}-${ASTRELM_PAYLOAD}")
set(ASTRELM_CONFIG_DIR "${CMAKE_CURRENT_SOURCE_DIR}/src/config")
set(ASTRELM_SYSTEM_DIR "${CMAKE_CURRENT_SOURCE_DIR}/src/system")
set(ASTRELM_BOARD_DIR "${ASTRELM_CONFIG_DIR}/boards/${ASTRELM_BOARD}")
set(ASTRELM_PAYLOAD_DIR "${CMAKE_CURRENT_SOURCE_DIR}/src/payloads/${ASTRELM_PAYLOAD}")
set(CMAKE_TOOLCHAIN_FILE "${ASTRELM_CONFIG_DIR}/arch/${ASTRELM_ARCH}/toolchain.cmake")

if(CMAKE_SOURCE_DIR STREQUAL CMAKE_BINARY_DIR)
    message(FATAL_ERROR "Use an out-of-source build under build/${ASTRELM_TRIPLET}")
endif()
if(NOT EXISTS "${CMAKE_TOOLCHAIN_FILE}" OR
   NOT EXISTS "${ASTRELM_BOARD_DIR}/board.cmake" OR
   NOT EXISTS "${ASTRELM_PAYLOAD_DIR}/CMakeLists.txt")
    message(FATAL_ERROR "Unsupported architecture, board, or payload: ${ASTRELM_TRIPLET}")
endif()
include("${ASTRELM_BOARD_DIR}/board.cmake")
if(NOT ASTRELM_ARCH IN_LIST ASTRELM_BOARD_ARCHES)
    message(FATAL_ERROR "Board ${ASTRELM_BOARD} does not support ${ASTRELM_ARCH}")
endif()
if(DEFINED ASTRELM_CONFIGURED_TRIPLET AND
   NOT ASTRELM_CONFIGURED_TRIPLET STREQUAL ASTRELM_TRIPLET)
    message(FATAL_ERROR "Use a separate build directory for ${ASTRELM_TRIPLET}")
endif()
set(ASTRELM_CONFIGURED_TRIPLET "${ASTRELM_TRIPLET}" CACHE INTERNAL "Selected target")

project(Astrelm LANGUAGES C CXX ASM)
set(CMAKE_C_STANDARD 17)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_C_EXTENSIONS OFF)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

add_library(astrelm_build_options INTERFACE)
target_compile_options(astrelm_build_options INTERFACE
    -ffreestanding -fno-stack-protector -fno-pic
    -Wall -Wextra -Werror
    $<$<COMPILE_LANGUAGE:CXX>:-fno-exceptions;-fno-rtti;-fno-threadsafe-statics>
)
target_link_options(astrelm_build_options INTERFACE
    -nostdlib -static "--ld-path=${ASTRELM_LINKER}"
)

add_subdirectory(src/system)
add_subdirectory(src/payloads)

set(ASTRELM_SYSROOT "${CMAKE_BINARY_DIR}/sysroot")
set(ASTRELM_IMAGES "${CMAKE_BINARY_DIR}/images")

# Recreate staging when inputs change so removed installed files cannot linger.
add_custom_command(
    OUTPUT "${ASTRELM_SYSROOT}/.stamp"
    COMMAND "${CMAKE_COMMAND}" -E rm -rf "${ASTRELM_SYSROOT}"
    COMMAND "${CMAKE_COMMAND}" --install "${CMAKE_BINARY_DIR}"
        --prefix "${ASTRELM_SYSROOT}"
    COMMAND "${CMAKE_COMMAND}" -E make_directory "${ASTRELM_SYSROOT}/data"
    COMMAND "${CMAKE_COMMAND}" -E touch "${ASTRELM_SYSROOT}/.stamp"
    DEPENDS astrelm_system ${ASTRELM_PAYLOAD_TARGETS}
        "${CMAKE_BINARY_DIR}/cmake_install.cmake"
        "${CMAKE_BINARY_DIR}/src/system/cmake_install.cmake"
        ${ASTRELM_PAYLOAD_INSTALL_SCRIPTS}
    COMMENT "Staging system, payload, and data sysroots"
    VERBATIM
)
add_custom_target(sysroot DEPENDS "${ASTRELM_SYSROOT}/.stamp")
include("${ASTRELM_BOARD_DIR}/image.cmake")
message(STATUS "Astrelm target: ${ASTRELM_TRIPLET}")
