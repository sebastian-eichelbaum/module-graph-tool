# Ensure there is a defined build type set
if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
    message(STATUS "Setting build type to 'Release' as none was specified.")
    set(CMAKE_BUILD_TYPE
        Release
        CACHE STRING "Choose the type of build." FORCE)
    # Set the possible values of build type for cmake-gui, ccmake
    set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS "Debug" "Release" "MinSizeRel" "RelWithDebInfo")
endif()

# Make sure the build type is known and defined.
string(TOLOWER "${CMAKE_BUILD_TYPE}" cmake_build_type_tolower)
if(NOT cmake_build_type_tolower STREQUAL "debug"
   AND NOT cmake_build_type_tolower STREQUAL "release"
   AND NOT cmake_build_type_tolower STREQUAL "minsizerel"
   AND NOT cmake_build_type_tolower STREQUAL "relwithdebinfo"
   AND NOT cmake_build_type_tolower STREQUAL "")
    message(SEND_ERROR "Unknown build type \"${CMAKE_BUILD_TYPE}\".")
endif()

message(STATUS "Buildtype: ${CMAKE_BUILD_TYPE}")
