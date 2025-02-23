# Enable link time optimization - disabled by default. Check carefully if this
# actually achieves the desired goal
option(ENABLE_IPO
       "Enable Interprocedural Optimization, aka Link Time Optimization (LTO)"
       OFF)

# Setup LTO for the given target
function(setup_lto target_name)
  if(ENABLE_IPO)
    include(CheckIPOSupported)
    check_ipo_supported(RESULT result OUTPUT output)
    if(result)
      message(STATUS "Enabling LTO for target: ${target_name}")
      set_property(TARGET ${target_name} PROPERTY INTERPROCEDURAL_OPTIMIZATION
                                                  TRUE)
    else()
      message(WARNING "IPO is not supported: ${output}")
    endif()
  endif()
endfunction()

# Setup LTO globally
function(setup_lto_global)
  if(ENABLE_IPO)
    include(CheckIPOSupported)
    check_ipo_supported(RESULT result OUTPUT output)
    if(result)
      message(STATUS "Enabling LTO globally.")
      set(CMAKE_INTERPROCEDURAL_OPTIMIZATION TRUE)
    else()
      message(WARNING "IPO is not supported: ${output}")
    endif()
  endif()
endfunction()
