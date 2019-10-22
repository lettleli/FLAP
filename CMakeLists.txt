# The target of the FLAP library is exported
# as FLAP::FLAP to a package configuration file for this library
#
# usage:
#     find_package(FLAP)/add_subdirectory(...)
#     ...
#     target_link_library(<target> FLAP::FLAP)
#
# the config file is generatet in the build and install directories
#
# to build the documentation build the target doc (ford is needed)
#
# to build the tests enable the option BUILD_TESTING (FLAP_BUILD_TESTING)
# if this is the main project (a subproject)
# afterwards they can be run with ctest

cmake_minimum_required(VERSION 3.14...3.15)
project(FLAP VERSION 1.1.8 LANGUAGES Fortran)

# seach path for additional cmake modules
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}/cmake/Modules")

# set export variables needed in subdirectories
set(TARGETS_EXPORT_NAME "${PROJECT_NAME}-targets")
set(NAMESPACE "${PROJECT_NAME}::")

# # third party packages
include(AddExternalGitPackage)

add_external_git_package(FACE
    TARGETS FACE::FACE
    GIT_REPOSITORY https://github.com/szaghi/FACE.git
    GIT_TAG master
    FETCHCONTENT_SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/src/third_party/FACE"
)

add_external_git_package(PENF
    TARGETS PENF::PENF
    GIT_REPOSITORY https://github.com/szaghi/PENF.git
    GIT_TAG master
    FETCHCONTENT_SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/src/third_party/PENF"
)

# generate the library and install instructions
add_subdirectory(src/lib)

add_subdirectory(doc EXCLUDE_FROM_ALL)

# testing
if(${PROJECT_SOURCE_DIR} STREQUAL ${CMAKE_SOURCE_DIR})
    set(main_project TRUE)
    option(BUILD_TESTING "Build the testing tree." OFF)
else()
    set(main_project FALSE)

    # if this is not the main project but BUILD_TESTIG is set to TRUE
    # the tests for this project can be enabled by also setting
    # BUILD_TESTING_${PROJECT_NAME} to TRUE
    include(CMakeDependentOption)
    cmake_dependent_option(BUILD_TESTING_${PROJECT_NAME}
        "Build the testing tree for project ${PROJECT_NAME}." OFF
        "BUILD_TESTING;NOT main_project" OFF
    )

endif()

if((main_project OR BUILD_TESTING_${PROJECT_NAME}) AND BUILD_TESTING)
    add_external_git_package(fortran_tester
        TARGETS fortran_tester::fortran_tester
        GIT_REPOSITORY https://github.com/pdebuyl/fortran_tester.git
        GIT_TAG master
        FETCHCONTENT_SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/src/third_party/fortran_tester"
    )
    enable_testing()
    add_subdirectory(src/tests)
endif()

# generate package config files
include(GNUInstallDirs)
set(project_config "${PROJECT_NAME}-config.cmake")
set(project_config_version "${PROJECT_NAME}-config-version.cmake")
set(cmake_files_dir "${CMAKE_CURRENT_BINARY_DIR}/CMakeFiles")
set(default_config_install_dir "${CMAKE_INSTALL_LIBDIR}/cmake/${PROJECT_NAME}")
set(config_build_dir "${CMAKE_CURRENT_BINARY_DIR}/${default_config_install_dir}")
set(${PROJECT_NAME}_INSTALL_CMAKEDIR ${default_config_install_dir} CACHE PATH "Path into which the cmake files for project ${PROJECT_NAME} will be installed.")

# export targets for install
install(EXPORT ${TARGETS_EXPORT_NAME}
    NAMESPACE
        ${NAMESPACE}
    DESTINATION
        ${${PROJECT_NAME}_INSTALL_CMAKEDIR}
    COMPONENT
        ${PROJECT_NAME}_Development
)

# export targets into build
export(EXPORT ${TARGETS_EXPORT_NAME}
    NAMESPACE
        ${NAMESPACE}
    FILE
        "${config_build_dir}/${TARGETS_EXPORT_NAME}.cmake"
)

# create package config
# Variables needed by PackageConfig.cmake.in: PROJECT_NAME, TARGETS_EXPORT_NAME,
#                                             PACKAGE_DEPENDENCIES

set(PACKAGE_DEPENDENCIES FACE PENF)
include(CMakePackageConfigHelpers)
configure_package_config_file(cmake/PackageConfig.cmake.in "${cmake_files_dir}/${project_config}"
    INSTALL_DESTINATION ${${PROJECT_NAME}_INSTALL_CMAKEDIR}
)

configure_package_config_file(cmake/PackageConfig.cmake.in "${config_build_dir}/${project_config}"
    INSTALL_DESTINATION ${config_build_dir}
    INSTALL_PREFIX ${CMAKE_CURRENT_BINARY_DIR}
)

write_basic_package_version_file(
    "${config_build_dir}/${project_config_version}"
    VERSION ${PROJECT_VERSION}
    COMPATIBILITY SameMajorVersion
)

install(
    FILES
        "${cmake_files_dir}/${project_config}"
        "${config_build_dir}/${project_config_version}"
    DESTINATION
        ${${PROJECT_NAME}_INSTALL_CMAKEDIR}
    COMPONENT
        ${PROJECT_NAME}_Development
)