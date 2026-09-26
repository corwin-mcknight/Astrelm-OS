# Run with: cmake -P src/build.cmake
# Override the checkout selection with -DASTRELM_ARCH, -DASTRELM_BOARD,
# -DASTRELM_PAYLOAD, and -DASTRELM_PROFILE=size|debug.
cmake_minimum_required(VERSION 3.24)
get_filename_component(root "${CMAKE_CURRENT_LIST_DIR}/.." ABSOLUTE)
set(selection_file "${root}/build/target.json")

set(default_ARCH riscv64)
set(default_BOARD virt)
set(default_PAYLOAD minimal)
if(EXISTS "${selection_file}")
    file(READ "${selection_file}" saved_selection)
endif()
foreach(field ARCH BOARD PAYLOAD)
    if(NOT DEFINED ASTRELM_${field})
        if(DEFINED saved_selection)
            string(TOLOWER "${field}" key)
            string(JSON ASTRELM_${field} GET "${saved_selection}" "${key}")
        else()
            set(ASTRELM_${field} "${default_${field}}")
        endif()
    endif()
    if(NOT ASTRELM_${field} MATCHES "^[a-z0-9][a-z0-9_-]*$")
        message(FATAL_ERROR "Invalid ASTRELM_${field}: ${ASTRELM_${field}}")
    endif()
endforeach()
if(NOT DEFINED ASTRELM_PROFILE)
    set(ASTRELM_PROFILE size)
    if(DEFINED saved_selection)
        string(JSON saved_profile ERROR_VARIABLE profile_error GET
            "${saved_selection}" profile)
        if(NOT profile_error)
            set(ASTRELM_PROFILE "${saved_profile}")
        endif()
    endif()
endif()
if(NOT ASTRELM_PROFILE MATCHES "^(size|debug)$")
    message(FATAL_ERROR "ASTRELM_PROFILE must be size or debug")
endif()

set(toolchain_file "${root}/src/config/arch/${ASTRELM_ARCH}/toolchain.cmake")
set(definitions
    "${toolchain_file}"
    "${root}/src/config/boards/${ASTRELM_BOARD}/board.cmake"
    "${root}/src/payloads/${ASTRELM_PAYLOAD}/CMakeLists.txt"
)
foreach(definition IN LISTS definitions)
    if(NOT EXISTS "${definition}")
        message(FATAL_ERROR "Unsupported target: missing ${definition}")
    endif()
endforeach()

set(triplet "${ASTRELM_ARCH}-${ASTRELM_BOARD}-${ASTRELM_PAYLOAD}")
set(output "${root}/build/${triplet}")
if(ASTRELM_PROFILE STREQUAL "debug")
    set(build_type AstrelmDebug)
else()
    set(build_type AstrelmSize)
endif()
set(configure_options)
set(needs_configure FALSE)
if(NOT EXISTS "${output}/build.ninja")
    set(needs_configure TRUE)
endif()
if(EXISTS "${output}/CMakeCache.txt")
    file(STRINGS "${output}/CMakeCache.txt" cached_build_type_line
        REGEX "^CMAKE_BUILD_TYPE:[^=]*=")
    string(REGEX REPLACE "^[^=]*=" "" cached_build_type "${cached_build_type_line}")
    if(NOT cached_build_type STREQUAL build_type)
        set(needs_configure TRUE)
    endif()
    file(STRINGS "${output}/CMakeCache.txt" cached_toolchain_line
        REGEX "^CMAKE_TOOLCHAIN_FILE:[^=]*=")
    string(REGEX REPLACE "^[^=]*=" "" cached_toolchain "${cached_toolchain_line}")
    if(cached_toolchain_line AND NOT cached_toolchain STREQUAL toolchain_file)
        set(needs_configure TRUE)
        list(APPEND configure_options --fresh)
        foreach(tool CMAKE_C_COMPILER CMAKE_CXX_COMPILER ASTRELM_LINKER ASTRELM_MKE2FS)
            file(STRINGS "${output}/CMakeCache.txt" cached_tool_line
                REGEX "^${tool}:[^=]*=")
            string(REGEX REPLACE "^[^=]*=" "" cached_tool "${cached_tool_line}")
            if(EXISTS "${cached_tool}")
                list(APPEND configure_options "-D${tool}:FILEPATH=${cached_tool}")
            endif()
        endforeach()
    endif()
endif()
if(needs_configure)
    execute_process(
        COMMAND "${CMAKE_COMMAND}" ${configure_options} -S "${root}" -B "${output}" -G Ninja
            "-DCMAKE_BUILD_TYPE=${build_type}"
            "-DASTRELM_ARCH=${ASTRELM_ARCH}"
            "-DASTRELM_BOARD=${ASTRELM_BOARD}"
            "-DASTRELM_PAYLOAD=${ASTRELM_PAYLOAD}"
        COMMAND_ERROR_IS_FATAL ANY
    )
endif()
execute_process(
    COMMAND "${CMAKE_COMMAND}" --build "${output}"
    COMMAND_ERROR_IS_FATAL ANY
)
file(WRITE "${selection_file}.tmp"
    "{\n  \"arch\": \"${ASTRELM_ARCH}\",\n"
    "  \"board\": \"${ASTRELM_BOARD}\",\n"
    "  \"payload\": \"${ASTRELM_PAYLOAD}\",\n"
    "  \"profile\": \"${ASTRELM_PROFILE}\"\n}\n")
file(RENAME "${selection_file}.tmp" "${selection_file}")
message(STATUS "Images: ${output}/images")
