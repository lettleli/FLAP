function(add_external_git_package NAME)
    set(options )
    set(oneValueArgs GIT_REPOSITORY GIT_TAG FETCHCONTENT_SOURCE_DIR)
    set(multiValueArgs TARGETS)
    cmake_parse_arguments(git_add "${options}" "${oneValueArgs}"
                        "${multiValueArgs}" ${ARGN})
    find_package(${NAME} QUIET)

    if (NOT (${NAME}_FOUND))
        foreach(target IN LISTS git_add_TARGETS)
            if(TARGET ${target})
                message(DEBUG "Target ${target} already exists, skip FetchContent")
                return()
            endif()
        endforeach()

        include(FetchContent)
        FetchContent_Declare(
            ${NAME}
            GIT_REPOSITORY ${git_add_GIT_REPOSITORY}
            GIT_TAG ${git_add_GIT_TAG}
        )
        string(TOUPPER ${NAME} uc_name)
        if(EXISTS ${git_add_FETCHCONTENT_SOURCE_DIR}/.git)
            set(FETCHCONTENT_SOURCE_DIR_${uc_name} ${git_add_FETCHCONTENT_SOURCE_DIR} CACHE PATH "")
        endif()
        FetchContent_MakeAvailable(${NAME})
        # FetchContent_GetProperties(${NAME})
        # string(TOLOWER ${NAME} lc_name)
        # if(NOT ${lc_name}_POPULATED)
        #     message(STATUS "Populating ${NAME} project ...")
        #     FetchContent_Populate(${NAME})
        #     add_subdirectory(${${lc_name}_SOURCE_DIR} ${${lc_name}_BINARY_DIR})
        # endif()
    endif()

endfunction()
