# The target of the library FACE is exported
# as FACE::FACE to a package config file for FACE
#
# usage find_package(FACE)
# ...
# target_link_library(<target> FACE)
#
# the config file is generatet in the build and install directories

#################################################################
# HEADER
#################################################################
cmake_minimum_required(VERSION 3.11...3.13)
project(FLAP VERSION 1.1.8 LANGUAGES Fortran)

#################################################################
# seach path for additional cmake modules
#################################################################
list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_LIST_DIR}/cmake/Modules)

#################################################################
# set export variables needed for building
#################################################################

set(TARGETS_EXPORT_NAME "${PROJECT_NAME}-targets")
set(NAMESPACE "${PROJECT_NAME}::")

#################################################################
# third party packages 
#################################################################

find_package(FACE QUIET)

if (NOT FACE_FOUND)
    include(FetchContent)
    FetchContent_Declare(
        FACE
        GIT_REPOSITORY https://github.com/lettleli/FACE.git
        GIT_TAG modern_cmake_targets
    )

    FetchContent_GetProperties(FACE)
    if(NOT face_POPULATED)
        message(STATUS "Populating FACE project ...")
        FetchContent_Populate(FACE)
        add_subdirectory(${face_SOURCE_DIR} ${face_BINARY_DIR})
    endif()
    unset(CMAKE_PREFIX_PATH)
    set(CMAKE_PREFIX_PATH ${CMAKE_PREFIX_PATH} ${face_BINARY_DIR} CACHE STRING "Directories specifying installation prefixes to be searched with find_...()" FORCE)
endif()

find_package(PENF QUIET)

if (NOT PENF_FOUND)
    include(FetchContent)
    FetchContent_Declare(
        PENF
        GIT_REPOSITORY https://github.com/lettleli/PENF.git
        GIT_TAG modern_cmake_targets
    )

    FetchContent_GetProperties(PENF)
    if(NOT penf_POPULATED)
        message(STATUS "Populating PENF project ...")
        FetchContent_Populate(PENF)
        add_subdirectory(${penf_SOURCE_DIR} ${penf_BINARY_DIR})
    endif()
    unset(CMAKE_PREFIX_PATH)
    set(CMAKE_PREFIX_PATH ${CMAKE_PREFIX_PATH} ${penf_BINARY_DIR} CACHE STRING "Directories specifying installation prefixes to be searched with find_...()" FORCE)
endif()


#################################################################
# generate the library and install instructions
#################################################################

add_subdirectory(src/lib)

#################################################################
# ENABLE TESTING
#################################################################

option(BUILD_TESTING "Build the testing tree." OFF)
if(BUILD_TESTING)
    include(CTest)
    find_package(fortran_tester QUIET)

    if (NOT fortran_tester_FOUND)
        include(FetchContent)
        FetchContent_Declare(
            fortran_tester
            GIT_REPOSITORY https://github.com/lettleli/fortran_tester.git
            GIT_TAG modern_cmake_targets
        )

        FetchContent_GetProperties(fortran_tester)
        if(NOT fortran_tester_POPULATED)
            message(STATUS "Populating fortran_tester project ...")
            FetchContent_Populate(fortran_tester)
            add_subdirectory(${fortran_tester_SOURCE_DIR} ${fortran_tester_BINARY_DIR})
        endif()
        unset(CMAKE_PREFIX_PATH)
        set(CMAKE_PREFIX_PATH ${CMAKE_PREFIX_PATH} ${fortran_tester_BINARY_DIR} CACHE STRING "Directories specifying installation prefixes to be searched with find_...()" FORCE)
    endif()
    add_subdirectory(src/tests)
endif()

#################################################################
# generate package config files
#################################################################

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
