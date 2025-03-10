# Create a default target to contain all project options
if(NOT TARGET project_sanitizers)
  add_library(project_sanitizers INTERFACE)
endif()

if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU" OR CMAKE_CXX_COMPILER_ID MATCHES
                                           ".*Clang")

  # NOTE: removed coverage. Its not really a sanitzer?!

  set(SANITIZERS "")

  option(ENABLE_SANITIZER_ADDRESS "Enable address sanitizer" FALSE)
  if(ENABLE_SANITIZER_ADDRESS)
    list(APPEND SANITIZERS "address")
  endif()

  option(ENABLE_SANITIZER_LEAK "Enable leak sanitizer" FALSE)
  if(ENABLE_SANITIZER_LEAK)
    list(APPEND SANITIZERS "leak")
  endif()

  option(ENABLE_SANITIZER_UNDEFINED_BEHAVIOR
         "Enable undefined behavior sanitizer" FALSE)
  if(ENABLE_SANITIZER_UNDEFINED_BEHAVIOR)
    list(APPEND SANITIZERS "undefined")
  endif()

  option(ENABLE_SANITIZER_THREAD "Enable thread sanitizer" FALSE)
  if(ENABLE_SANITIZER_THREAD)
    if("address" IN_LIST SANITIZERS OR "leak" IN_LIST SANITIZERS)
      message(
        WARNING
          "Thread sanitizer does not work with Address and Leak sanitizer enabled"
      )
    else()
      list(APPEND SANITIZERS "thread")
    endif()
  endif()

  option(ENABLE_SANITIZER_MEMORY "Enable memory sanitizer" FALSE)
  if(ENABLE_SANITIZER_MEMORY AND CMAKE_CXX_COMPILER_ID MATCHES ".*Clang")
    if("address" IN_LIST SANITIZERS
       OR "thread" IN_LIST SANITIZERS
       OR "leak" IN_LIST SANITIZERS)
      message(
        WARNING
          "Memory sanitizer does not work with Address, Thread and Leak sanitizer enabled"
      )
    else()
      list(APPEND SANITIZERS "memory")
    endif()
  endif()

  list(JOIN SANITIZERS "," LIST_OF_SANITIZERS)

endif()

if(LIST_OF_SANITIZERS)
  if(NOT "${LIST_OF_SANITIZERS}" STREQUAL "")
    target_compile_options(project_sanitizers
                           INTERFACE -fsanitize=${LIST_OF_SANITIZERS})
    target_link_options(project_sanitizers INTERFACE
                        -fsanitize=${LIST_OF_SANITIZERS})
  endif()
endif()
