# Very basic PCH example
option(ENABLE_PCH "Enable Precompiled Headers" OFF)
if(ENABLE_PCH)
    # You should actually adapt this to your needs.
    target_precompile_headers(project_options INTERFACE <vector> <string> <map> <utility>)
endif()
