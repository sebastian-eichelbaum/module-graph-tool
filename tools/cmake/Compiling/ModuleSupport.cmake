# This manages C++ 20 Module support

# TODO: there are some compiler version specific hacks here. Re-validate and clean up!

option(ENABLE_MODULE_SUPPORT "Enable C++20 module support" TRUE)
if(ENABLE_MODULE_SUPPORT)

    # ##################################################################################################################
    # Version checks

    if(CMAKE_VERSION VERSION_LESS "3.28.0")
        message(
            FATAL_ERROR
                "Please consider to switch to CMake 3.28.0 - All versions below do not support C++20 modules! You are using ${CMAKE_VERSION}"
        )
    endif()

    # ##################################################################################################################
    # Compiler specific setups

    # Clang
    if(CMAKE_CXX_COMPILER_ID MATCHES ".*Clang")
        if(CLANG_VERSION_STRING VERSION_LESS "17.0.0")
            # Turning off extensions avoids an issue with the clang 16 compiler clang 17 and greater can avoid this
            # setting
            set(CMAKE_CXX_EXTENSIONS OFF)
        endif()
    endif()
endif()
