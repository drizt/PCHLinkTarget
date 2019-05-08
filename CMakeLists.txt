cmake_minimum_required(VERSION 3.0)

add_subdirectory(examples/widgets-qt5)

# collect_info_files function
# Takes collect_info_files - list of non-source files to look for
# Returns INFO_FILES with all files found from the input list.
# Based on macro posted here
# http://lists.qt-project.org/pipermail/qt-creator/2012-August/001191.html [^]
function(collect_info_files)
    list(APPEND _all_found)
    foreach(_it ${ARGN})
        if(NOT IS_DIRECTORY ${_it})
            get_filename_component(_path ${_it} ABSOLUTE)
            if(EXISTS ${_path})
                list(APPEND _all_found ${_it})
                if(NOT ${_it} MATCHES "^/\\\\..*$;~$")
                    set_source_files_properties(${_it} PROPERTIES HEADER_FILE_ONLY TRUE)
                endif()
            endif()
        endif()
    endforeach()
    set(INFO_FILES ${_all_found} PARENT_SCOPE)
endfunction()

# Collect all existing files and configure as non-sources.
collect_info_files(
    cmake/CompileParseCommand.cmake
    cmake/CompilePch.cmake
    cmake/parse-compile-commands.c
    cmake/PCHLinkTarget.cmake
)

# Create dummy target/project for an IDE with documents attached
add_custom_target(cmake SOURCES ${INFO_FILES})
