cmake_minimum_required(VERSION 3.2...3.31)

project(
    mgt
    VERSION 1.0.0
    DESCRIPTION "Module Graph Tools"
    HOMEPAGE_URL "https://github.com/seichelbaum/mgt"
)
set(PROJECT_AUTHORS "Sophia Eichelbaum")

# Use some sane default boilerplate. This creates some interface targets you should add as a target link lib:
# "project_warnings", "project_options" and "project_sanitizers".
include(tools/cmake/Boilerplate.cmake)
include(FetchContent)

# C++ Standard Level - the pre-defined level in the boilerplate code is C++20. Change if needed.
target_compile_features(project_options INTERFACE cxx_std_23)

# https://github.com/bobluppes/graaf, MIT License
add_target(
    "graaf" HEADER_ONLY_LIB
    # The base dir where to find the lib and its codes
    BASE "${CMAKE_CURRENT_SOURCE_DIR}/external/graaf/"
)

# https://github.com/nlohmann/json, MIT License
add_target(
    "nlohmann_json"
    HEADER_ONLY_LIB
    # The base dir where to find the lib and its codes
    BASE
    "${CMAKE_CURRENT_SOURCE_DIR}/external/nlohmann_json/"
    INCLUDE_DIRS
    "single_include"
    INCLUDES
    "single_include/*.hpp"
)

add_target("mgt" EXE LINK_LIBS "nlohmann_json" "graaf")
