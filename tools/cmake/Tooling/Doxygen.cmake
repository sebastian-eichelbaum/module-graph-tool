# Enable Doxygen - on by default
option(ENABLE_DOXYGEN "Enable doxygen if available" ON)
if(NOT ENABLE_DOXYGEN)
    return()
endif()

find_package(Doxygen OPTIONAL_COMPONENTS dot)
if(DOXYGEN_FOUND)
    message(STATUS "Doxygen found and enabled.")

    # Where to find all the additional theme files
    set(docDir "${PROJECT_SOURCE_DIR}/doc/doxygen")
    set(docThemeDir "${PROJECT_SOURCE_DIR}/doc/doxygen/theme/doxygen-awesome-css")
    set(docThemeCustomizationDir "${PROJECT_SOURCE_DIR}/doc/doxygen/theme")

    # ##################################################################################################################
    # Style
    #

    # Using doxygen-awesome-css. See doc at https://jothepro.github.io/doxygen-awesome-css/index.html

    # Required by doxygen-awesome-css
    set(DOXYGEN_DISABLE_INDEX NO)
    # Disable full sidebar. Not yet supported.
    set(DOXYGEN_FULL_SIDEBAR NO)

    # Add some custom CSS according to doxygen-awesome-css doc
    set(DOXYGEN_HTML_EXTRA_STYLESHEET
        "${docThemeDir}/doxygen-awesome.css,${docThemeDir}/doxygen-awesome-sidebar-only.css,${docThemeDir}/doxygen-awesome-sidebar-only-darkmode-toggle.css,${docThemeCustomizationDir}/custom.css"
    )

    set(DOXYGEN_HTML_EXTRA_FILES
        "${docThemeDir}/doxygen-awesome-darkmode-toggle.js,${docThemeDir}/doxygen-awesome-fragment-copy-button.js"
    )

    # set custom header. Required to add darkmode toggle and more
    set(DOXYGEN_HTML_HEADER "${docThemeCustomizationDir}/header.html")

    # Some things cannot be overwritten by those CSS. Make the other colors match well:
    set(DOXYGEN_HTML_COLORSTYLE_HUE 209)
    set(DOXYGEN_HTML_COLORSTYLE_SAT 0)
    set(DOXYGEN_HTML_COLORSTYLE_GAMMA 80)

    # ##################################################################################################################
    # General setup and features to use
    #

    # Logo
    if(EXISTS "${PROJECT_LOGO}")
        set(DOXYGEN_PROJECT_LOGO "${PROJECT_LOGO}")
    endif()

    # Use the README as default page
    if(EXISTS "${PROJECT_SOURCE_DIR}/README.md")
        set(DOXYGEN_USE_MDFILE_AS_MAINPAGE "README.md")
    endif()

    # Configure dot - NOTE: the doxygen setting "HAVE_DOT" is set automatically if it was found.
    set(DOXYGEN_DOT_IMAGE_FORMAT svg)
    set(DOXYGEN_DOT_TRANSPARENT YES)

    # Do not strip doxygen comments in included code
    set(DOXYGEN_STRIP_CODE_COMMENTS NO)

    # This is the tree-like sidebar
    set(DOXYGEN_GENERATE_TREEVIEW YES)

    # Where to put it
    set(DOXYGEN_OUTPUT_DIRECTORY "./doc/")

    # Exclude the build dirs and the vcpkg_installed dirs explicitly.
    #
    # NOTE: also excludes examples/tests. They are not always properly doxygen-documented.
    set(DOXYGEN_EXCLUDE_PATTERNS
        "*/doc/doxygen/*,*/build*/*,*/vcpkg_installed,*/extern/*,*/external/nx.boilerplate/*,*/ext/*,*/examples/*,*/tests/*,*/scripts/*"
    )

    # Instead, include examples explicitly, making them available via @examples command. See below. examples and tests
    # are added if they exist.

    # set(DOXYGEN_EXAMPLE_PATH "examples/,tests/")

    # ##################################################################################################################
    # Alias definitions:
    #

    # Add @usage to provide code and doc on how to use this thing.
    set(DOXYGEN_ALIASES
        usage=\"@par
        Usage:\",
        examples=\"<h2><b>
        Examples:</b></h2>\",
        example{2}=\"<details
        open=
        \'\'>
        <summary>\\2:
        <b>\\1</b></summary>
        @snippet{lineno,trimleft}
        \\1
        \\2
        ^^</details>
        \",
        tests{1}=\"<details>
        <summary>Tests:
        <b>\\1</b></summary>
        @include{lineno}
        \\1
        ^^</details>
        \",
        specialization{1}=\"@remarks
        **Specialization**
        of
        @ref
        \\1
        \\n
        \"
    )

    # ##################################################################################################################
    # Parsing Setup
    #

    # Can help parsing template rich code at the cost of performance: set(DOXYGEN_CLANG_ASSISTED_PARSING YES)
    # set(DOXYGEN_CLANG_DATABASE_PATH .)

    # Graphs look more like UML: set(DOXYGEN_UML_LOOK YES)

    # Direct and indirect inheritance relations
    set(DOXYGEN_CLASS_GRAPH YES)
    # The direct and indirect implementation dependencies (inheritance, containment, and class references variables)
    set(DOXYGEN_COLLABORATION_GRAPH YES)
    # The relations between templates and their instances.
    set(DOXYGEN_TEMPLATE_RELATIONS NO)
    # The direct and indirect include dependencies of the file with other documented files
    set(DOXYGEN_INCLUDE_GRAPH YES)
    # The direct and indirect include dependencies of the file with other documented files
    set(DOXYGEN_INCLUDED_BY_GRAPH YES)
    # Caller dependency graph for every global function or class method
    set(DOXYGEN_CALLER_GRAPH YES)
    # Call dependency graph for every global function or class method
    set(DOXYGEN_CALL_GRAPH YES)
    # Graphical hierarchy of all classes instead of a textual one
    set(DOXYGEN_GRAPHICAL_HIERARCHY YES)
    # The dependencies a directory has on other directories. The dependency relations are determined by the #include
    # relations between the files in the directories.
    set(DOXYGEN_DIRECTORY_GRAPH YES)

    # Make the SVG scalable and pan-able in the browser set(DOXYGEN_INTERACTIVE_SVG YES)

    # Collapse those graph views by default?
    set(DOXYGEN_HTML_DYNAMIC_SECTIONS NO)

    # Info to extract from code:
    set(DOXYGEN_EXTRACT_PRIVATE YES)
    set(DOXYGEN_EXTRACT_PRIV_VIRTUAL YES)
    set(DOXYGEN_EXTRACT_PACKAGE YES)
    set(DOXYGEN_EXTRACT_STATIC YES)
    set(DOXYGEN_EXTRACT_LOCAL_CLASSES YES)
    set(DOXYGEN_EXTRACT_LOCAL_METHODS YES)
    set(DOXYGEN_EXTRACT_ANON_NSPACES YES)
    # Can produce a lot of warning but is worth it as it forces us to document properly.
    set(DOXYGEN_EXTRACT_ALL YES)

    # Configure warnings - these are not triggered if EXTRACT_ALL is true?!
    set(DOXYGEN_QUIET YES)
    set(DOXYGEN_WARNINGS YES)
    set(DOXYGEN_WARN_IF_UNDOCUMENTED YES)
    set(DOXYGEN_WARN_NO_PARAMDOC YES)
    set(DOXYGEN_WARN_IF_DOC_ERROR YES)
    set(DOXYGEN_WARN_IF_INCOMPLETE_DOC YES)

    # Autobrief makes the first sentence of a block a brief doc.
    set(DOXYGEN_JAVADOC_AUTOBRIEF YES)
    set(DOXYGEN_T_AUTOBRIEF YES)

    # Do not include detail namespaces set(DOXYGEN_EXCLUDE_SYMBOLS
    # "_details,_details::*,*::_details::*,_detail,_detail::*,*::_detail::*")

    # If this code base contains examples, add them. This allows linking examples using @example or @snipped
    set(DOXYGEN_EXAMPLE_PATH "")
    if(EXISTS ${PROJECT_SOURCE_DIR}/examples)
        list(APPEND DOXYGEN_EXAMPLE_PATH "${PROJECT_SOURCE_DIR}/examples")
    endif()
    if(EXISTS ${PROJECT_SOURCE_DIR}/tests)
        list(APPEND DOXYGEN_EXAMPLE_PATH "${PROJECT_SOURCE_DIR}/tests")
    endif()
    if(EXISTS ${PROJECT_SOURCE_DIR}/external/nx)
        list(APPEND DOXYGEN_EXAMPLE_PATH "${PROJECT_SOURCE_DIR}/external/nx")
    endif()

    # This adds a target "doxygen" for us.
    doxygen_add_docs(
        doxygen ${PROJECT_SOURCE_DIR} ${PROJECT_SOURCE_DIR}/external/nx COMMENT "Generate doxygen code docs"
    )
else()
    message(WARNING "Doxygen is enabled but was not found. Not using it.")
endif()
