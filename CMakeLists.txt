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


find_package(FACE QUIET)

if (NOT (FACE_FOUND OR (TARGET FACE::FACE)))
    include(FetchContent)
    FetchContent_Declare(
        FACE
        GIT_REPOSITORY https://github.com/szaghi/FACE.git
        GIT_TAG master
    )
    if (USE_GIT_SUBMODULES)
        set(FETCHCONTENT_SOURCE_DIR_FACE ${CMAKE_CURRENT_SOURCE_DIR}/src/third_party/FACE CACHE PATH "")
    endif()
    FetchContent_MakeAvailable(FACE)
    # FetchContent_GetProperties(FACE)
    # if(NOT face_POPULATED)
    #     message(STATUS "Populating FACE project ...")
    #     FetchContent_Populate(FACE)
    #     add_subdirectory(${face_SOURCE_DIR} ${face_BINARY_DIR})
    # endif()
endif()

find_package(PENF QUIET)

if (NOT (PENF_FOUND OR (TARGET PENF::PENF)))
    include(FetchContent)
    FetchContent_Declare(
        PENF
        GIT_REPOSITORY https://github.com/szaghi/PENF.git
        GIT_TAG master
    )
    if (USE_GIT_SUBMODULES)
        set(FETCHCONTENT_SOURCE_DIR_PENF ${CMAKE_CURRENT_SOURCE_DIR}/src/third_party/PENF CACHE PATH "")
    endif()
    FetchContent_MakeAvailable(PENF)
    # FetchContent_GetProperties(PENF)
    # if(NOT penf_POPULATED)
    #     message(STATUS "Populating PENF project ...")
    #     FetchContent_Populate(PENF)
    #     add_subdirectory(${penf_SOURCE_DIR} ${penf_BINARY_DIR})
    # endif()
endif()


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
    find_package(fortran_tester QUIET)

    if (NOT (fortran_tester_FOUND OR (TARGET fortran_tester::fortran_tester)))
        include(FetchContent)
        FetchContent_Declare(
            fortran_tester
            GIT_REPOSITORY https://github.com/pdebuyl/fortran_tester.git
            GIT_TAG master
        )
        if (USE_GIT_SUBMODULES)
            set(FETCHCONTENT_SOURCE_DIR_FORTRAN_TESTER ${CMAKE_CURRENT_SOURCE_DIR}/src/third_party/fortran_tester CACHE PATH "")
        endif()
        FetchContent_MakeAvailable(fortran_tester)
        # FetchContent_GetProperties(fortran_tester)
        # if(NOT fortran_tester_POPULATED)
        #     message(STATUS "Populating fortran_tester project ...")
        #     FetchContent_Populate(fortran_tester)
        #     add_subdirectory(${fortran_tester_SOURCE_DIR} ${fortran_tester_BINARY_DIR})
        # endif()
    endif()

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
