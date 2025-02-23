# Enable CCache - on by default
option(ENABLE_CCACHE "Enable ccache if available" ON)
if(NOT ENABLE_CCACHE)
  return()
endif()

find_program(CCACHE_BINARY ccache)
if(CCACHE_BINARY)
  message(STATUS "ccache found and enabled: ${CCACHE_BINARY}")
  set(CMAKE_CXX_COMPILER_LAUNCHER ${CCACHE_BINARY})
else()
  message(WARNING "Cache is enabled but ccache was not found. Not using it.")
endif()
