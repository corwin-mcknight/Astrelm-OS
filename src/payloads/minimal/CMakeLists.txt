# The mission package owns its applications and their source layout.
add_executable(minimal_app apps/minimal/main.cpp)
set_target_properties(minimal_app PROPERTIES OUTPUT_NAME minimal)

# Export the executables that belong in this package's payload partition.
set(ASTRELM_PAYLOAD_TARGETS minimal_app PARENT_SCOPE)
