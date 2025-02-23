# Setup the given target for emscripten. Also provides the loader html/js.
function(setup_emscripten BinName)
    message(STATUS "Configuring ${BinName} for Emscripten")

    # Enable exceptions
    target_compile_options(
        ${BinName}
        PUBLIC # Enable Exception support per-se
               "-fexceptions"
               # This enables WebAssemply Exception Handling support
               "-fwasm-exceptions"
               # More:
    )

    # technically, this is not needed as the emscripten clang sets it, but helpful for code completion tools
    target_compile_definitions(${BinName} PUBLIC EMSCRIPTEN)

    # Not yet supported: target_compile_options(${BinName} PUBLIC "-fwasm-exceptions")

    # Some Emscripten-specific settings
    target_link_options(
        ${BinName}
        PUBLIC
        # Enable EMBIND support and CCALL support
        "--bind"
        "-sEXPORTED_RUNTIME_METHODS=ccall"
        #
        # Async support - increases code size drastically.
        #
        # "-sASYNCIFY"
        #
        # Generate a modern JS module and provide a custom factory name
        "-sMODULARIZE=1"
        "-sEXPORT_ES6=1"
        "-sEXPORT_NAME=factory" # NOTE: only needed when not using the default export
        #
        # WebGL: Allow v1 and v2
        "-sMIN_WEBGL_VERSION=1"
        "-sMAX_WEBGL_VERSION=2"
        #
        # Exception support - adds some overhead
        "-fexceptions"
        # WebAssemply Exception Handling enabled
        "-fwasm-exceptions"
        #
        # Link time optimization - can cause linker issues (mismatching symbols)
        #
        # "-flto"
    )

    # HACK: make it work with Emscripten >= 3.14. They moved some included headers into the sysroot but it is not
    # included as sys include dir automatically. target_include_directories(${BinName} SYSTEM PUBLIC
    # "${EMSCRIPTEN_SYSROOT}/include/emscripten") Help the code tools to find everything?
    # target_include_directories(project_options SYSTEM INTERFACE ${EMSCRIPTEN_ROOT_PATH}/system/include)

    # Debug options
    string(TOLOWER "${CMAKE_BUILD_TYPE}" cmake_build_type_tolower)
    if(cmake_build_type_tolower STREQUAL "debug")
        target_link_options(${BinName} PRIVATE "-gsource-map" "--emit-symbol-map" "--source-map-base=./")
    endif()

    # Convenience Tools: DISABLED for now. This is not part of the boilerplate. copy_to(${BinName} "scripts/serve.py"
    # "${CMAKE_BINARY_DIR}")
endfunction()

# Setup the given target for Unix. This excluded Apple.
function(setup_linuxbsd BinName)
    message(STATUS "Configuring ${BinName} for Linux/BSD")
endfunction()

# Setup the given target for Apple.
function(setup_apple BinName)
    message(STATUS "Configuring ${BinName} for Apple")
endfunction()

# Generic platform setup. Sets the sensible defaults for each platform. This prepares the build system for the specific
# platform. It does NOT setup any platform specific needs of any of your dependencies.
function(platform_setup BinName)
    if(EMSCRIPTEN)
        setup_emscripten(${BinName})
    elseif(UNIX AND NOT APPLE)
        setup_linuxbsd(${BinName})
    elseif(APPLE)
        setup_apple(${BinName})
    endif()
endfunction()
