set(_current_list_dir ${CMAKE_CURRENT_LIST_DIR})

function(pch_link_target target pch_header)
    # Hide warnings for clang PCH header
    target_compile_options(${target} PUBLIC "-Wno-invalid-pch")

    # Write actual compile command to json file
    set(CMAKE_EXPORT_COMPILE_COMMANDS TRUE PARENT_SCOPE)

    # Get lang
    if (ARGN)
        list(GET ARGN 0 pchlangid)
    else()
        get_property(enabled_langs GLOBAL PROPERTY ENABLED_LANGUAGES)
        list(FIND enabled_langs CXX index)
        if(index STREQUAL -1)
            list(GET enabled_langs 0 pchlangid)
        else()
            set(pchlangid CXX)
        endif()
    endif()

    set(compile_source "")
    set(gch_path ${CMAKE_CURRENT_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/${target}_pch.dir/${pch_header}.gch)
    get_target_property(sources ${target} SOURCES)

    # Check for Objective-C/Objective-C++ files
    if(pchlangid STREQUAL CXX)
        set(RX "\\.mm$")
    else()
        set(RX "\\.m$")
    endif()

    foreach(s ${sources})
        if(s MATCHES "^\\\$<")
            continue()
        endif()

        get_source_file_property(langid ${s} LANGUAGE)

        if(s MATCHES ${RX})
            set(has_objc TRUE)
        endif()
    endforeach()

    if(has_objc)
        foreach(s ${sources})
            if(s MATCHES "^\\\$<")
                continue()
            endif()

            get_source_file_property(langid ${s} LANGUAGE)
            if (langid AND (pchlangid STREQUAL langid) AND (NOT ${s} MATCHES ${RX}))
                set(compile_source ${s})
                if(${CMAKE_VERSION} VERSION_LESS "3.10.0")
                    set_source_files_properties(${s} PROPERTIES COMPILE_FLAGS "-include ${CMAKE_CURRENT_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/${target}_pch.dir/${pch_header}")
                else()
                    set_source_files_properties(${s} PROPERTIES COMPILE_OPTIONS "-include;${CMAKE_CURRENT_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/${target}_pch.dir/${pch_header}")
                endif()
            endif()
        endforeach()
    else()
        # Propogate PCH header to automoc sources
        target_compile_options(${target} PRIVATE "$<$<COMPILE_LANGUAGE:${pchlangid}>:-include;${CMAKE_CURRENT_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/${target}_pch.dir/${pch_header}>")
        foreach(s ${sources})
            if(s MATCHES "^\\\$<")
                continue()
            endif()

            get_source_file_property(langid ${s} LANGUAGE)

            if (langid AND (pchlangid STREQUAL langid) AND (NOT s MATCHES ${RX}))
                set(compile_source ${s})
            endif()
        endforeach()
    endif()

    add_custom_target(${target}_pch
        ${CMAKE_COMMAND} -DSOURCE_FILE=${compile_source}
                         -DTARGET=${target}
                         -DSOURCE_DIR=${CMAKE_CURRENT_SOURCE_DIR}
                         -DBINARY_DIR=${CMAKE_BINARY_DIR}
                         -DCURRENT_BINARY_DIR=${CMAKE_CURRENT_BINARY_DIR}
                         -DPCH=${pch_header}
                         -DLANG=${pchlangid}
                         -P ${_current_list_dir}/CompilePch.cmake
        BYPRODUCTS ${CMAKE_CURRENT_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/${target}_pch.dir/${pch_header}.gch/gch
                   ${CMAKE_CURRENT_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/${target}_pch.dir/${pch_header}.gch/clang-gch
                   ${CMAKE_CURRENT_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/${target}_pch.dir/${pch_header}.gch
    )
    add_dependencies(${target} ${target}_pch)

    if(NOT TARGET compile-parse-compile-commands)
        add_custom_target(compile-parse-compile-commands
            ${CMAKE_COMMAND} -DBINARY_DIR=${CMAKE_BINARY_DIR}
                             -P ${_current_list_dir}/CompileParseCommand.cmake
            BYPRODUCTS ${CMAKE_BINARY_DIR}/parse-compile-commands${CMAKE_EXECUTABLE_SUFFIX}
        )
    endif()
    add_dependencies(${target}_pch compile-parse-compile-commands)
endfunction()
