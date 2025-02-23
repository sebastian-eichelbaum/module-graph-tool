# ######################################################################################################################
# {{{1 Setup of these cmake helpers

# Make this path and the finders path known to cmake.
list(PREPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}")
list(PREPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}/Finders")

# Some sanity checking
include(Sanity/NoInSourceBuild)
include(Sanity/EnsureBuildType)

# ######################################################################################################################
# {{{1 Global compilation tools

# Create project_options target and set some sane defaults
include(Compiling/ProjectOptions)

# Create project_warnings target and set some useful warnings (usually not covered by -Wall and -Wextra)
include(Compiling/ProjectWarnings)

# Automatic configuration of version.h.in files
include(Compiling/Version)

# C++ 20 Module support
include(Compiling/ModuleSupport)

# }}}

# ######################################################################################################################
# {{{1 Target specific compilation tools

# PCH Feature. You should configure this to make real use of it.
include(Compiling/PrecompiledHeaders)

# Unity builds compile all sources of a target as one single file. Can speed up compilation of larger, seldom modified
# libs /parts of code. Needs to be setup per target.
include(Compiling/UnityBuilds)

# Link time optimization. Can be setup globally or per target# Link time optimization. Can be setup globally or per
# target.
include(Compiling/LinkTimeOptimization)

# }}}

# ######################################################################################################################
# {{{1 Build/Bundle/Doc Tooling

# Cache. On by default if ccache is installed.
include(Tooling/Cache)

# Code Style formatting using clang-format
include(Tooling/CodeStyle)

# Documentation generation using doxygen and dot. Adds a target "doxygen"
include(Tooling/Doxygen)

# Utilize the compiler-provided sanitizers. Right now, this is only used if g++ or clang is used. All sanitizers are
# disabled by default.
#
# Creates the "project_sanitizers" target. You need to add this as target link lib to enable this per executable/lib.
include(Tooling/Sanitizers)

# Registers several static analyzers like clang_tidy to cmake. They run automatically if enabled. All analyzers are
# disabled by default.
include(Tooling/StaticAnalyzers)

# }}}

# ######################################################################################################################
# {{{1 Convenience tools to setup targets

# Some tools to easily setup libs and binaries. Also includes tools to collect code and assets.
include(Project/Targets)
include(Project/Bundles)

# Configure targets for different target platforms
include(Project/Platforms)

# }}}
