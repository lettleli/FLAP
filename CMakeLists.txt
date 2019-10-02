# The target of the library FLAP is exported
# as FLAP::FLAP to a package config file for FLAP
#
# usage:
#     find_package(FLAP)
#     ...
#     target_link_library(<target> FLAP)
#
# the config file is generatet in the build and install directories

cmake_minimum_required(VERSION 3.14...3.15)
project(FLAP VERSION 1.1.8 LANGUAGES Fortran)

# seach path for additional cmake modules
list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_LIST_DIR}/cmake/Modules)


# set export variables needed for building
set(TARGETS_EXPORT_NAME "${PROJECT_NAME}-targets")
set(NAMESPACE "${PROJECT_NAME}::")


# third party packages
option(USE_GIT_SUBMODULES "Use the git submodules in src/third_party instead of downloading the needed Packages with FetchContent" ON)
if(USE_GIT_SUBMODULES)
    find_package(Git QUIET)
    if(GIT_FOUND)
        # Update submodules as needed
        option(GIT_SUBMODULE "Check submodules during build" OFF)
        if(GIT_SUBMODULE)
            message(DEBUG "Submodule update")
            execute_process(COMMAND ${GIT_EXECUTABLE} submodule update --init --recursive
                            WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
                            RESULT_VARIABLE GIT_SUBMOD_RESULT)
            if(NOT GIT_SUBMOD_RESULT EQUAL "0")
                message(FATAL_ERROR "git submodule update --init --recursive failed with ${GIT_SUBMOD_RESULT}, please checkout submodules")
            endif()
        endif()
    endif()
endif()

include(AddExternalGitPackage)

if(USE_GIT_SUBMODULES)
    set(FACE_SUBMODULE ${CMAKE_CURRENT_SOURCE_DIR}/src/third_party/FACE)
    set(PENF_SUBMODULE ${CMAKE_CURRENT_SOURCE_DIR}/src/third_party/PENF)
endif()

add_external_git_package(FACE
    TARGETS FACE::FACE
    GIT_REPOSITORY https://github.com/szaghi/FACE.git
    GIT_TAG master
    FETCHCONTENT_SOURCE_DIR ${FACE_SUBMODULE}
)

add_external_git_package(PENF
    TARGETS PENF::PENF
    GIT_REPOSITORY https://github.com/szaghi/PENF.git
    GIT_TAG master
    FETCHCONTENT_SOURCE_DIR ${PENF_SUBMODULE}
)

# generate the library and install instructions
add_subdirectory(src/lib)

# testing
if(${PROJECT_SOURCE_DIR} STREQUAL ${CMAKE_SOURCE_DIR})
    set(main_project TRUE)
else()
    set(main_project FALSE)
endif()

include(CMakeDependentOption)
cmake_dependent_option(BUILD_TESTING_${PROJECT_NAME}
     "Build the testing tree for project ${PROJECT_NAME}." OFF
     "BUILD_TESTING;NOT main_project" OFF
)

if((main_project AND BUILD_TESTING) OR BUILD_TESTING_${PROJECT_NAME})
    # third party packages for testing
    if(USE_GIT_SUBMODULES)
        set(fortran_tester_SUBMODULE ${CMAKE_CURRENT_SOURCE_DIR}/src/third_party/fortran_tester)
    endif()

    add_external_git_package(fortran_tester
        TARGETS fortran_tester::fortran_tester
        GIT_REPOSITORY https://github.com/pdebuyl/fortran_tester.git
        GIT_TAG master
        FETCHCONTENT_SOURCE_DIR ${fortran_tester_SUBMODULE}
    )

    enable_testing()
    add_subdirectory(src/tests)
endif()

# generate package config files
include(GNUInstallDirs)
set(project_config "${PROJECT_NAME}-config.cmake")
set(cmake_files_dir "${CMAKE_CURRENT_BINARY_DIR}/CMakeFiles")
set(config_install_dir "${CMAKE_INSTALL_LIBDIR}/cmake/${PROJECT_NAME}")
set(config_build_dir "${CMAKE_CURRENT_BINARY_DIR}/${config_install_dir}")

# export targets for install
install(EXPORT ${TARGETS_EXPORT_NAME}
    NAMESPACE
        ${NAMESPACE}
    DESTINATION
        ${config_install_dir}
    COMPONENT Development
)

# export targets into build
export(EXPORT ${TARGETS_EXPORT_NAME}
    NAMESPACE
        ${NAMESPACE}
    FILE
        ${config_build_dir}/${TARGETS_EXPORT_NAME}.cmake
)

#create package config
include(CMakePackageConfigHelpers)
configure_package_config_file(cmake/PackageConfig.cmake.in ${cmake_files_dir}/${project_config}
    INSTALL_DESTINATION ${config_install_dir}
)
install(FILES ${cmake_files_dir}/${project_config}
    DESTINATION ${config_install_dir}
)

configure_package_config_file(cmake/PackageConfig.cmake.in ${config_build_dir}/${project_config}
    INSTALL_DESTINATION ${config_build_dir}
    INSTALL_PREFIX ${CMAKE_CURRENT_BINARY_DIR}
)
