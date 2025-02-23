# When this property is set to true, the target source files will be combined
# into batches for faster compilation. This is done by creating a (set of) unity
# sources which #include the original sources, then compiling these unity
# sources instead of the originals. This is known as a Unity or Jumbo build.
#
# NOTE: needs to be set per target
option(ENABLE_UNITY "Enable Unity builds of projects" OFF)

function(setup_unity_build target_name)
  if(ENABLE_UNITY)
    # Add for any project you want to apply unity builds for
    set_target_properties(${target_name} PROPERTIES UNITY_BUILD ON)
  endif()
endfunction()
