# Create a bundle. A bundle is nothing more than an interface library target that depends on all the additional assets
# that where added with one of the bundle_XYZ functions. This adds a property "BUNDLE_OUTPUT_DIRECTORY" to the target to
# indicate the output path.
#
# Make sure that the bundle name is not yet used by any other target
function(add_bundle BundleName)
    add_library("bundle_${BundleName}" INTERFACE)

    define_property(
        TARGET
        PROPERTY BUNDLE_OUTPUT_DIRECTORY
        BRIEF_DOCS "Where to put the bundle contents."
        FULL_DOCS "Where to put the bundle contents."
    )

    set_target_properties("bundle_${BundleName}" PROPERTIES BUNDLE_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bundle")
endfunction()

# Setup a target to be part of a bundle. Call this once for a target. This ensures the target gets put into a proper
# bundle directory, that the bundle-associated assets are copied and so on. A target can only be used in one bundle.
#
# This adds the property "BUNDLE_NAME" to the target
function(bundle_target BundleName TargetName)
    # Properties like RUNTIME_OUTPUT_DIRECTORY are not inherited from the dependant bundle. Set them for this target
    # according to the BUNDLE_OUTPUT_DIRECTORY
    get_target_property(bundleDir "bundle_${BundleName}" BUNDLE_OUTPUT_DIRECTORY)
    if(NOT bundleDir)
        message(FATAL_ERROR "Bundle output directory not set. Probably, the bundle ${BundleName} does not exist")
    endif()

    define_property(
        TARGET
        PROPERTY BUNDLE_NAME
        BRIEF_DOCS "The name of the bundle the target is used in."
        FULL_DOCS "The name of the bundle the target is used in."
    )

    set_target_properties(
        ${TargetName}
        PROPERTIES ARCHIVE_OUTPUT_DIRECTORY "${bundleDir}"
                   LIBRARY_OUTPUT_DIRECTORY "${bundleDir}"
                   RUNTIME_OUTPUT_DIRECTORY "${bundleDir}"
                   BUNDLE_NAME "${BundleName}"
    )

    add_dependencies(${TargetName} "bundle_${BundleName}")

endfunction()

# Copy and configure the specified file to the given destination, relative to the bundle directory. The destination is
# an optional parameter. If not specified, the file will be placed in the bundle directory as is. Absolute paths as
# destination are not allowed.
#
# If the source path is relative, it is assumed to be relative to CMAKE_CURRENT_SOURCE_DIR. This replaces CMake-known
# variables in the form of @VARNAME@ in the file.
function(bundle_configure_file BundleName path)
    if(ARGC GREATER 3)
        message(FATAL_ERROR "Only 2 or 3 arguments are accepted")
    endif()

    get_target_property(dest "bundle_${BundleName}" BUNDLE_OUTPUT_DIRECTORY)
    if(NOT dest)
        message(FATAL_ERROR "Bundle output directory not set. Probably, the bundle ${BundleName} does not exist")
    endif()

    # If the destination is given, check if relative and add to current path
    if(ARGC GREATER 2)
        if(IS_ABSOLUTE ${ARGV2})
            message(FATAL_ERROR "Destination path must not be absolute.")
        endif()

        set(dest ${dest}/${ARGV2})
    endif()

    # Relative paths are relative to the current source dir
    set(p ${path})
    if(NOT IS_ABSOLUTE ${path})
        set(p ${CMAKE_CURRENT_SOURCE_DIR}/${path})
    endif()

    if(IS_DIRECTORY ${p})
        message(FATAL_ERROR "Configuring directories is not supported")
    endif()

    configure_file(${p} ${dest} @ONLY)

    # message(${p} " to " ${dest})
endfunction()

# Add the given directory to the bundle. Provide the bundle name, the path to add and "as" - the target path. If the
# given path does not exist, this is a NOP.
function(bundle_assets BundleName path as)
    get_target_property(dest "bundle_${BundleName}" BUNDLE_OUTPUT_DIRECTORY)
    if(NOT dest)
        message(FATAL_ERROR "Bundle output directory not set. Probably, the bundle ${BundleName} does not exist")
    endif()

    set(pathAbs ${path})
    if(NOT IS_ABSOLUTE ${path})
        set(pathAbs ${CMAKE_CURRENT_SOURCE_DIR}/${path})
    endif()

    if(NOT IS_DIRECTORY ${pathAbs})
        message(NOTICE "Bundle \"${BundleName}\": asset path \"${pathAbs}\" does not exist. Skipping.")
        return()
    endif()

    if(IS_ABSOLUTE ${as})
        message(FATAL_ERROR "Asset destination must not be absolute.")
    endif()

    if(UNIX AND NOT APPLE)
        set(linkPath "${dest}/${as}")
    else()
        message(FATAL_ERROR "Linking assets on non-unix(and Apple) not yet verified.")
        # set(linkPath "${dest}/$<CONFIG>/${as}")
    endif()

    get_filename_component(destDir ${linkPath} DIRECTORY)
    file(MAKE_DIRECTORY ${destDir})
    file(CREATE_LINK "${pathAbs}" "${linkPath}" SYMBOLIC)
endfunction()
