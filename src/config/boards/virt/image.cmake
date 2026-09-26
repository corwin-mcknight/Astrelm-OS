# This board currently emits three standalone partitions, with no disk/boot wrapper.
find_program(ASTRELM_MKE2FS NAMES "$ENV{MKE2FS}" mke2fs
    HINTS /opt/homebrew/opt/e2fsprogs/sbin /usr/local/opt/e2fsprogs/sbin REQUIRED)

set(partition_images)
foreach(partition system payload data)
    set(image "${ASTRELM_IMAGES}/${partition}.img")
    add_custom_command(
        OUTPUT "${image}"
        COMMAND "${CMAKE_COMMAND}" -E make_directory "${ASTRELM_IMAGES}"
        COMMAND "${CMAKE_COMMAND}" -E rm -f "${image}.tmp"
        COMMAND "${ASTRELM_MKE2FS}" -q -F -t ext2 -b 4096 -m 0
            -O none,filetype,sparse_super,large_file -E root_owner=0:0
            -L "${partition}" -d "${ASTRELM_SYSROOT}/${partition}" "${image}.tmp" 8M
        COMMAND "${CMAKE_COMMAND}" -E rename "${image}.tmp" "${image}"
        DEPENDS "${ASTRELM_SYSROOT}/.stamp" "${CMAKE_CURRENT_LIST_FILE}"
        COMMENT "Creating ${partition}.img (ext2, 8 MiB)"
        VERBATIM
    )
    list(APPEND partition_images "${image}")
endforeach()
add_custom_target(images ALL DEPENDS ${partition_images})
