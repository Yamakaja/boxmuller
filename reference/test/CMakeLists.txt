find_package(Check REQUIRED)

include(CheckCSourceCompiles)
include(CheckCSourceRuns)
include(CheckFunctionExists)
include(CheckIncludeFile)
include(CheckIncludeFiles)
include(CheckLibraryExists)
include(CheckSymbolExists)
include(CheckTypeSize)

add_executable(test_fxpnt_simple_arithmetic test_fxpnt_simple_arithmetic.c)
target_link_libraries(test_fxpnt_simple_arithmetic boxmueller check)

add_executable(test_xoroshiro128plus test_xoroshiro128plus.c)
target_link_libraries(test_xoroshiro128plus boxmueller check)

add_test(NAME fxpnt_simple_arithmetic COMMAND test_fxpnt_simple_arithmetic WORKING_DIRECTORY ${CMAKE_BINARY_DIR}/test)
add_test(NAME xoroshiro128plus COMMAND test_xoroshiro128plus WORKING_DIRECTORY ${CMAKE_BINARY_DIR}/test)
