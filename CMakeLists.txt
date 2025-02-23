cmake_minimum_required(VERSION 3.1)

project(
    mgt
    VERSION 1.0.0
    DESCRIPTION "Module Graph Tools"
    HOMEPAGE_URL "https://github.com/sebastian-eichelbaum/mgt"
)

# Use some sane default boilerplate. This creates some interface targets you should add as a target link lib:
# "project_warnings", "project_options" and "project_sanitizers".
include(tools/cmake/Boilerplate.cmake)

# C++ Standard Level - the pre-defined level in the boilerplate code is C++20. Change if needed.
target_compile_features(project_options INTERFACE cxx_std_23)

# Setup the target add_target(${BinName} EXE LINK_LIBS "nx")
add_target("mgt" EXE)
