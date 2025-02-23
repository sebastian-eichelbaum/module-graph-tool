# Create compile_commands.json - required by several tools
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# Ensure the system headers are listed explicitly. This fixes some issues with LSPs like cland not finding the sys
# headers in unusual spots (like in NixOS)
if(CMAKE_EXPORT_COMPILE_COMMANDS)
    set(CMAKE_CXX_STANDARD_INCLUDE_DIRECTORIES ${CMAKE_CXX_IMPLICIT_INCLUDE_DIRECTORIES})
endif()

# Create a default target to contain all project options
if(NOT TARGET project_options)
    add_library(project_options INTERFACE)
endif()

# The default standard - can be overwritten with a higher standard
target_compile_features(project_options INTERFACE cxx_std_20)

# Use include as global include search path - this is where the _public_ library headers reside in.
if(EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/include)
    target_include_directories(project_options INTERFACE ${CMAKE_SOURCE_DIR}/include)
endif()

# Use colored output during compilation. This is the default for clang and gcc already on most systems. Enable on all
# others. (like EMSCRIPTEN)
if(CMAKE_CXX_COMPILER_ID MATCHES ".*Clang")
    target_compile_options(project_options INTERFACE -fcolor-diagnostics)
elseif(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
    target_compile_options(project_options INTERFACE -fdiagnostics-color=always)
endif()
