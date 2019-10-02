include(GNUInstallDirs)

SET(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${PROJECT_BINARY_DIR}/tests/${CMAKE_INSTALL_BINDIR}")

function(add_flap_test test_src libraries)
    get_filename_component(test_name ${test_src} NAME_WE)

    add_executable(${test_name} ${test_src})
    foreach(lib IN LISTS libraries)
        target_link_libraries(${test_name} ${lib})
    endforeach()
    add_test(NAME ${test_name} COMMAND ${test_name})
endfunction()

foreach(flap_test
    flap_test_ansi_color_style.f90
    flap_test_basic.f90
    flap_test_choices_logical.f90
    flap_test_hidden.f90
    flap_test_minimal.f90
    flap_test_nested.f90
    flap_test_string.f90
    flap_test_duplicated_clas.f90
    flap_test_save_bash_completion.f90
    flap_test_save_man_page.f90
    flap_test_save_usage_to_markdown.f90
)
    add_flap_test(${flap_test} "FLAP;PENF::PENF")
endforeach()

add_flap_test(flap_test_group.f90 "FLAP;PENF::PENF;fortran_tester::fortran_tester")
