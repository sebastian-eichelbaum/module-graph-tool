# Setup a target using the global project properties and settings. This puts the builds into the default output
# directories as specified by CMake in  RUNTIME_OUTPUT_DIRECTORY, ...
function(setup_target TargetName)
    # Local include path
    target_include_directories(${TargetName} PRIVATE ${CMAKE_CURRENT_SOURCE_DIR})

    # The logger can utilize this to auto-generate log tags
    target_compile_definitions(${TargetName} PUBLIC SRC_BASE_PATH="${CMAKE_SOURCE_DIR}")

    # Linking the options and compiler flags to the target
    target_link_libraries(${TargetName} PRIVATE project_options project_warnings project_sanitizers)

    # depend on version generation
    target_link_libraries(${TargetName} PUBLIC project_version)

    # Setup some building tools:
    setup_unity_build(${TargetName})
    setup_lto(${TargetName})
endfunction()

# Collect different source by glob automatically.  Use:
#
# ~~~
# collect_files(
#        NOGLOB # Set this IFF your globs are not globs but real paths instead
#
#        BASE     # - search globs in here
#        ${SOME_DIR}
#
#        RESULT   # - Result will be stored here
#        ResultVarName
#
#        GLOBS    # - a set of glob expressions to use
#        ${GIVEN_GLOBS}
#
#        DEFAULTS # - the defaults of GIVEN_GLOBS is empty
#        "include/*.hpp;include/*.h++;include/*.hxx"
#        "orAnExactMatch.hpp"
#    )
# ~~~
function(collect_files)
    set(options NOGLOB)
    set(oneValueArgs BASE RESULT)
    set(multiValueArgs GLOBS DEFAULTS)
    cmake_parse_arguments(ARGS "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    # Ensure the base dir was given
    if((NOT DEFINED ARGS_BASE) OR (NOT EXISTS ${ARGS_BASE}))
        message(FATAL_ERROR "BASE dir must be specified for collecting files.")
    endif()

    # use given globs or defaults
    list(LENGTH ARGS_GLOBS NUM_GLOBS)
    set(_GLOBS ${ARGS_GLOBS})
    if(${NUM_GLOBS} EQUAL 0)
        set(_GLOBS ${ARGS_DEFAULTS})
    endif()

    set(COLLECTED_FILES)
    foreach(glob ${_GLOBS})
        # message("Glob: ${glob}")
        cmake_path(APPEND ARGS_BASE ${glob} OUTPUT_VARIABLE fullglob)

        if(ARGS_NOGLOB)
            list(APPEND COLLECTED_FILES ${fullglob})
        else()
            file(GLOB_RECURSE foundfiles ${fullglob})
            list(APPEND COLLECTED_FILES ${foundfiles})
        endif()
    endforeach()

    set(${ARGS_RESULT}
        ${COLLECTED_FILES}
        PARENT_SCOPE
    )
endfunction()

# Automagically add a target and collect its sources and set everything up. The defaults assume pitchfork project style.
#
# Usage:
# ~~~
#
# add_target(
#    # Target name
#    "nx"
#    # The target type. One of HEADER_ONLY_LIB, STATIC_LIB, SHARED_LIB, EXE
#    HEADER_ONLY_LIB
#    # The base dir where to find the lib and its codes. If not given, ${CMAKE_CURRENT_SOURCE_DIR} is used.
#    BASE
#    "${CMAKE_CURRENT_SOURCE_DIR}/external/nx"
#    # a list of include directories relative to BASE.
#    INCLUDE_DIRS
#    "include"
#    # a glob expression relative to BASE describing the headers of this lib
#    INCLUDES
#    "include/*.hpp"
#    "include/*.h++"
#    "include/*.hxx"
#    # a glob expression relative to BASE describing the sources to build
#    SOURCES
#    "src/*.cpp"
#    "src/*.c++"
#    "src/*.cxx"
#    # a glob expression relative to BASE describing the modules to build
#    MODULES
#    "src/*.cppm"
#    "src/*.c++m"
#    "src/*.cxxm"
#    "src/*.ixx"
#    # an explicit list of headers to pre-compile. Relative to BASE.
#    PRECOMPILE
#    "include/nx.hpp"
#    # A list of deps to link to this target
#    LINK_LIBS
#    fmt::fmt
# )
# ~~~
function(add_target TargetName)
    set(options HEADER_ONLY_LIB SHARED_LIB STATIC_LIB EXE)
    set(oneValueArgs BASE)
    set(multiValueArgs INCLUDE_DIRS INCLUDES SOURCES MODULES PRECOMPILE LINK_LIBS)
    cmake_parse_arguments(ARGS "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    if(NOT DEFINED ARGS_BASE)
        set(ARGS_BASE ${CMAKE_CURRENT_SOURCE_DIR})
    endif()

    # Ensure the base dir was given
    if((NOT DEFINED ARGS_BASE) OR (NOT EXISTS ${ARGS_BASE}))
        message(FATAL_ERROR "BASE dir must be specified and must exist for target \"${TargetName}\".")
    endif()

    # ##################################################################################################################
    # Collect sources:
    #

    # Cpp sources
    collect_files(
        BASE
        ${ARGS_BASE}
        RESULT
        TARGET_CPP_FILES
        GLOBS
        ${ARGS_SOURCES}
        DEFAULTS
        "src/*.cpp;src/*.c++;src/*.cxx"
    )

    # Cpp modules sources
    collect_files(
        BASE
        ${ARGS_BASE}
        RESULT
        TARGET_CPPM_FILES
        GLOBS
        ${ARGS_MODULES}
        DEFAULTS
        "src/*.cppm;src/*.c++m;src/*.cxxm;src/*.ixx"
    )

    # Headers modules sources
    collect_files(
        BASE
        ${ARGS_BASE}
        RESULT
        TARGET_HPP_FILES
        GLOBS
        ${ARGS_INCLUDES}
        DEFAULTS
        "include/*.hpp;include/*.h++;include/*.hxx;include/*.h"
    )

    # Headers modules sources
    collect_files(
        BASE ${ARGS_BASE} RESULT TARGET_PCH_FILES GLOBS ${ARGS_PRECOMPILE}
        # No default precompile headers by default
    )

    # Collect include dirs
    collect_files(
        NOGLOB
        BASE
        ${ARGS_BASE}
        RESULT
        TARGET_INCLUDE_DIRS
        GLOBS
        ${ARGS_INCLUDE_DIRS}
        DEFAULTS
        "include"
    )

    list(LENGTH TARGET_CPP_FILES NUM_CPP)
    list(LENGTH TARGET_CPPM_FILES NUM_CPPM)
    list(LENGTH TARGET_HPP_FILES NUM_HEADER)
    list(LENGTH TARGET_INCLUDE_DIRS NUM_INCLUDEDIRS)

    # ##################################################################################################################
    # Validate:
    #

    # If not header only, ensure there are sources.
    #
    # NOTE: modules are NOT sources that build a lib/exe. They are more like pre-compiled headers.
    if((NOT ARGS_HEADER_ONLY_LIB) AND (${NUM_CPP} EQUAL 0))
        message(
            FATAL_ERROR
                "No sources found for target \"${TargetName}\" in \"${ARGS_BASE}\". Set the HEADER_ONLY_LIB option if this is a lib without sources."
        )
    endif()

    # If header only, ensure there are headers or modules sources
    if(ARGS_HEADER_ONLY_LIB
       AND (${NUM_HEADER} EQUAL 0)
       AND (${NUM_CPPM} EQUAL 0)
    )
        message(
            FATAL_ERROR
                "No headers or module sources found for HEADER_ONLY_LIB target \"${TargetName}\" in \"${ARGS_BASE}\"."
        )
    endif()

    # Ensure there are include directories specified
    if(${NUM_INCLUDEDIRS} EQUAL 0)
        message(FATAL_ERROR "No include dir is specified for target \"${TargetName}\".")
    endif()

    # ##################################################################################################################
    # Target creation:
    #

    if(ARGS_HEADER_ONLY_LIB)
        add_library(${TargetName} INTERFACE)
    elseif(ARGS_SHARED_LIB)
        add_library(${TargetName} SHARED ${TARGET_CPP_FILES})
    elseif(ARGS_STATIC_LIB)
        add_library(${TargetName} STATIC ${TARGET_CPP_FILES})
    else()
        add_executable(${TargetName} ${TARGET_CPP_FILES})
    endif()

    # ##################################################################################################################
    # Target configuration:
    #

    # Setup the targets. Header only is a bit different though
    if(ARGS_HEADER_ONLY_LIB)
        # The logger can utilize this to auto-generate log tags
        target_compile_definitions(${TargetName} INTERFACE SRC_BASE_PATH="${CMAKE_SOURCE_DIR}")

        # Linking the options and compiler flags to the target
        target_link_libraries(${TargetName} INTERFACE project_options project_warnings project_sanitizers)

        # depend on version generation
        target_link_libraries(${TargetName} INTERFACE project_version)

        # Link anything else the user specified
        target_link_libraries(${TargetName} INTERFACE ${ARGS_LINK_LIBS})
    else()
        # The logger can utilize this to auto-generate log tags
        target_compile_definitions(${TargetName} PRIVATE SRC_BASE_PATH="${CMAKE_SOURCE_DIR}")

        # Linking the options and compiler flags to the target
        target_link_libraries(${TargetName} PRIVATE project_options project_warnings project_sanitizers)

        # Setup some building tools:
        setup_unity_build(${TargetName})
        setup_lto(${TargetName})

        # depend on version generation
        target_link_libraries(${TargetName} PRIVATE project_version)

        # Link anything else the user specified
        target_link_libraries(${TargetName} PUBLIC ${ARGS_LINK_LIBS})

        # Platform specific setup
        platform_setup(${TargetName})
    endif()

    # Module sources, if present
    if(NOT ${NUM_CPPM} EQUAL 0)
        target_sources(${TargetName} PUBLIC FILE_SET CXX_MODULES FILES ${TARGET_CPPM_FILES})
    endif()
    # Headers
    target_sources(${TargetName} PUBLIC FILE_SET HEADERS BASE_DIRS ${TARGET_INCLUDE_DIRS} FILES ${TARGET_HPP_FILES})

endfunction()

# A wrapper to add_subdirectory that is coupled to an OPTION and dependencies.
#
# Dir: the directory containing the CMake file
#
# ComponentName: the name of the component. Used to construct the option and build directory name.
#
# DefaultValue: ON or OFF
function(add_subdirectory_optional Dir ComponentName DefaultValue)
    option(BUILD_${ComponentName} "Build ${ComponentName}?" ${DefaultValue})

    if(BUILD_${ComponentName})
        add_subdirectory(${Dir} ${ComponentName})
    endif()
endfunction()

# Copy the file or dir to CMAKE_CURRENT_BINARY_DIR. If the path is relative, it is assumed to be relative to
# CMAKE_SOURCE_DIR.
function(copy target path)
    copy_to(${target} ${path} ${CMAKE_CURRENT_BINARY_DIR})
endfunction()

# Copy the file or dir to the given destination. If the path is relative, it is assumed to be relative to
# CMAKE_SOURCE_DIR. If destination is relative, it is assumed to be relative to CMAKE_CURRENT_BINARY_DIR.
function(copy_to target path destination)
    set(pathAbs ${path})
    if(NOT IS_ABSOLUTE ${path})
        set(pathAbs ${CMAKE_SOURCE_DIR}/${path})
    endif()

    set(destAbs ${destination})
    if(NOT IS_ABSOLUTE ${path})
        set(destAbs ${CMAKE_SOURCE_DIR}/${path})
    endif()

    if(IS_DIRECTORY ${pathAbs})
        get_filename_component(dst ${pathAbs} NAME)
        add_custom_target(
            Copy_${target}_${path} ALL COMMAND ${CMAKE_COMMAND} -E copy_directory ${pathAbs} ${destAbs}/${dst}
        )
    else()
        configure_file(${pathAbs} "${destination}" COPYONLY)
    endif()
endfunction()

# Copy and configure the specified file to CMAKE_CURRENT_BINARY_DIR. If the path is relative, it is assumed to be
# relative to CMAKE_CURRENT_SOURCE_DIR. This replaces CMake-known variables in the form of @VARNAME@ in the file.
function(config path)
    config_as(${path} "${CMAKE_CURRENT_BINARY_DIR}")
endfunction()

# Copy and configure the specified file to a specified destination path. If the path is relative, it is assumed to be
# relative to CMAKE_CURRENT_SOURCE_DIR. This replaces CMake-known variables in the form of @VARNAME@ in the file.
function(config_as path dest)
    set(p ${path})
    if(NOT IS_ABSOLUTE ${path})
        set(p ${CMAKE_CURRENT_SOURCE_DIR}/${path})
    endif()

    if(IS_DIRECTORY ${p})
        message(WARNING "Configuring directories is not supported")
        return()
    endif()

    configure_file(${p} ${dest} @ONLY)
endfunction()
