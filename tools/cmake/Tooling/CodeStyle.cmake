# ######################################################################################################################
# Check the code style of c,cpp,h,hpp in src and include.
#
# Can be called directly in script-mode from the project root via:
#
# cmake -P tools/cmake/Tooling/CodeStyle.cmake [fix|check]

# Try finding it.
find_program(
    CLANGFORMAT_BINARY
    NAMES
    clang-format
    clang-format-25
    clang-format-24
    clang-format-23
    clang-format-22
    clang-format-21
    clang-format-20
    clang-format-19
    clang-format-18
    clang-format-17
    clang-format-16
    clang-format-15
    clang-format-14
)
if(CLANGFORMAT_BINARY)
    if(EXISTS "${CMAKE_SOURCE_DIR}/.clang-format")
        message(VERBOSE "clang-format and config found: ${CLANGFORMAT_BINARY}")
    else()
        message(WARNING "No .clang-format configuration found in ${CMAKE_SOURCE_DIR}. ")
        return()
    endif()
else()
    message(WARNING "clang-format not found. Make sure it is in your PATH.")
    return()
endif()

# Search all files to process
file(
    GLOB_RECURSE ALL_INCLUDE_FILES
    RELATIVE ${CMAKE_SOURCE_DIR}
    "${CMAKE_SOURCE_DIR}/include/*.[ch]" "${CMAKE_SOURCE_DIR}/include/*.cpp" "${CMAKE_SOURCE_DIR}/include/*.hpp"
)

file(
    GLOB_RECURSE ALL_SRC_FILES
    RELATIVE ${CMAKE_SOURCE_DIR}
    "${CMAKE_SOURCE_DIR}/src/*.[ch]" "${CMAKE_SOURCE_DIR}/src/*.cpp" "${CMAKE_SOURCE_DIR}/src/*.hpp"
)

# Check and optionally fix a single file
function(codestyle_checkfile filename autofix)
    execute_process(
        COMMAND ${CLANGFORMAT_BINARY} --dry-run --ferror-limit=1 -Werror ${filename}
        WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
        OUTPUT_VARIABLE styleOut
        ERROR_VARIABLE styleErr
        RESULT_VARIABLE result
    )

    if(NOT "${result}" EQUAL "0")

        # If we should not fix it, show a message and return
        if(NOT "${autofix}" EQUAL "1")
            message("UGLY: ${fn}")
            return()
        endif()

        execute_process(
            COMMAND ${CLANGFORMAT_BINARY} -i ${filename}
            WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
            OUTPUT_VARIABLE styleOut
            ERROR_VARIABLE styleErr
        )

        if(NOT "${styleErr}" STREQUAL "")
            message("ERROR: ${fn}: ${styleErr}")
            return()
        endif()

        message("FIXED: ${fn}")
    endif()
endfunction()

# Fix issues
function(codestyle_fix)
    message(STATUS "Fixing code style")
    foreach(fn IN LISTS ALL_INCLUDE_FILES ALL_SRC_FILES)
        codestyle_checkfile(${fn} "1")
    endforeach()
endfunction()

# Check and report issues
function(codestyle_check)
    message(STATUS "Checking code style")
    foreach(fn IN LISTS ALL_INCLUDE_FILES ALL_SRC_FILES)
        codestyle_checkfile(${fn} "0")
    endforeach()
endfunction()

# If this is run in script mode, execute accordingly. If not, some targets are added for convenient execution
if(CMAKE_SCRIPT_MODE_FILE AND NOT CMAKE_PARENT_LIST_FILE)
    if(CODESTYLE_FIX)
        codestyle_fix()
    else()
        codestyle_check()
    endif()
else()
    message(STATUS "Stylecheck enabled")
    add_custom_target(
        stylecheck
        COMMAND ${CMAKE_COMMAND} -P ${CMAKE_CURRENT_LIST_FILE}
        WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
    )

    add_custom_target(
        stylefix
        COMMAND ${CMAKE_COMMAND} -DCODESTYLE_FIX=1 -P ${CMAKE_CURRENT_LIST_FILE}
        WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
    )
endif()
